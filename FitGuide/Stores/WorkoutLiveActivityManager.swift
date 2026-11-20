import ActivityKit
import Foundation
import os

/// Keeps the system Live Activity in step with the locally persisted workout.
/// There is no push service: all updates originate from an on-device user action.
@MainActor
enum WorkoutLiveActivityManager {
    private static let log = Logger(
        subsystem: "com.local.fitguide",
        category: "LiveActivity"
    )

    static func synchronize(with session: WorkoutSession) {
        guard session.status == .active else {
            end(session: session)
            return
        }
        guard #available(iOS 16.2, *) else { return }

        let snapshot = Snapshot(session: session)
        Task {
            await updateOrStart(snapshot)
        }
    }

    static func end(session: WorkoutSession) {
        guard #available(iOS 16.2, *) else { return }

        let snapshot = Snapshot(session: session)
        Task {
            await endActivities(matching: snapshot)
        }
    }

    static func endAllActiveActivities() {
        guard #available(iOS 16.2, *) else { return }

        Task {
            for activity in Activity<WorkoutLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    @available(iOS 16.2, *)
    private static func updateOrStart(_ snapshot: Snapshot) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let content = ActivityContent(
            state: snapshot.contentState,
            staleDate: snapshot.restEndsAt
        )
        let matching = Activity<WorkoutLiveActivityAttributes>.activities.filter {
            $0.attributes.sessionID == snapshot.sessionID
        }

        if let activity = matching.first {
            await activity.update(content)
            return
        }

        do {
            _ = try Activity.request(
                attributes: snapshot.attributes,
                content: content,
                pushType: nil
            )
        } catch {
            log.error("Unable to start workout Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    @available(iOS 16.2, *)
    private static func endActivities(matching snapshot: Snapshot) async {
        let content = ActivityContent(
            state: snapshot.contentState,
            staleDate: nil
        )
        for activity in Activity<WorkoutLiveActivityAttributes>.activities where
            activity.attributes.sessionID == snapshot.sessionID {
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }

    private struct Snapshot: Sendable {
        let sessionID: String
        let attributes: WorkoutLiveActivityAttributes
        let contentState: WorkoutLiveActivityAttributes.ContentState
        let restEndsAt: Date?

        init(session: WorkoutSession) {
            let currentExercise = session.exercises.first {
                $0.id == session.currentExerciseId
            } ?? session.sortedExercises.first {
                !$0.isSkipped && !$0.isCompleted
            } ?? session.sortedExercises.first
            let currentSetIndex: Int
            if let currentExercise,
               let currentSetID = session.currentSetId,
               let index = currentExercise.sortedSets.firstIndex(where: {
                   $0.id == currentSetID
               }) {
                currentSetIndex = index + 1
            } else {
                currentSetIndex = 0
            }
            let metrics = WorkoutMetrics.calculate(for: session)

            sessionID = session.id
            attributes = WorkoutLiveActivityAttributes(
                sessionID: session.id,
                workoutName: session.displayName
            )
            contentState = WorkoutLiveActivityAttributes.ContentState(
                exerciseName: currentExercise?.exerciseNameZHSnapshot ?? "添加动作",
                exerciseNameEN: currentExercise?.exerciseNameENSnapshot ?? "ADD EXERCISE",
                currentSet: currentSetIndex,
                totalSets: currentExercise?.sortedSets.count ?? 0,
                completedSets: metrics.completedSets,
                plannedSets: metrics.plannedSets,
                restEndsAt: session.restEndsAt,
                pausedRestSeconds: session.restPausedRemaining.map {
                    max(0, Int($0.rounded(.up)))
                }
            )
            restEndsAt = session.restEndsAt
        }
    }
}
