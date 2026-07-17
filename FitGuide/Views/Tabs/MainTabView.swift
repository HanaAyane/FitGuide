import SwiftUI

struct MainTabView: View {
    @State private var selection: Tab = .exercises

    enum Tab: Hashable {
        case exercises, plans, favorites, profile
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

            FavoritesTabView()
                .tabItem {
                    Label {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("收藏")
                            Text("Favorites")
                                .font(.caption2.smallCaps())
                                .opacity(0.7)
                        }
                    } icon: {
                        Image(systemName: "bookmark")
                    }
                }
                .tag(Tab.favorites)

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
    }
}