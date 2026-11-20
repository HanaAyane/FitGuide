import XCTest

final class FitGuideUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testFreeWorkoutContinueBackgroundFinishAndHistory() {
        launch()
        startQuickWorkout()

        app.buttons["workout.close"].tap()
        XCTAssertTrue(app.buttons["training.continueWorkout"].waitForExistence(timeout: 3))
        app.buttons["training.continueWorkout"].tap()
        XCTAssertTrue(app.buttons["workout.addExercise.empty"].waitForExistence(timeout: 3))

        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["workout.addExercise.empty"].waitForExistence(timeout: 5))

        addFixtureExercise()
        completeAllThreeSets()
        finishWorkout()

        XCTAssertTrue(app.staticTexts["workout.summary.saved"].waitForExistence(timeout: 5))
        app.buttons["workout.summary.done"].tap()
        XCTAssertTrue(app.buttons["training.recent.row"].waitForExistence(timeout: 5))

        app.buttons["training.recent.row"].tap()
        XCTAssertTrue(app.staticTexts["workout.summary.saved"].waitForExistence(timeout: 5))
    }

    func testSeededPlanCanCompleteWithoutMutatingTemplate() {
        launch(extraArguments: ["--ui-testing-seed-plan"])
        XCTAssertTrue(app.buttons["training.planStart"].waitForExistence(timeout: 8))
        XCTAssertTrue(waitForEnabled(app.buttons["training.planStart"], timeout: 8))
        app.buttons["training.planStart"].tap()

        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 5))
        app.buttons["workout.completeSet"].tap()
        finishWorkout()
        XCTAssertTrue(app.staticTexts["workout.summary.saved"].waitForExistence(timeout: 5))

        app.buttons["workout.summary.done"].tap()
        XCTAssertTrue(app.buttons["training.planStart"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["training.recent.row"].exists)
    }

    func testPlanPlayResumesExistingWorkoutInsteadOfStartingAnother() {
        launch(extraArguments: ["--ui-testing-seed-plan"])
        let planStart = app.buttons["training.planStart"]
        XCTAssertTrue(planStart.waitForExistence(timeout: 8))
        XCTAssertTrue(waitForEnabled(planStart, timeout: 8))
        planStart.tap()
        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 5))

        app.buttons["workout.close"].tap()
        XCTAssertTrue(app.buttons["training.continueWorkout"].waitForExistence(timeout: 5))

        // Repeatedly pressing a plan's play button continues the existing
        // workout; it must not attempt a second save/create operation.
        planStart.tap()
        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 5))
    }

    func testAbandonedWorkoutDoesNotCreateCompletedHistory() {
        launch()
        startQuickWorkout()

        app.buttons["workout.sessionMenu"].tap()
        app.buttons["放弃训练 Abandon"].tap()
        app.buttons["放弃训练 Abandon"].tap()

        XCTAssertTrue(app.buttons["training.quickStart"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["training.recent.row"].exists)
    }

    func testColdLaunchRestoresActiveWorkoutFromDisk() {
        launch(
            extraArguments: [
                "--ui-testing-persistent-store",
                "--ui-testing-reset-store"
            ]
        )
        startQuickWorkout()
        addFixtureExercise()
        app.terminate()

        launch(extraArguments: ["--ui-testing-persistent-store"])
        XCTAssertTrue(
            app.buttons["training.continueWorkout"].waitForExistence(timeout: 8)
        )
        app.buttons["training.continueWorkout"].tap()
        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 8))

        app.buttons["workout.sessionMenu"].tap()
        app.buttons["放弃训练 Abandon"].tap()
        app.buttons["放弃训练 Abandon"].tap()
        XCTAssertTrue(app.buttons["training.quickStart"].waitForExistence(timeout: 5))
    }

    func testTrainingCoreControlsRemainReachableAtAccessibilityTextSize() {
        launch(
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
                "-UIAccessibilityReduceMotionEnabled",
                "YES"
            ]
        )
        startQuickWorkout()

        XCTAssertTrue(app.buttons["workout.addExercise.empty"].isHittable)
        XCTAssertTrue(app.buttons["workout.close"].isHittable)
        XCTAssertTrue(app.buttons["workout.sessionMenu"].isHittable)
    }

    func testTrainingCoreControlsAtCurrentSystemSettings() {
        launch()
        startQuickWorkout()

        XCTAssertTrue(app.buttons["workout.addExercise.empty"].isHittable)
        XCTAssertTrue(app.buttons["workout.close"].isHittable)
        XCTAssertTrue(app.buttons["workout.sessionMenu"].isHittable)
    }

    func testTrainingHomeAndWorkoutPassAccessibilityAudit() throws {
        launch(extraArguments: ["--ui-testing-seed-plan"])
        try app.performAccessibilityAudit(
            for: [
                .hitRegion,
                .sufficientElementDescription,
                .textClipped
            ]
        )

        XCTAssertTrue(waitForEnabled(app.buttons["training.planStart"], timeout: 8))
        app.buttons["training.planStart"].tap()
        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(
            for: [
                .hitRegion,
                .sufficientElementDescription,
                .textClipped
            ]
        )

        app.buttons["workout.completeSet"].tap()
        finishWorkout()
        XCTAssertTrue(app.staticTexts["workout.summary.saved"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(
            for: [
                .hitRegion,
                .sufficientElementDescription,
                .textClipped
            ]
        )

        app.buttons["workout.summary.done"].tap()
        XCTAssertTrue(app.buttons["training.recent.row"].waitForExistence(timeout: 5))
        app.buttons["training.recent.row"].tap()
        XCTAssertTrue(app.staticTexts["workout.summary.saved"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(
            for: [
                .hitRegion,
                .sufficientElementDescription,
                .textClipped
            ]
        )
    }

    func testRestTimerPassesAccessibilityAuditAtLargeTextAndReduceMotion() throws {
        launch(
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL",
                "-UIAccessibilityReduceMotionEnabled",
                "YES"
            ]
        )
        startQuickWorkout()
        addFixtureExercise()
        app.buttons["workout.completeSet"].tap()

        XCTAssertTrue(app.buttons["workout.rest.skip"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["workout.rest.extend"].isHittable)
        XCTAssertTrue(app.buttons["workout.rest.pauseResume"].isHittable)
        XCTAssertTrue(app.buttons["workout.rest.skip"].isHittable)
        try app.performAccessibilityAudit(
            for: [
                .hitRegion,
                .sufficientElementDescription,
                .textClipped
            ]
        )
    }

    private func launch(extraArguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = [
            "--ui-testing",
            "--ui-testing-training-tab"
        ] + extraArguments
        app.launch()
        XCTAssertTrue(app.buttons["training.quickStart"].waitForExistence(timeout: 12))
    }

    private func startQuickWorkout() {
        app.buttons["training.quickStart"].tap()
        let addExercise = app.buttons["workout.addExercise.empty"]
        if !addExercise.waitForExistence(timeout: 12),
           app.buttons["training.quickStart"].exists {
            app.buttons["training.quickStart"].tap()
        }
        if !addExercise.waitForExistence(timeout: 5) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertTrue(
            addExercise.exists,
            "Quick workout did not open.\n\(app.debugDescription)"
        )
    }

    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: element
        )
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func addFixtureExercise() {
        app.buttons["workout.addExercise.empty"].tap()
        let fixture = app.buttons["workout.exercise.add.0001"]
        XCTAssertTrue(fixture.waitForExistence(timeout: 8))
        fixture.tap()
        XCTAssertTrue(app.buttons["workout.completeSet"].waitForExistence(timeout: 5))
    }

    private func completeAllThreeSets() {
        for index in 0..<3 {
            let complete = app.buttons["workout.completeSet"]
            XCTAssertTrue(complete.waitForExistence(timeout: 5))
            complete.tap()

            if index < 2 {
                let skip = app.buttons["workout.rest.skip"]
                XCTAssertTrue(skip.waitForExistence(timeout: 3))
                skip.tap()
            }
        }
    }

    private func finishWorkout() {
        app.buttons["workout.sessionMenu"].tap()
        app.buttons["结束训练 Finish"].tap()
        app.buttons["结束训练 Finish Workout"].tap()
    }
}
