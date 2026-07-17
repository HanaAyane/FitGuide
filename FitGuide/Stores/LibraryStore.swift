import Foundation
import SwiftUI
import SwiftData
import os

@MainActor
final class LibraryStore: ObservableObject {
    let container: ModelContainer
    let context: ModelContext

    @Published var favoriteLists: [FavoriteList] = []
    @Published var recentViews: [RecentView] = []
    @Published var trainingPlans: [TrainingPlan] = []

    @Published var defaultFavorites: FavoriteList?
    @Published var customLists: [FavoriteList] = []

    private let log = Logger(subsystem: "com.local.fitguide", category: "Library")

    init() {
        let schema = Schema([FavoriteList.self, FavoriteItem.self, RecentView.self, TrainingPlan.self, TrainingPlanItem.self])
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
            context = container.mainContext
            ensureDefault()
            load()
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    private func ensureDefault() {
        let desc = FetchDescriptor<FavoriteList>(predicate: #Predicate { $0.id == FavoriteListDefaultID })
        if let existing = try? context.fetch(desc).first {
            defaultFavorites = existing
        } else {
            let d = FavoriteList(id: FavoriteListDefaultID, name: FavoriteListDefaultName, order: -1)
            context.insert(d)
            try? context.save()
            defaultFavorites = d
        }
    }

    func load() {
        let listDesc = FetchDescriptor<FavoriteList>(sortBy: [SortDescriptor(\.order)])
        favoriteLists = (try? context.fetch(listDesc)) ?? []
        customLists = favoriteLists.filter { $0.id != FavoriteListDefaultID }
        let recentDesc = FetchDescriptor<RecentView>(sortBy: [SortDescriptor(\.viewedAt, order: .reverse)])
        recentViews = (try? context.fetch(recentDesc)) ?? []
        let planDesc = FetchDescriptor<TrainingPlan>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        trainingPlans = (try? context.fetch(planDesc)) ?? []
    }

    func isFavorited(exerciseId: String, in list: FavoriteList? = nil) -> Bool {
        guard let list else { return false }
        return list.items.contains { $0.exerciseId == exerciseId }
    }

    func isFavoritedAnywhere(exerciseId: String) -> Bool {
        favoriteLists.contains { list in list.items.contains { $0.exerciseId == exerciseId } }
    }

    func toggleFavorite(exerciseId: String, in list: FavoriteList) {
        if let item = list.items.first(where: { $0.exerciseId == exerciseId }) {
            context.delete(item)
        } else {
            let item = FavoriteItem(exerciseId: exerciseId)
            item.list = list
            context.insert(item)
        }
        try? context.save()
        load()
    }

    func addList(named name: String) {
        let order = (favoriteLists.map(\.order).max() ?? 0) + 1
        let newList = FavoriteList(name: name, order: order)
        context.insert(newList)
        try? context.save()
        load()
    }

    func rename(list: FavoriteList, to newName: String) {
        list.name = newName
        try? context.save()
        load()
    }

    func delete(list: FavoriteList) {
        guard list.id != FavoriteListDefaultID else { return }
        context.delete(list)
        try? context.save()
        load()
    }

    func recordRecent(exerciseId: String) {
        let desc = FetchDescriptor<RecentView>(predicate: #Predicate { $0.id == exerciseId })
        if let existing = try? context.fetch(desc).first {
            existing.viewedAt = .now
        } else {
            let recent = RecentView(exerciseId: exerciseId)
            context.insert(recent)
        }
        try? context.save()
        load()
        // Prune
        if recentViews.count > 20 {
            for r in recentViews.dropFirst(20) {
                context.delete(r)
            }
            try? context.save()
            load()
        }
    }

    // MARK: - Training Plans

    func addPlan(named name: String) -> TrainingPlan {
        let plan = TrainingPlan(name: name)
        context.insert(plan)
        try? context.save()
        load()
        return plan
    }

    func containsInPlan(_ plan: TrainingPlan, exerciseId: String) -> Bool {
        plan.items.contains { $0.exerciseId == exerciseId }
    }

    func addToPlan(_ plan: TrainingPlan, exerciseId: String, sets: Int = 3, reps: Int = 12) {
        guard !containsInPlan(plan, exerciseId: exerciseId) else { return }
        let order = (plan.items.map(\.order).max() ?? -1) + 1
        let item = TrainingPlanItem(exerciseId: exerciseId, sets: sets, reps: reps, order: order)
        item.plan = plan
        context.insert(item)
        try? context.save()
        load()
    }

    func updateItem(_ item: TrainingPlanItem, sets: Int, reps: Int) {
        let newSets = max(1, sets)
        item.reps = max(1, reps)
        var states = item.setStates
        if newSets > states.count {
            states.append(contentsOf: Array(repeating: false, count: newSets - states.count))
        } else if newSets < states.count {
            states = Array(states.prefix(newSets))
        }
        item.sets = newSets
        item.setStates = states
        if item.isCompleted { item.completedAt = .now } else { item.completedAt = nil }
        try? context.save()
        load()
    }

    func toggleSet(_ item: TrainingPlanItem, at index: Int) {
        var states = item.setStates
        guard index >= 0 && index < states.count else { return }
        states[index].toggle()
        item.setStates = states
        item.completedAt = item.isCompleted ? .now : (item.completedCount > 0 ? .now : nil)
        try? context.save()
        load()
    }

    func uncompleteAllItems(in plan: TrainingPlan) {
        for it in plan.items {
            it.setStates = Array(repeating: false, count: it.sets)
            it.completedAt = nil
        }
        try? context.save()
        load()
    }

    func deleteItem(_ item: TrainingPlanItem) {
        context.delete(item)
        try? context.save()
        load()
    }

    func deletePlan(_ plan: TrainingPlan) {
        context.delete(plan)
        try? context.save()
        load()
    }

    func renamePlan(_ plan: TrainingPlan, to newName: String) {
        plan.name = newName
        try? context.save()
        load()
    }
}