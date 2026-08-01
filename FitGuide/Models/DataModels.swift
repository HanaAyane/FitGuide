import Foundation
import SwiftData

let DefaultRestSeconds = 90

enum WorkoutStatus: String, Codable, CaseIterable {
    case active
    case completed
    case abandoned
}

/// Retained only to open v1 stores without destructive migration. v2 no longer
/// presents or writes the legacy favorites feature.
@Model
final class FavoriteList {
    @Attribute(.unique) var id: String
    var name: String
    var order: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \FavoriteItem.list)
    var items: [FavoriteItem]

    init(id: String = UUID().uuidString, name: String, order: Int = 0, createdAt: Date = .now, items: [FavoriteItem] = []) {
        self.id = id
        self.name = name
        self.order = order
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class FavoriteItem {
    @Attribute(.unique) var id: String
    var exerciseId: String
    var addedAt: Date
    var list: FavoriteList?

    init(id: String = UUID().uuidString, exerciseId: String, addedAt: Date = .now) {
        self.id = id
        self.exerciseId = exerciseId
        self.addedAt = addedAt
    }
}

@Model
final class RecentView {
    @Attribute(.unique) var id: String
    var exerciseId: String
    var viewedAt: Date

    init(exerciseId: String, viewedAt: Date = .now) {
        self.id = exerciseId
        self.exerciseId = exerciseId
        self.viewedAt = viewedAt
    }
}

@Model
final class TrainingPlan {
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date
    /// Optional for lightweight migration from the v1 store.
    var updatedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \TrainingPlanItem.plan)
    var items: [TrainingPlanItem]

    init(
        id: String = UUID().uuidString,
        name: String,
        createdAt: Date = .now,
        updatedAt: Date? = .now,
        items: [TrainingPlanItem] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

@Model
final class TrainingPlanItem {
    @Attribute(.unique) var id: String
    var exerciseId: String
    var sets: Int
    var reps: Int
    var order: Int
    /// Optional backing value allows existing v1 rows to migrate without data loss.
    var restSecondsRaw: Int?
    var setStatesRaw: String
    var completedAt: Date?
    var plan: TrainingPlan?

    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        sets: Int = 3,
        reps: Int = 12,
        order: Int = 0,
        restSeconds: Int = DefaultRestSeconds
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.order = order
        self.restSecondsRaw = max(0, restSeconds)
        self.setStatesRaw = TrainingPlanItem.encodeSetStates(Array(repeating: false, count: sets))
        self.completedAt = nil
    }

    static func encodeSetStates(_ states: [Bool]) -> String {
        states.map { $0 ? "1" : "0" }.joined()
    }

    static func decodeSetStates(_ raw: String) -> [Bool] {
        raw.map { $0 == "1" }
    }

    var setStates: [Bool] {
        get { Self.decodeSetStates(setStatesRaw) }
        set { setStatesRaw = Self.encodeSetStates(newValue) }
    }

    var completedCount: Int {
        setStates.filter { $0 }.count
    }

    var isCompleted: Bool {
        !setStates.isEmpty && setStates.allSatisfy { $0 }
    }

    var progress: Double {
        guard sets > 0 else { return 0 }
        return Double(completedCount) / Double(sets)
    }

    var restSeconds: Int {
        get { max(0, restSecondsRaw ?? DefaultRestSeconds) }
        set { restSecondsRaw = max(0, newValue) }
    }
}

// MARK: - v2 Workout History

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: String
    var sourcePlanId: String?
    var planNameSnapshot: String?
    var startedAt: Date
    var endedAt: Date?
    var statusRaw: String
    var notes: String?
    var currentExerciseId: String?
    var currentSetId: String?
    var restEndsAt: Date?
    var restPausedRemaining: Double?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.session)
    var exercises: [WorkoutExercise]

    init(
        id: String = UUID().uuidString,
        sourcePlanId: String? = nil,
        planNameSnapshot: String? = nil,
        startedAt: Date = .now,
        endedAt: Date? = nil,
        status: WorkoutStatus = .active,
        notes: String? = nil,
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.sourcePlanId = sourcePlanId
        self.planNameSnapshot = planNameSnapshot
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.statusRaw = status.rawValue
        self.notes = notes
        self.currentExerciseId = nil
        self.currentSetId = nil
        self.restEndsAt = nil
        self.restPausedRemaining = nil
        self.exercises = exercises
    }

    var status: WorkoutStatus {
        get { WorkoutStatus(rawValue: statusRaw) ?? .abandoned }
        set { statusRaw = newValue.rawValue }
    }

    var sortedExercises: [WorkoutExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    var displayName: String {
        if let trimmed = planNameSnapshot?.trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmed.isEmpty {
            return trimmed
        }
        return "自由训练"
    }
}

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: String
    var exerciseId: String
    var exerciseNameZHSnapshot: String
    var exerciseNameENSnapshot: String
    var order: Int
    var plannedSets: Int
    var targetReps: Int
    var restSeconds: Int
    var isSkipped: Bool
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \SetLog.workoutExercise)
    var sets: [SetLog]

    init(
        id: String = UUID().uuidString,
        exerciseId: String,
        exerciseNameZH: String,
        exerciseNameEN: String,
        order: Int,
        plannedSets: Int = 3,
        targetReps: Int = 12,
        restSeconds: Int = DefaultRestSeconds,
        isSkipped: Bool = false,
        sets: [SetLog] = []
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseNameZHSnapshot = exerciseNameZH
        self.exerciseNameENSnapshot = exerciseNameEN
        self.order = order
        self.plannedSets = max(1, plannedSets)
        self.targetReps = max(1, targetReps)
        self.restSeconds = max(0, restSeconds)
        self.isSkipped = isSkipped
        self.sets = sets
    }

    var sortedSets: [SetLog] {
        sets.sorted { $0.order < $1.order }
    }

    var completedSetCount: Int {
        sets.filter { $0.completedAt != nil }.count
    }

    var isCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.completedAt != nil }
    }
}

@Model
final class SetLog {
    @Attribute(.unique) var id: String
    var order: Int
    var targetReps: Int
    var actualReps: Int
    var weightKg: Double?
    var completedAt: Date?
    var isWarmup: Bool
    var workoutExercise: WorkoutExercise?

    init(
        id: String = UUID().uuidString,
        order: Int,
        targetReps: Int,
        actualReps: Int? = nil,
        weightKg: Double? = nil,
        completedAt: Date? = nil,
        isWarmup: Bool = false
    ) {
        self.id = id
        self.order = order
        self.targetReps = max(1, targetReps)
        self.actualReps = max(0, actualReps ?? targetReps)
        self.weightKg = weightKg
        self.completedAt = completedAt
        self.isWarmup = isWarmup
    }
}

struct WorkoutMetrics: Equatable {
    let duration: TimeInterval
    let plannedSets: Int
    let completedSets: Int
    let totalReps: Int
    let totalVolume: Double
    let completedExercises: Int

    static func calculate(for session: WorkoutSession, now: Date = .now) -> WorkoutMetrics {
        let end = session.endedAt ?? now
        let allSets = session.exercises.flatMap(\.sets)
        let completedSets = allSets.filter { $0.completedAt != nil }

        return WorkoutMetrics(
            duration: max(0, end.timeIntervalSince(session.startedAt)),
            plannedSets: allSets.count,
            completedSets: completedSets.count,
            totalReps: completedSets.reduce(0) { $0 + $1.actualReps },
            totalVolume: completedSets.reduce(0) { result, set in
                result + ((set.weightKg ?? 0) * Double(set.actualReps))
            },
            completedExercises: session.exercises.filter { exercise in
                !exercise.isSkipped && exercise.sets.contains { $0.completedAt != nil }
            }.count
        )
    }
}
