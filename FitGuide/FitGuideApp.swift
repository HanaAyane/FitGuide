import SwiftUI
import SwiftData

@main
struct FitGuideApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var store: ExerciseStore
    @StateObject private var library: LibraryStore
    @StateObject private var workout: ActiveWorkoutStore

    init() {
        do {
            let arguments = ProcessInfo.processInfo.arguments
            let isUITesting = arguments.contains("--ui-testing")
            let usesPersistentUITestStore = arguments.contains(
                "--ui-testing-persistent-store"
            )
            let container = try LibraryStore.makeContainer(
                isStoredInMemoryOnly: isUITesting && !usesPersistentUITestStore,
                configurationName: usesPersistentUITestStore
                    ? "FitGuideUITests"
                    : nil
            )

            if usesPersistentUITestStore,
               arguments.contains("--ui-testing-reset-store") {
                try Self.resetUITestStore(container)
            }

            let library = LibraryStore(container: container)

            if arguments.contains("--ui-testing-seed-plan") {
                let plan = library.addPlan(named: "UI Test Plan")
                library.addToPlan(
                    plan,
                    exerciseId: "0001",
                    sets: 1,
                    reps: 1,
                    restSeconds: 0
                )
            }

            let workoutPreferences: UserDefaults
            if isUITesting {
                workoutPreferences = UserDefaults(
                    suiteName: "FitGuideUITests-\(ProcessInfo.processInfo.processIdentifier)"
                ) ?? .standard
            } else {
                workoutPreferences = .standard
            }

            _store = StateObject(wrappedValue: ExerciseStore())
            _library = StateObject(wrappedValue: library)
            _workout = StateObject(
                wrappedValue: ActiveWorkoutStore(
                    container: container,
                    preferences: workoutPreferences
                )
            )
        } catch {
            fatalError("ModelContainer init failed: \(error)")
        }
    }

    private static func resetUITestStore(_ container: ModelContainer) throws {
        let context = container.mainContext
        try context.delete(model: SetLog.self)
        try context.delete(model: WorkoutExercise.self)
        try context.delete(model: WorkoutSession.self)
        try context.delete(model: TrainingPlanItem.self)
        try context.delete(model: TrainingPlan.self)
        try context.delete(model: FavoriteItem.self)
        try context.delete(model: FavoriteList.self)
        try context.delete(model: RecentView.self)
        try context.save()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(library)
                .environmentObject(workout)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        workout.handleAppBecameActive()
                    case .background, .inactive:
                        workout.persistActiveState()
                    @unknown default:
                        break
                    }
                }
        }
    }
}
