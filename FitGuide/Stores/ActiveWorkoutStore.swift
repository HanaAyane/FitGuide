import Foundation
import SwiftData
import os

@MainActor
final class ActiveWorkoutStore: ObservableObject {
    static let autoStartRestTimerKey = "workout.autoStartRestTimer"
    static let restTimerSoundKey = "workout.restTimerSound"

    let container: ModelContainer
    let context: ModelContext

    @Published private(set) var activeSession: WorkoutSession?
    @Published var lastErrorMessage: String?
    @Published var autoStartRestTimerEnabled: Bool {
        didSet {
            preferences.set(
                autoStartRestTimerEnabled,
                forKey: Self.autoStartRestTimerKey
            )
        }
    }
    @Published var restTimerSoundEnabled: Bool {
        didSet {
            preferences.set(
                restTimerSoundEnabled,
                forKey: Self.restTimerSoundKey
            )
        }
    }

    private let log = Logger(subsystem: "com.local.fitguide", category: "Workout")
    private let preferences: UserDefaults
    private let saveAction: () throws -> Void
    private let rollbackAction: () -> Void

    init(
        container: ModelContainer,
        preferences: UserDefaults = .standard,
        saveAction: (() throws -> Void)? = nil,
        rollbackAction: (() -> Void)? = nil
    ) {
        self.container = container
        self.context = container.mainContext
        self.preferences = preferences
        let context = container.mainContext
        self.saveAction = saveAction ?? { try context.save() }
        self.rollbackAction = rollbackAction ?? { context.rollback() }
        self.autoStartRestTimerEnabled =
            preferences.object(forKey: Self.autoStartRestTimerKey) as? Bool
            ?? true
        self.restTimerSoundEnabled =
            preferences.object(forKey: Self.restTimerSoundKey) as? Bool
            ?? false
        restoreActiveSession()
    }

    // MARK: - Session lifecycle

    @discardableResult
    func start(plan: TrainingPlan, exercisesById: [String: Exercise]) -> WorkoutSession? {
        guard activeSession == nil else {
            lastErrorMessage = "已有正在进行的训练，请先继续或结束它。"
                + " An active workout already exists; continue or end it first."
            return nil
        }

        let sortedItems = plan.items.sorted { $0.order < $1.order }
        guard !sortedItems.isEmpty else {
            lastErrorMessage = "空计划不能开始训练。 Empty plans cannot be started."
            return nil
        }
        let missingExerciseCount = sortedItems.reduce(into: 0) { count, item in
            if exercisesById[item.exerciseId] == nil {
                count += 1
            }
        }
        guard missingExerciseCount == 0 else {
            lastErrorMessage = "计划中有 \(missingExerciseCount) 个动作资源不可用，未开始训练。"
                + " \(missingExerciseCount) exercise resources are missing; "
                + "the workout was not started."
            return nil
        }

        let session = WorkoutSession(
            sourcePlanId: plan.id,
            planNameSnapshot: plan.name
        )
        context.insert(session)

        for (index, item) in sortedItems.enumerated() {
            guard let exercise = exercisesById[item.exerciseId] else {
                log.warning("Skipped missing exercise \(item.exerciseId, privacy: .public)")
                continue
            }
            insertWorkoutExercise(
                exercise: exercise,
                order: index,
                sets: item.sets,
                reps: item.reps,
                restSeconds: item.restSeconds,
                into: session
            )
        }

        guard !session.exercises.isEmpty else {
            context.delete(session)
            lastErrorMessage = "计划中的动作资源不可用，无法开始训练。"
                + " The plan's exercise resources are unavailable."
            return nil
        }

        selectFirstPending(in: session)
        guard save("开始训练", synchronizing: session) else {
            context.rollback()
            return nil
        }
        activeSession = session
        return session
    }

    @discardableResult
    func startQuickWorkout() -> WorkoutSession? {
        guard activeSession == nil else {
            lastErrorMessage = "已有正在进行的训练，请先继续或结束它。"
                + " An active workout already exists; continue or end it first."
            return nil
        }
        let session = WorkoutSession(planNameSnapshot: "自由训练")
        context.insert(session)
        guard save("开始自由训练", synchronizing: session) else {
            context.rollback()
            return nil
        }
        activeSession = session
        return session
    }

    func addExercise(
        _ exercise: Exercise,
        to session: WorkoutSession,
        sets: Int = 3,
        reps: Int = 12,
        restSeconds: Int = DefaultRestSeconds
    ) {
        guard session.status == .active else { return }
        guard !session.exercises.contains(where: { $0.exerciseId == exercise.id }) else {
            lastErrorMessage = "这个动作已在本次训练中。"
                + " This exercise is already in the workout."
            return
        }

        let nextOrder = (session.exercises.map(\.order).max() ?? -1) + 1
        let workoutExercise = insertWorkoutExercise(
            exercise: exercise,
            order: nextOrder,
            sets: sets,
            reps: reps,
            restSeconds: restSeconds,
            into: session
        )
        if session.currentExerciseId == nil {
            session.currentExerciseId = workoutExercise.id
            session.currentSetId = workoutExercise.sortedSets.first?.id
        }
        _ = save("添加训练动作", synchronizing: session)
    }

    func deleteExercise(_ exercise: WorkoutExercise) {
        guard let session = exercise.session, session.status == .active else { return }
        guard exercise.completedSetCount == 0 else {
            lastErrorMessage = "已有完成组的动作不能删除，可以将它标记为跳过。"
                + " Exercises with completed sets cannot be deleted; skip them instead."
            return
        }
        let wasCurrent = session.currentExerciseId == exercise.id
        let retained = session.sortedExercises.filter { $0.id != exercise.id }
        context.delete(exercise)
        for (index, retainedExercise) in retained.enumerated() {
            retainedExercise.order = index
        }
        if wasCurrent {
            let replacement = retained.first {
                !$0.isSkipped && !$0.isCompleted
            } ?? retained.first { !$0.isSkipped }
            session.currentExerciseId = replacement?.id
            session.currentSetId = replacement.flatMap {
                firstPendingSet(in: $0)?.id ?? $0.sortedSets.first?.id
            }
        }
        _ = save("删除训练动作", synchronizing: session)
    }

    func toggleSkipped(_ exercise: WorkoutExercise) {
        guard let session = exercise.session, session.status == .active else { return }
        exercise.isSkipped.toggle()
        if exercise.isSkipped && session.currentExerciseId == exercise.id {
            selectFirstPending(in: session)
        }
        _ = save("更新跳过状态", synchronizing: session)
    }

    func updateSetCount(for exercise: WorkoutExercise, to requestedCount: Int) {
        guard let session = exercise.session, session.status == .active else { return }
        let completedCount = exercise.sets.filter { $0.completedAt != nil }.count
        let newCount = min(10, max(max(1, completedCount), requestedCount))
        let sortedSets = exercise.sortedSets

        if newCount > sortedSets.count {
            for index in sortedSets.count..<newCount {
                let setLog = SetLog(order: index, targetReps: exercise.targetReps)
                setLog.workoutExercise = exercise
                context.insert(setLog)
            }
        } else if newCount < sortedSets.count {
            let removeCount = sortedSets.count - newCount
            let removable = sortedSets.reversed().filter { $0.completedAt == nil }
            let removed = Array(removable.prefix(removeCount))
            let removedIDs = Set(removed.map(\.id))
            for setLog in removed {
                context.delete(setLog)
            }
            let retained = sortedSets.filter { !removedIDs.contains($0.id) }
            for (index, setLog) in retained.enumerated() {
                setLog.order = index
            }

            if session.currentExerciseId == exercise.id,
               let currentSetID = session.currentSetId,
               removedIDs.contains(currentSetID) {
                session.currentSetId =
                    retained.first(where: { $0.completedAt == nil })?.id
                    ?? retained.first?.id
            }
        }

        exercise.plannedSets = newCount
        if session.currentSetId == nil {
            session.currentSetId = firstPendingSet(in: exercise)?.id
        }
        _ = save("调整训练组数", synchronizing: session)
    }

    func moveExercise(_ exercise: WorkoutExercise, by offset: Int) {
        guard let session = exercise.session, session.status == .active else { return }
        let sorted = session.sortedExercises
        guard let source = sorted.firstIndex(where: { $0.id == exercise.id }) else { return }
        let destination = source + offset
        guard sorted.indices.contains(destination) else { return }
        let other = sorted[destination]
        let oldOrder = exercise.order
        exercise.order = other.order
        other.order = oldOrder
        _ = save("调整训练动作顺序", synchronizing: session)
    }

    func finishActiveSession(at date: Date = .now) -> WorkoutSession? {
        guard let session = activeSession, session.status == .active else { return nil }
        guard session.exercises.contains(where: { exercise in
            exercise.sets.contains { $0.completedAt != nil }
        }) else {
            lastErrorMessage = "至少完成一组后才能结束训练；若不保留为完成记录，请选择放弃训练。"
                + " Complete at least one set, or abandon the workout instead."
            return nil
        }
        session.status = .completed
        session.endedAt = date
        clearRestState(in: session)
        guard save("结束训练") else { return nil }
        activeSession = nil
        WorkoutLiveActivityManager.end(session: session)
        return session
    }

    func abandonActiveSession(at date: Date = .now) -> WorkoutSession? {
        guard let session = activeSession, session.status == .active else { return nil }
        session.status = .abandoned
        session.endedAt = date
        clearRestState(in: session)
        guard save("放弃训练") else { return nil }
        activeSession = nil
        WorkoutLiveActivityManager.end(session: session)
        return session
    }

    func restoreActiveSession() {
        let activeValue = WorkoutStatus.active.rawValue
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == activeValue },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        do {
            let sessions = try context.fetch(descriptor)
            activeSession = sessions.first
            if sessions.count > 1 {
                for duplicate in sessions.dropFirst() {
                    duplicate.status = .abandoned
                    duplicate.endedAt = .now
                    clearRestState(in: duplicate)
                }
                _ = save("整理异常训练状态")
            }
            if let session = activeSession {
                selectFirstPendingIfNeeded(in: session)
                WorkoutLiveActivityManager.synchronize(with: session)
            } else {
                WorkoutLiveActivityManager.endAllActiveActivities()
            }
        } catch {
            report(error, operation: "恢复训练")
        }
    }

    func persistActiveState() {
        guard activeSession != nil else { return }
        _ = save("保存进行中的训练", synchronizing: activeSession)
    }

    func handleAppBecameActive(now: Date = .now) {
        if activeSession == nil {
            restoreActiveSession()
        }
        if let activeSession {
            reconcileRestTimer(in: activeSession, now: now)
        }
    }

    // MARK: - Set logging

    func select(exercise: WorkoutExercise, set: SetLog? = nil) {
        guard let session = exercise.session, session.status == .active else { return }
        session.currentExerciseId = exercise.id
        session.currentSetId = set?.id ?? firstPendingSet(in: exercise)?.id ?? exercise.sortedSets.first?.id
        _ = save("记录训练位置", synchronizing: session)
    }

    func currentExercise(in session: WorkoutSession) -> WorkoutExercise? {
        if let id = session.currentExerciseId,
           let selected = session.exercises.first(where: { $0.id == id }) {
            return selected
        }
        return session.sortedExercises.first { !$0.isSkipped && !$0.isCompleted }
            ?? session.sortedExercises.first { !$0.isSkipped }
            ?? session.sortedExercises.first
    }

    func currentSet(in exercise: WorkoutExercise) -> SetLog? {
        if let id = exercise.session?.currentSetId,
           let selected = exercise.sets.first(where: { $0.id == id }) {
            return selected
        }
        return firstPendingSet(in: exercise) ?? exercise.sortedSets.last
    }

    func complete(
        _ set: SetLog,
        actualReps: Int,
        weightKg: Double?,
        at date: Date = .now
    ) {
        guard let exercise = set.workoutExercise,
              let session = exercise.session,
              session.status == .active else { return }

        let previousActualReps = set.actualReps
        let previousWeight = set.weightKg
        let previousCompletedAt = set.completedAt
        let previousCurrentExerciseID = session.currentExerciseId
        let previousCurrentSetID = session.currentSetId
        let previousRestEndsAt = session.restEndsAt
        let previousRestPausedRemaining = session.restPausedRemaining
        let previousWeights = Dictionary(
            uniqueKeysWithValues: session.exercises
                .flatMap(\.sets)
                .map { ($0.id, $0.weightKg) }
        )

        set.actualReps = max(0, actualReps)
        if let weightKg, weightKg >= 0 {
            set.weightKg = weightKg
        } else {
            set.weightKg = nil
        }
        set.completedAt = date

        let nextSet = firstPendingSet(in: exercise)
        if let nextSet, nextSet.weightKg == nil {
            nextSet.weightKg = set.weightKg
        }
        session.currentSetId = nextSet?.id
        if nextSet == nil {
            session.currentExerciseId = nextPendingExercise(after: exercise, in: session)?.id ?? exercise.id
            if let nextExercise = currentExercise(in: session) {
                session.currentSetId = firstPendingSet(in: nextExercise)?.id
            }
        }

        if autoStartRestTimerEnabled,
           hasPendingSets(in: session),
           exercise.restSeconds > 0 {
            startRest(seconds: exercise.restSeconds, in: session, now: date)
        }
        guard save("完成训练组", synchronizing: session) else {
            set.actualReps = previousActualReps
            set.weightKg = previousWeight
            set.completedAt = previousCompletedAt
            for candidate in session.exercises.flatMap(\.sets) {
                if let previous = previousWeights[candidate.id] {
                    candidate.weightKg = previous
                }
            }
            session.currentExerciseId = previousCurrentExerciseID
            session.currentSetId = previousCurrentSetID
            session.restEndsAt = previousRestEndsAt
            session.restPausedRemaining = previousRestPausedRemaining
            return
        }
    }

    func undo(_ set: SetLog) {
        guard let exercise = set.workoutExercise,
              let session = exercise.session,
              session.status == .active else { return }
        set.completedAt = nil
        session.currentExerciseId = exercise.id
        session.currentSetId = set.id
        _ = save("撤销训练组", synchronizing: session)
    }

    func update(_ set: SetLog, actualReps: Int, weightKg: Double?) {
        guard set.workoutExercise?.session?.status == .active else { return }
        set.actualReps = max(0, actualReps)
        if let weightKg, weightKg >= 0 {
            set.weightKg = weightKg
        } else {
            set.weightKg = nil
        }
        _ = save("更新训练组", synchronizing: set.workoutExercise?.session)
    }

    // MARK: - Rest timer

    func startRest(seconds: Int, in session: WorkoutSession, now: Date = .now) {
        guard session.status == .active, seconds > 0 else { return }
        session.restEndsAt = now.addingTimeInterval(TimeInterval(seconds))
        session.restPausedRemaining = nil
    }

    func remainingRestSeconds(in session: WorkoutSession, now: Date = .now) -> Int {
        if let paused = session.restPausedRemaining {
            return max(0, Int(paused.rounded(.up)))
        }
        guard let endsAt = session.restEndsAt else { return 0 }
        return max(0, Int(endsAt.timeIntervalSince(now).rounded(.up)))
    }

    func pauseRest(in session: WorkoutSession, now: Date = .now) {
        let remaining = remainingRestSeconds(in: session, now: now)
        guard remaining > 0 else {
            skipRest(in: session)
            return
        }
        session.restPausedRemaining = TimeInterval(remaining)
        session.restEndsAt = nil
        _ = save("暂停休息计时", synchronizing: session)
    }

    func resumeRest(in session: WorkoutSession, now: Date = .now) {
        guard let remaining = session.restPausedRemaining, remaining > 0 else { return }
        session.restEndsAt = now.addingTimeInterval(remaining)
        session.restPausedRemaining = nil
        _ = save("继续休息计时", synchronizing: session)
    }

    func extendRest(by seconds: Int, in session: WorkoutSession, now: Date = .now) {
        guard seconds > 0 else { return }
        if let paused = session.restPausedRemaining {
            session.restPausedRemaining = paused + TimeInterval(seconds)
        } else {
            let base = max(session.restEndsAt ?? now, now)
            session.restEndsAt = base.addingTimeInterval(TimeInterval(seconds))
        }
        _ = save("延长休息计时", synchronizing: session)
    }

    func skipRest(in session: WorkoutSession) {
        clearRestState(in: session)
        _ = save("跳过休息计时", synchronizing: session)
    }

    func reconcileRestTimer(in session: WorkoutSession, now: Date = .now) {
        if let endsAt = session.restEndsAt, endsAt <= now {
            clearRestState(in: session)
            _ = save("结束休息计时", synchronizing: session)
        }
    }

    // MARK: - History

    func completedSessions(limit: Int = 100, offset: Int = 0) -> [WorkoutSession] {
        let completedValue = WorkoutStatus.completed.rawValue
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == completedValue },
            sortBy: [SortDescriptor(\.endedAt, order: .reverse)]
        )
        descriptor.fetchLimit = max(1, limit)
        descriptor.fetchOffset = max(0, offset)
        do {
            return try context.fetch(descriptor)
        } catch {
            report(error, operation: "读取训练历史")
            return []
        }
    }

    func completedSessionCount() -> Int {
        let completedValue = WorkoutStatus.completed.rawValue
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == completedValue }
        )
        do {
            return try context.fetchCount(descriptor)
        } catch {
            report(error, operation: "统计训练历史")
            return 0
        }
    }

    @discardableResult
    func deleteHistory(_ session: WorkoutSession) -> Bool {
        guard session.status != .active else { return false }
        context.delete(session)
        return save("删除训练历史")
    }

    func clearError() {
        lastErrorMessage = nil
    }

    // MARK: - Helpers

    @discardableResult
    private func insertWorkoutExercise(
        exercise: Exercise,
        order: Int,
        sets: Int,
        reps: Int,
        restSeconds: Int,
        into session: WorkoutSession
    ) -> WorkoutExercise {
        let workoutExercise = WorkoutExercise(
            exerciseId: exercise.id,
            exerciseNameZH: exercise.nameZH,
            exerciseNameEN: exercise.name,
            order: order,
            plannedSets: sets,
            targetReps: reps,
            restSeconds: restSeconds
        )
        workoutExercise.session = session
        context.insert(workoutExercise)

        for index in 0..<max(1, sets) {
            let setLog = SetLog(order: index, targetReps: reps)
            setLog.workoutExercise = workoutExercise
            context.insert(setLog)
        }
        return workoutExercise
    }

    private func firstPendingSet(in exercise: WorkoutExercise) -> SetLog? {
        exercise.sortedSets.first { $0.completedAt == nil }
    }

    private func hasPendingSets(in session: WorkoutSession) -> Bool {
        session.exercises.contains { exercise in
            !exercise.isSkipped && exercise.sets.contains { $0.completedAt == nil }
        }
    }

    private func nextPendingExercise(
        after exercise: WorkoutExercise,
        in session: WorkoutSession
    ) -> WorkoutExercise? {
        let sorted = session.sortedExercises
        guard let index = sorted.firstIndex(where: { $0.id == exercise.id }) else { return nil }
        let tail = sorted.dropFirst(index + 1)
        return tail.first { !$0.isSkipped && !$0.isCompleted }
            ?? sorted.first { !$0.isSkipped && !$0.isCompleted }
    }

    private func selectFirstPendingIfNeeded(in session: WorkoutSession) {
        guard currentExercise(in: session) == nil || session.currentSetId == nil else { return }
        selectFirstPending(in: session)
    }

    private func selectFirstPending(in session: WorkoutSession) {
        let exercise = session.sortedExercises.first { !$0.isSkipped && !$0.isCompleted }
            ?? session.sortedExercises.first { !$0.isSkipped }
            ?? session.sortedExercises.first
        session.currentExerciseId = exercise?.id
        session.currentSetId = exercise.flatMap { firstPendingSet(in: $0)?.id ?? $0.sortedSets.first?.id }
    }

    private func clearRestState(in session: WorkoutSession) {
        session.restEndsAt = nil
        session.restPausedRemaining = nil
    }

    @discardableResult
    private func save(
        _ operation: String,
        synchronizing session: WorkoutSession? = nil
    ) -> Bool {
        do {
            try saveAction()
            if let session {
                WorkoutLiveActivityManager.synchronize(with: session)
            }
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
}
