import ActivityKit
import Foundation

@available(iOS 16.2, *)
struct WorkoutLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let exerciseName: String
        let exerciseNameEN: String
        let currentSet: Int
        let totalSets: Int
        let completedSets: Int
        let plannedSets: Int
        let restEndsAt: Date?
        let pausedRestSeconds: Int?
    }

    let sessionID: String
    let workoutName: String
}
