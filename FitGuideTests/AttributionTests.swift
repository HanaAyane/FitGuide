import XCTest
@testable import FitGuide

@MainActor
final class AttributionTests: XCTestCase {

    func testEveryExerciseHasGymVisualAttribution() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        XCTAssertFalse(store.exercises.isEmpty, "exercises should be loaded")
        for ex in store.exercises {
            XCTAssertTrue(ex.attribution.contains("Gym visual"), "exercise \(ex.id) missing Gym visual attribution")
            XCTAssertTrue(ex.attribution.contains("gymvisual.com"), "exercise \(ex.id) missing gymvisual.com URL")
        }
    }

    func testStaticAttributionStringHardcoded() {
        XCTAssertTrue(Exercise.gymVisualAttribution.contains("Gym visual"))
        XCTAssertTrue(Exercise.gymVisualAttribution.contains("gymvisual.com"))
    }

    func testAttributionFooterConstantHasSourceLink() {
        XCTAssertTrue(Exercise.gymVisualAttribution.contains("https://gymvisual.com/"))
    }

    func testWorkoutGuideKeepsAttributionPathReachable() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let detailSource = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("FitGuide/Views/Detail/ExerciseDetailView.swift"),
            encoding: .utf8
        )
        let workoutSource = try String(
            contentsOf: repositoryRoot
                .appendingPathComponent("FitGuide/Views/Plans/WorkoutSessionView.swift"),
            encoding: .utf8
        )

        XCTAssertTrue(
            detailSource.contains("AttributionFooter"),
            "Exercise details must keep the Gym visual attribution footer."
        )
        XCTAssertTrue(
            workoutSource.contains("ExerciseDetailView(exercise:"),
            "Workout guide must reuse the attributed exercise detail view."
        )
    }
}
