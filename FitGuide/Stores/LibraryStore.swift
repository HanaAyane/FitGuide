import Foundation
import SwiftUI
import SwiftData
import os

@MainActor
final class LibraryStore: ObservableObject {
    let container: ModelContainer
    let context: ModelContext

    @Published var recentViews: [RecentView] = []
    @Published var trainingPlans: [TrainingPlan] = []

    @Published var lastErrorMessage: String?

    private let log = Logger(subsystem: "com.local.fitguide", category: "Library")
    private let saveAction: () throws -> Void
    private let rollbackAction: () -> Void

    static func makeContainer(
        isStoredInMemoryOnly: Bool = false,
        configurationName: String? = nil,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema([
            FavoriteList.self,
            FavoriteItem.self,
            RecentView.self,
            TrainingPlan.self,
            TrainingPlanItem.self,
            WorkoutSession.self,
            WorkoutExercise.self,
            SetLog.self
        ])
        let config: ModelConfiguration
        if let storeURL {
            config = ModelConfiguration(
                configurationName,
                schema: schema,
                url: storeURL
            )
        } else {
            config = ModelConfiguration(
                configurationName,
                schema: schema,
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        }
        return try ModelContainer(for: schema, configurations: [config])
    }

    init(
        container: ModelContainer? = nil,
        saveAction: (() throws -> Void)? = nil,
        rollbackAction: (() -> Void)? = nil
    ) {
        do {
            self.container = try container ?? Self.makeContainer()
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
        self.context = self.container.mainContext
        let context = self.container.mainContext
        self.saveAction = saveAction ?? { try context.save() }
        self.rollbackAction = rollbackAction ?? { context.rollback() }
        migrateLegacyDefaults()
        load()
    }

    /// Completes the lightweight v1 → v2 migration after optional columns are added.
    /// Legacy completion flags are intentionally preserved but ignored by v2 workouts.
    private func migrateLegacyDefaults() {
        do {
            let plans = try context.fetch(FetchDescriptor<TrainingPlan>())
            let items = try context.fetch(FetchDescriptor<TrainingPlanItem>())
            var changed = false

            for plan in plans where plan.updatedAt == nil {
                plan.updatedAt = plan.createdAt
                changed = true
            }
            for item in items where item.restSecondsRaw == nil {
                item.restSecondsRaw = DefaultRestSeconds
                changed = true
            }
            if changed {
                _ = save("升级 v1 本地计划数据")
            }
        } catch {
            report(error, operation: "迁移 v1 本地计划数据")
        }
    }

    func load() {
        do {
            let recentDesc = FetchDescriptor<RecentView>(sortBy: [SortDescriptor(\.viewedAt, order: .reverse)])
            recentViews = try context.fetch(recentDesc)

            let planDesc = FetchDescriptor<TrainingPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            trainingPlans = try context.fetch(planDesc)
        } catch {
            report(error, operation: "读取本地资料库")
        }
    }

    @discardableResult
    private func save(_ operation: String) -> Bool {
        do {
            try saveAction()
            return true
        } catch {
            rollbackAction()
            report(error, operation: operation)
            return false
        }
    }

    private func report(_ error: Error, operation: String) {
        let message = "\(operation)失败 · Operation failed: \(error.localizedDescription)"
        lastErrorMessage = message
        log.error("\(message, privacy: .public)")
    }

    func recordRecent(exerciseId: String) {
        let desc = FetchDescriptor<RecentView>(predicate: #Predicate { $0.id == exerciseId })
        do {
            if let existing = try context.fetch(desc).first {
                existing.viewedAt = .now
            } else {
                let recent = RecentView(exerciseId: exerciseId)
                context.insert(recent)
            }
            _ = save("记录最近浏览")
            load()

            if recentViews.count > 20 {
                for recent in recentViews.dropFirst(20) {
                    context.delete(recent)
                }
                _ = save("清理最近浏览")
                load()
            }
        } catch {
            report(error, operation: "读取最近浏览")
        }
    }

    // MARK: - Training Plans

    func addPlan(named name: String) -> TrainingPlan {
        let plan = TrainingPlan(name: name)
        context.insert(plan)
        _ = save("新建训练计划")
        load()
        return plan
    }

    func containsInPlan(_ plan: TrainingPlan, exerciseId: String) -> Bool {
        plan.items.contains { $0.exerciseId == exerciseId }
    }

    @discardableResult
    func addToPlan(
        _ plan: TrainingPlan,
        exerciseId: String,
        sets: Int = 3,
        reps: Int = 12,
        restSeconds: Int = DefaultRestSeconds
    ) -> Bool {
        guard !containsInPlan(plan, exerciseId: exerciseId) else { return false }
        let order = (plan.items.map(\.order).max() ?? -1) + 1
        let item = TrainingPlanItem(
            exerciseId: exerciseId,
            sets: max(1, sets),
            reps: max(1, reps),
            order: order,
            restSeconds: max(0, restSeconds)
        )
        item.plan = plan
        plan.updatedAt = .now
        context.insert(item)
        let didSave = save("添加计划动作")
        load()
        return didSave
    }

    /// Creates a plan and its first item in one transaction so the picker never
    /// reports success after persisting only an empty plan.
    @discardableResult
    func createPlan(
        named name: String,
        adding exerciseId: String,
        sets: Int = 3,
        reps: Int = 12,
        restSeconds: Int = DefaultRestSeconds
    ) -> Bool {
        let plan = TrainingPlan(name: name)
        let item = TrainingPlanItem(
            exerciseId: exerciseId,
            sets: max(1, sets),
            reps: max(1, reps),
            order: 0,
            restSeconds: max(0, restSeconds)
        )
        item.plan = plan
        context.insert(plan)
        context.insert(item)
        let didSave = save("新建计划并添加动作")
        load()
        return didSave
    }

    func updateItem(_ item: TrainingPlanItem, sets: Int, reps: Int, restSeconds: Int? = nil) {
        item.sets = max(1, sets)
        item.reps = max(1, reps)
        item.restSeconds = max(0, restSeconds ?? item.restSeconds)
        item.plan?.updatedAt = .now
        _ = save("更新计划动作")
        load()
    }

    /// v1 compatibility only. v2 workout execution writes SetLog instead.
    func toggleSet(_ item: TrainingPlanItem, at index: Int) {
        var states = item.setStates
        guard index >= 0 && index < states.count else { return }
        states[index].toggle()
        item.setStates = states
        item.completedAt = item.isCompleted ? .now : nil
        _ = save("更新旧版计划进度")
        load()
    }

    func uncompleteAllItems(in plan: TrainingPlan) {
        for it in plan.items {
            it.setStates = Array(repeating: false, count: it.sets)
            it.completedAt = nil
        }
        _ = save("重置旧版计划进度")
        load()
    }

    func deleteItem(_ item: TrainingPlanItem) {
        let plan = item.plan
        context.delete(item)
        plan?.updatedAt = .now
        _ = save("删除计划动作")
        normalizeOrder(in: plan)
        load()
    }

    func deletePlan(_ plan: TrainingPlan) {
        context.delete(plan)
        _ = save("删除训练计划")
        load()
    }

    func renamePlan(_ plan: TrainingPlan, to newName: String) {
        plan.name = newName
        plan.updatedAt = .now
        _ = save("重命名训练计划")
        load()
    }

    func moveItem(_ item: TrainingPlanItem, by offset: Int) {
        guard let plan = item.plan else { return }
        let items = plan.items.sorted { $0.order < $1.order }
        guard let source = items.firstIndex(where: { $0.id == item.id }) else { return }
        let destination = source + offset
        guard items.indices.contains(destination) else { return }
        let other = items[destination]
        let oldOrder = item.order
        item.order = other.order
        other.order = oldOrder
        plan.updatedAt = .now
        _ = save("调整计划顺序")
        load()
    }

    private func normalizeOrder(in plan: TrainingPlan?) {
        guard let plan else { return }
        for (index, item) in plan.items.sorted(by: { $0.order < $1.order }).enumerated() {
            item.order = index
        }
        plan.updatedAt = .now
        _ = save("整理计划顺序")
    }

    func clearError() {
        lastErrorMessage = nil
    }
}
