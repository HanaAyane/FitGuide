import ActivityKit
import SwiftUI
import WidgetKit

@main
struct FitGuideLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        FitGuideWorkoutLiveActivity()
    }
}

@available(iOS 16.2, *)
struct FitGuideWorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutLiveActivityAttributes.self) { context in
            HStack(spacing: 12) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundStyle(.cyan)

                VStack(alignment: .leading, spacing: 3) {
                    Text(context.attributes.workoutName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                    Text(context.state.exerciseName)
                        .font(.headline)
                        .lineLimit(1)
                    Text(progressText(for: context.state))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
                RestStatus(state: context.state)
            }
            .padding(.horizontal, 16)
            .activityBackgroundTint(Color(red: 0.02, green: 0.12, blue: 0.16))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.cyan)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    RestStatus(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.exerciseName)
                            .font(.headline)
                            .lineLimit(1)
                        Text(progressText(for: context.state))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                if let restEndsAt = context.state.restEndsAt {
                    // Rest is time-sensitive, so it takes the compact island.
                    Text(restEndsAt, style: .timer)
                        .font(.caption2.monospacedDigit())
                } else if let paused = context.state.pausedRestSeconds, paused > 0 {
                    Text("\(paused)s")
                        .font(.caption2.monospacedDigit())
                } else {
                    // Outside rest, the current exercise is the most useful
                    // piece of information in the limited compact space.
                    Text(context.state.exerciseName)
                        .font(.caption2.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(.cyan)
            }
            .keylineTint(.cyan)
        }
    }

    private func progressText(
        for state: WorkoutLiveActivityAttributes.ContentState
    ) -> String {
        let currentSet = state.currentSet > 0
            ? "第 \(state.currentSet)/\(state.totalSets) 组"
            : "准备开始"
        return "\(currentSet) · \(state.completedSets)/\(state.plannedSets) 组"
    }
}

@available(iOS 16.2, *)
private struct RestStatus: View {
    let state: WorkoutLiveActivityAttributes.ContentState

    var body: some View {
        if let restEndsAt = state.restEndsAt {
            VStack(alignment: .trailing, spacing: 2) {
                Text("休息")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(restEndsAt, style: .timer)
                    .font(.headline.monospacedDigit())
            }
        } else if let paused = state.pausedRestSeconds, paused > 0 {
            VStack(alignment: .trailing, spacing: 2) {
                Text("休息已暂停")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(paused)s")
                    .font(.headline.monospacedDigit())
            }
        }
    }
}
