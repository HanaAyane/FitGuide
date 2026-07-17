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
}