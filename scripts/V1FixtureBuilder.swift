import Foundation
import SwiftData

let FavoriteListDefaultID = "default-favorites"

@Model
final class FavoriteList {
    @Attribute(.unique) var id: String
    var name: String
    var order: Int
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \FavoriteItem.list)
    var items: [FavoriteItem]

    init(
        id: String,
        name: String,
        order: Int,
        createdAt: Date,
        items: [FavoriteItem] = []
    ) {
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

    init(id: String, exerciseId: String, addedAt: Date) {
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

    init(exerciseId: String, viewedAt: Date) {
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

    init(
        id: String,
        name: String,
        createdAt: Date,
        items: [TrainingPlanItem] = []
    ) {
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

    init(
        id: String,
        exerciseId: String,
        sets: Int,
        reps: Int,
        order: Int,
        setStatesRaw: String,
        completedAt: Date?
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.sets = sets
        self.reps = reps
        self.order = order
        self.setStatesRaw = setStatesRaw
        self.completedAt = completedAt
    }
}

@main
@MainActor
struct V1FixtureBuilder {
    static func main() throws {
        guard CommandLine.arguments.count == 2 else {
            fatalError("Usage: V1FixtureBuilder <output.store>")
        }

        let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let schema = Schema([
            FavoriteList.self,
            FavoriteItem.self,
            RecentView.self,
            TrainingPlan.self,
            TrainingPlanItem.self
        ])
        let configuration = ModelConfiguration(
            "FitGuideV1Fixture",
            schema: schema,
            url: outputURL,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
        let context = container.mainContext

        let defaultList = FavoriteList(
            id: FavoriteListDefaultID,
            name: "我的收藏",
            order: -1,
            createdAt: fixedDate
        )
        let defaultFavorite = FavoriteItem(
            id: "legacy-favorite-default",
            exerciseId: "0001",
            addedAt: fixedDate.addingTimeInterval(1)
        )
        defaultFavorite.list = defaultList

        let customList = FavoriteList(
            id: "legacy-custom-list",
            name: "Legacy Favorites",
            order: 1,
            createdAt: fixedDate.addingTimeInterval(2)
        )
        let customFavorite = FavoriteItem(
            id: "legacy-favorite-custom",
            exerciseId: "0002",
            addedAt: fixedDate.addingTimeInterval(3)
        )
        customFavorite.list = customList

        let recent = RecentView(
            exerciseId: "0002",
            viewedAt: fixedDate.addingTimeInterval(4)
        )

        let plan = TrainingPlan(
            id: "legacy-plan",
            name: "Legacy Plan",
            createdAt: fixedDate.addingTimeInterval(5)
        )
        let firstItem = TrainingPlanItem(
            id: "legacy-plan-item-1",
            exerciseId: "0001",
            sets: 3,
            reps: 12,
            order: 0,
            setStatesRaw: "101",
            completedAt: nil
        )
        firstItem.plan = plan
        let secondItem = TrainingPlanItem(
            id: "legacy-plan-item-2",
            exerciseId: "0002",
            sets: 2,
            reps: 8,
            order: 1,
            setStatesRaw: "11",
            completedAt: fixedDate.addingTimeInterval(6)
        )
        secondItem.plan = plan

        context.insert(defaultList)
        context.insert(defaultFavorite)
        context.insert(customList)
        context.insert(customFavorite)
        context.insert(recent)
        context.insert(plan)
        context.insert(firstItem)
        context.insert(secondItem)
        try context.save()
    }
}
