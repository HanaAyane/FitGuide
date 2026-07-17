import SwiftUI

@main
struct FitGuideApp: App {
    @StateObject private var store = ExerciseStore()
    @StateObject private var library = LibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(library)
                .preferredColorScheme(.dark)
        }
    }
}