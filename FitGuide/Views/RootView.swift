import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: ExerciseStore
    @State private var loaded = false

    var body: some View {
        ZStack {
            SpaceBackground()
            if store.exercises.isEmpty {
                VStack(spacing: Spacing.s.rawValue) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(Color.accentColor)
                    Text("FitGuide")
                        .font(.largeTitle.weight(.semibold))
                        .foregroundColor(.textPrimary)
                    Text("健身动作指导")
                        .font(.caption.smallCaps())
                        .foregroundColor(.textSecondary)
                    ProgressView()
                        .tint(Color.accentColor)
                        .padding(.top, Spacing.s.rawValue)
                }
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
}
        }
    }
}