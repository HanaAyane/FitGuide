import XCTest
import UIKit
import ImageIO
import SwiftData
@testable import FitGuide

@MainActor
final class PerformanceTests: XCTestCase {
    func testJSONLoadPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertEqual(store.exercises.count, 1324)

        measure {
            let s = ExerciseStore()
            let e = expectation(description: "m")
            Task {
                await s.load()
                e.fulfill()
            }
            wait(for: [e], timeout: 10)
        }
    }

    func testSearchPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            _ = store.search(query: "胸")
            _ = store.search(query: "bench")
            _ = store.search(query: "dumbbell")
        }
    }

    func testFilterPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            _ = store.filtered(bodyParts: ["chest"], equipments: ["dumbbell"], targets: [])
            _ = store.filtered(bodyParts: [], equipments: [], targets: ["biceps"])
        }
    }

    func testGIFURLResolutionPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            for ex in store.exercises.prefix(50) {
                _ = ExerciseStore.gifURL(for: ex)
                _ = ExerciseStore.imageURL(for: ex)
            }
        }
    }

    func testColdStartToInteractive() throws {
        measure {
            let s = ExerciseStore()
            let e = expectation(description: "m")
            Task {
                await s.load()
                // load完成后即首页可交互
                e.fulfill()
            }
            wait(for: [e], timeout: 10)
            XCTAssertFalse(s.exercises.isEmpty)
        }
    }

    func testGIFFirstFrameLoadTime() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        // 量首帧 GIF 解码时间
        measure {
            guard let ex = store.exercises.first,
                  let url = ExerciseStore.gifURL(for: ex),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            _ = CGImageSourceCreateImageAtIndex(src, 0, nil)
        }
    }

    func testThumbnailLoadBatchTime() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        // 量首屏卡片缩略图批量解码时间（10 张卡片首屏数量）
        measure {
            for ex in store.exercises.prefix(10) {
                if let url = ExerciseStore.imageURL(for: ex) {
                    _ = UIImage(contentsOfFile: url.path)
                }
            }
        }
    }

    func testWorkoutHistoryFirstPageWithOneThousandSessions() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FitGuideHistory-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                XCTFail("Failed to remove performance fixture: \(error)")
            }
        }
        let storeURL = directory.appendingPathComponent("history.store")
        try createLargeHistoryFixture(at: storeURL)
        try verifyLargeHistoryFixture(at: storeURL)
    }

    private func verifyLargeHistoryFixture(at storeURL: URL) throws {
        let container = try LibraryStore.makeContainer(storeURL: storeURL)
        let context = container.mainContext
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<WorkoutSession>()),
            1_000
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<WorkoutExercise>()),
            10_000
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<SetLog>()),
            50_000
        )

        let workoutStore = ActiveWorkoutStore(container: container)
        let started = CFAbsoluteTimeGetCurrent()
        let firstPage = workoutStore.completedSessions(limit: 30)
        let metrics = firstPage.map { WorkoutMetrics.calculate(for: $0) }
        let elapsed = CFAbsoluteTimeGetCurrent() - started
        XCTAssertEqual(firstPage.count, 30)
        XCTAssertEqual(metrics.count, 30)
        XCTAssertTrue(metrics.allSatisfy { $0.plannedSets == 50 })
        XCTAssertLessThan(
            elapsed,
            0.5,
            "History first page and row metrics took \(elapsed)s; target is < 0.5s"
        )

        measure {
            let page = workoutStore.completedSessions(limit: 30)
            XCTAssertEqual(
                page.map { WorkoutMetrics.calculate(for: $0) }.count,
                30
            )
        }
    }

    private func createLargeHistoryFixture(at storeURL: URL) throws {
        let container = try LibraryStore.makeContainer(storeURL: storeURL)
        let context = container.mainContext
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)

        for sessionIndex in 0..<1_000 {
            let startedAt = baseDate.addingTimeInterval(
                TimeInterval(sessionIndex * 60)
            )
            let session = WorkoutSession(
                startedAt: startedAt,
                endedAt: startedAt.addingTimeInterval(45),
                status: .completed
            )
            context.insert(session)

            for exerciseIndex in 0..<10 {
                let exercise = WorkoutExercise(
                    exerciseId: "fixture-\(sessionIndex)-\(exerciseIndex)",
                    exerciseNameZH: "测试动作 \(exerciseIndex + 1)",
                    exerciseNameEN: "Fixture Exercise \(exerciseIndex + 1)",
                    order: exerciseIndex,
                    plannedSets: 5,
                    targetReps: 10
                )
                exercise.session = session
                context.insert(exercise)

                for setIndex in 0..<5 {
                    let setLog = SetLog(
                        order: setIndex,
                        targetReps: 10,
                        actualReps: 10,
                        completedAt: session.endedAt
                    )
                    setLog.workoutExercise = exercise
                    context.insert(setLog)
                }
            }
        }
        try context.save()
    }

    func testWorkoutCriticalPathPerformanceTargets() throws {
        let container = try LibraryStore.makeContainer(isStoredInMemoryOnly: true)
        let library = LibraryStore(container: container)
        let suiteName = "PerformanceTests-\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        let workout = ActiveWorkoutStore(
            container: container,
            preferences: preferences
        )
        let plan = library.addPlan(named: "Performance fixture")
        var exercisesByID: [String: Exercise] = [:]

        for index in 0..<10 {
            let exercise = Exercise(
                id: "performance-\(index)",
                name: "fixture exercise \(index)",
                category: "strength",
                bodyPart: "chest",
                equipment: "barbell",
                instructions: ["zh": "步骤", "en": "Step"],
                instructionSteps: ["zh": ["步骤"], "en": ["Step"]],
                muscleGroup: "chest",
                secondaryMuscles: [],
                target: "pectorals",
                mediaId: "performance-\(index)",
                image: "performance-\(index).jpg",
                gifUrl: "performance-\(index).gif",
                attribution: Exercise.gymVisualAttribution,
                createdAt: "2026-07-31"
            )
            exercisesByID[exercise.id] = exercise
            library.addToPlan(
                plan,
                exerciseId: exercise.id,
                sets: 5,
                reps: 10,
                restSeconds: 90
            )
        }

        let startBegan = CFAbsoluteTimeGetCurrent()
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: exercisesByID)
        )
        let startElapsed = CFAbsoluteTimeGetCurrent() - startBegan
        XCTAssertLessThan(
            startElapsed,
            0.3,
            "Entering a 10-exercise workout took \(startElapsed)s; target is < 0.3s"
        )

        let firstSet = try XCTUnwrap(session.sortedExercises.first?.sortedSets.first)
        let completionBegan = CFAbsoluteTimeGetCurrent()
        workout.complete(firstSet, actualReps: 10, weightKg: 50)
        let completionElapsed = CFAbsoluteTimeGetCurrent() - completionBegan
        XCTAssertLessThan(
            completionElapsed,
            0.1,
            "Completing a set took \(completionElapsed)s; target is < 0.1s"
        )

        let restoreBegan = CFAbsoluteTimeGetCurrent()
        let restored = ActiveWorkoutStore(
            container: container,
            preferences: preferences
        )
        let restoreElapsed = CFAbsoluteTimeGetCurrent() - restoreBegan
        XCTAssertEqual(restored.activeSession?.id, session.id)
        XCTAssertLessThan(
            restoreElapsed,
            0.3,
            "Restoring an active workout took \(restoreElapsed)s; target is < 0.3s"
        )
    }
}
