import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore
    @State private var selection: Tab

    enum Tab: Hashable {
        case exercises, plans, profile
    }

    init() {
        let startsOnTraining = ProcessInfo.processInfo.arguments.contains(
            "--ui-testing-training-tab"
        )
        _selection = State(initialValue: startsOnTraining ? .plans : .exercises)
    }

    var body: some View {
        TabView(selection: $selection) {
            ExercisesTabView()
                .tabItem {
                    Label {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("动作")
                            Text("Exercises")
                                .font(.caption2.smallCaps())
                                .opacity(0.7)
                        }
                    } icon: {
                        Image(systemName: "figure.strengthtraining.traditional")
                    }
                }
                .tag(Tab.exercises)

            PlansView()
                .accessibilityIdentifier("screen.training")
                .tabItem {
                    Label {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("训练")
                            Text("Plans")
                                .font(.caption2.smallCaps())
                                .opacity(0.7)
                        }
                    } icon: {
                        Image(systemName: "list.clipboard")
                    }
                }
                .tag(Tab.plans)

            ProfileTabView()
                .tabItem {
                    Label {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("我的")
                            Text("Profile")
                                .font(.caption2.smallCaps())
                                .opacity(0.7)
                        }
                    } icon: {
                        Image(systemName: "person.crop.circle")
                    }
                }
                .tag(Tab.profile)
        }
        .tint(.accentColor)
        .alert(
            "无法保存数据 · Unable to save data",
            isPresented: Binding(
                get: {
                    library.lastErrorMessage != nil
                        || workoutStore.lastErrorMessage != nil
                },
                set: {
                    if !$0 {
                        library.clearError()
                        workoutStore.clearError()
                    }
                }
            )
        ) {
            Button("好 OK", role: .cancel) {
                library.clearError()
                workoutStore.clearError()
            }
        } message: {
            Text(
                workoutStore.lastErrorMessage
                    ?? library.lastErrorMessage
                    ?? "未知错误 Unknown error"
            )
        }
    }
}
