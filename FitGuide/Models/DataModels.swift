import Foundation
import SwiftData

let FavoriteListDefaultID = "default-favorites"
let FavoriteListDefaultName = "我的收藏"

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
    @Relationship(deleteRule: .cascade, inverse: \TrainingPlanItem.plan)
    var items: [TrainingPlanItem]

    init(id: String = UUID().uuidString, name: String, createdAt: Date = .now, items: [TrainingPlanItem] = []) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
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
    var setStatesRaw: String
    var completedAt: Date?
    var plan: TrainingPlan?

    init(id: String = UUID().uuidString, exerciseId: String, sets: Int = 3, reps: Int = 12, order: Int = 0) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.order = order
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
}