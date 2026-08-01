import XCTest
import SwiftData
@testable import FitGuide

@MainActor
final class WorkoutStoreTests: XCTestCase {
    private enum ForcedPersistenceError: Error {
        case saveFailed
    }

    private var container: ModelContainer!
    private var library: LibraryStore!
    private var workout: ActiveWorkoutStore!

    override func setUpWithError() throws {
        container = try LibraryStore.makeContainer(isStoredInMemoryOnly: true)
        library = LibraryStore(container: container)
        workout = ActiveWorkoutStore(container: container)
    }

    override func tearDownWithError() throws {
        workout = nil
        library = nil
        container = nil
    }

    func testPlanCreatesIndependentWorkoutSnapshot() throws {
        let exercise = makeExercise(id: "bench", name: "barbell bench press")
        let plan = library.addPlan(named: "Push Day")
        library.addToPlan(
            plan,
            exerciseId: exercise.id,
            sets: 4,
            reps: 8,
            restSeconds: 120
        )

        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let snapshot = try XCTUnwrap(session.exercises.first)

        XCTAssertEqual(session.sourcePlanId, plan.id)
        XCTAssertEqual(session.planNameSnapshot, "Push Day")
        XCTAssertEqual(snapshot.exerciseId, exercise.id)
        XCTAssertEqual(snapshot.exerciseNameZHSnapshot, exercise.nameZH)
        XCTAssertEqual(snapshot.sets.count, 4)
        XCTAssertEqual(snapshot.targetReps, 8)
        XCTAssertEqual(snapshot.restSeconds, 120)

        let templateItem = try XCTUnwrap(plan.items.first)
        library.updateItem(templateItem, sets: 2, reps: 15, restSeconds: 30)

        XCTAssertEqual(snapshot.sets.count, 4)
        XCTAssertEqual(snapshot.targetReps, 8)
        XCTAssertEqual(snapshot.restSeconds, 120)
    }

    func testDeletingSourcePlanDoesNotChangeWorkoutSnapshot() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Snapshot source")
        library.addToPlan(
            plan,
            exerciseId: exercise.id,
            sets: 2,
            reps: 9,
            restSeconds: 75
        )
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )

        library.deletePlan(plan)

        let snapshot = try XCTUnwrap(session.exercises.first)
        XCTAssertEqual(session.planNameSnapshot, "Snapshot source")
        XCTAssertEqual(snapshot.exerciseNameZHSnapshot, exercise.nameZH)
        XCTAssertEqual(snapshot.sortedSets.count, 2)
        XCTAssertEqual(snapshot.targetReps, 9)
        XCTAssertEqual(snapshot.restSeconds, 75)
    }

    func testPlanWithMissingExerciseResourceDoesNotStartPartially() throws {
        let available = makeExercise(id: "available")
        let plan = library.addPlan(named: "Incomplete resources")
        library.addToPlan(plan, exerciseId: available.id)
        library.addToPlan(plan, exerciseId: "missing")

        let session = workout.start(
            plan: plan,
            exercisesById: [available.id: available]
        )

        XCTAssertNil(session)
        XCTAssertNil(workout.activeSession)
        XCTAssertNotNil(workout.lastErrorMessage)
        XCTAssertEqual(
            try container.mainContext.fetchCount(
                FetchDescriptor<WorkoutSession>()
            ),
            0
        )
    }

    func testCompletingSetPersistsMetricsAndRestTimer() throws {
        let exercise = makeExercise(id: "squat", name: "barbell full squat")
        let plan = library.addPlan(named: "Leg Day")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 2, reps: 5, restSeconds: 90)
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let set = try XCTUnwrap(session.exercises.first?.sortedSets.first)
        let completionTime = Date(timeIntervalSince1970: 1_000)

        workout.complete(set, actualReps: 5, weightKg: 100, at: completionTime)

        let metrics = WorkoutMetrics.calculate(for: session, now: completionTime)
        XCTAssertNotNil(set.completedAt)
        XCTAssertEqual(metrics.completedSets, 1)
        XCTAssertEqual(metrics.totalReps, 5)
        XCTAssertEqual(metrics.totalVolume, 500)
        XCTAssertEqual(metrics.completedExercises, 1)
        XCTAssertEqual(
            workout.remainingRestSeconds(in: session, now: completionTime),
            90
        )
    }

    func testUndoSetRestoresPendingState() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Plan")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 1, reps: 12)
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let set = try XCTUnwrap(session.exercises.first?.sets.first)

        workout.complete(set, actualReps: 10, weightKg: 20)
        workout.undo(set)

        XCTAssertNil(set.completedAt)
        XCTAssertEqual(session.currentSetId, set.id)
        XCTAssertEqual(WorkoutMetrics.calculate(for: session).completedSets, 0)
    }

    func testOnlyOneActiveSessionCanStart() throws {
        let first = try XCTUnwrap(workout.startQuickWorkout())
        let second = workout.startQuickWorkout()

        XCTAssertNil(second)
        XCTAssertEqual(workout.activeSession?.id, first.id)
        XCTAssertNotNil(workout.lastErrorMessage)
    }

    func testPersistenceFailureRollsBackSetAndCanRetry() throws {
        var shouldFail = false
        let context = container.mainContext
        let store = ActiveWorkoutStore(
            container: container,
            saveAction: {
                if shouldFail {
                    throw ForcedPersistenceError.saveFailed
                }
                try context.save()
            },
            rollbackAction: {
                context.rollback()
            }
        )
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Failure recovery")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 1, reps: 10)
        let session = try XCTUnwrap(
            store.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let set = try XCTUnwrap(session.exercises.first?.sets.first)

        shouldFail = true
        store.complete(set, actualReps: 8, weightKg: 20)

        XCTAssertNil(set.completedAt)
        XCTAssertNotNil(store.lastErrorMessage)
        XCTAssertEqual(store.activeSession?.id, session.id)

        shouldFail = false
        store.clearError()
        store.complete(set, actualReps: 8, weightKg: 20)

        XCTAssertNotNil(set.completedAt)
        XCTAssertNil(store.lastErrorMessage)
        XCTAssertEqual(WorkoutMetrics.calculate(for: session).completedSets, 1)
    }

    func testLibraryPersistenceFailureRollsBackAndReportsError() throws {
        var shouldFail = false
        let context = container.mainContext
        let store = LibraryStore(
            container: container,
            saveAction: {
                if shouldFail {
                    throw ForcedPersistenceError.saveFailed
                }
                try context.save()
            },
            rollbackAction: {
                context.rollback()
            }
        )
        let plan = store.addPlan(named: "Original")

        shouldFail = true
        store.renamePlan(plan, to: "Not saved")

        XCTAssertEqual(plan.name, "Original")
        XCTAssertNotNil(store.lastErrorMessage)

        shouldFail = false
        store.clearError()
        store.renamePlan(plan, to: "Saved")
        XCTAssertEqual(plan.name, "Saved")
        XCTAssertNil(store.lastErrorMessage)
    }

    func testCreatePlanWithFirstExerciseIsAtomicOnSaveFailure() throws {
        let context = container.mainContext
        let store = LibraryStore(
            container: container,
            saveAction: {
                throw ForcedPersistenceError.saveFailed
            },
            rollbackAction: {
                context.rollback()
            }
        )

        XCTAssertFalse(
            store.createPlan(named: "Should not persist", adding: "exercise-1")
        )
        XCTAssertNotNil(store.lastErrorMessage)
        XCTAssertTrue(store.trainingPlans.isEmpty)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<TrainingPlan>()),
            0
        )
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<TrainingPlanItem>()),
            0
        )
    }

    func testEmptyWorkoutCannotBeMarkedCompleted() throws {
        let session = try XCTUnwrap(workout.startQuickWorkout())

        XCTAssertNil(workout.finishActiveSession())
        XCTAssertEqual(session.status, .active)
        XCTAssertNotNil(workout.lastErrorMessage)
    }

    func testFinishCreatesCompletedHistoryWithoutChangingPlan() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Stable Template")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 1, reps: 10)
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let set = try XCTUnwrap(session.exercises.first?.sets.first)
        workout.complete(set, actualReps: 9, weightKg: 25)

        let completed = try XCTUnwrap(workout.finishActiveSession())

        XCTAssertEqual(completed.status, .completed)
        XCTAssertNotNil(completed.endedAt)
        XCTAssertNil(workout.activeSession)
        XCTAssertEqual(workout.completedSessions().map(\.id), [completed.id])
        XCTAssertEqual(plan.items.first?.sets, 1)
        XCTAssertEqual(plan.items.first?.reps, 10)
        XCTAssertEqual(plan.items.first?.completedAt, nil)
    }

    func testAbandonedSessionDoesNotAppearInCompletedHistory() throws {
        let session = try XCTUnwrap(workout.startQuickWorkout())
        let abandoned = try XCTUnwrap(workout.abandonActiveSession())

        XCTAssertEqual(abandoned.id, session.id)
        XCTAssertEqual(abandoned.status, .abandoned)
        XCTAssertTrue(workout.completedSessions().isEmpty)
    }

    func testRestTimerPauseResumeExtendAndSkip() throws {
        let session = try XCTUnwrap(workout.startQuickWorkout())
        let start = Date(timeIntervalSince1970: 2_000)

        workout.startRest(seconds: 60, in: session, now: start)
        workout.pauseRest(in: session, now: start.addingTimeInterval(10))
        XCTAssertEqual(workout.remainingRestSeconds(in: session, now: start.addingTimeInterval(40)), 50)

        workout.extendRest(by: 15, in: session, now: start.addingTimeInterval(40))
        XCTAssertEqual(workout.remainingRestSeconds(in: session, now: start.addingTimeInterval(40)), 65)

        workout.resumeRest(in: session, now: start.addingTimeInterval(40))
        XCTAssertEqual(workout.remainingRestSeconds(in: session, now: start.addingTimeInterval(50)), 55)

        workout.skipRest(in: session)
        XCTAssertEqual(workout.remainingRestSeconds(in: session, now: start), 0)
        XCTAssertNil(session.restEndsAt)
        XCTAssertNil(session.restPausedRemaining)
    }

    func testLegacyPlanCompletionStateDoesNotBecomeHistory() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Legacy")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 2, reps: 12)
        let item = try XCTUnwrap(plan.items.first)
        library.toggleSet(item, at: 0)

        let newStore = ActiveWorkoutStore(container: container)

        XCTAssertTrue(newStore.completedSessions().isEmpty)
        XCTAssertEqual(plan.items.first?.sets, 2)
        XCTAssertEqual(plan.items.first?.reps, 12)
    }

    func testLegacyOptionalDefaultsAreBackfilled() throws {
        let plan = TrainingPlan(name: "Legacy", updatedAt: nil)
        let item = TrainingPlanItem(exerciseId: "legacy")
        item.restSecondsRaw = nil
        item.plan = plan
        container.mainContext.insert(plan)
        container.mainContext.insert(item)
        try container.mainContext.save()

        _ = LibraryStore(container: container)

        XCTAssertEqual(plan.updatedAt, plan.createdAt)
        XCTAssertEqual(item.restSecondsRaw, DefaultRestSeconds)
    }

    func testFrozenV1StoreMigratesWithoutLosingUserData() throws {
        let fixtureURL = try XCTUnwrap(
            Bundle(for: WorkoutStoreTests.self).url(
                forResource: "v1",
                withExtension: "store"
            )
        )
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FitGuideV1Migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer {
            do {
                try FileManager.default.removeItem(at: directory)
            } catch {
                XCTFail("Failed to remove migration fixture copy: \(error)")
            }
        }
        let migratedStoreURL = directory.appendingPathComponent("migrated.store")
        try FileManager.default.copyItem(
            at: fixtureURL,
            to: migratedStoreURL
        )

        do {
            let migratedContainer = try LibraryStore.makeContainer(
                storeURL: migratedStoreURL
            )
            let migratedLibrary = LibraryStore(container: migratedContainer)
            let context = migratedContainer.mainContext

            XCTAssertEqual(
                try context.fetchCount(FetchDescriptor<FavoriteList>()),
                2
            )
            XCTAssertEqual(
                try context.fetchCount(FetchDescriptor<FavoriteItem>()),
                2
            )
            XCTAssertEqual(migratedLibrary.recentViews.map(\.exerciseId), ["0002"])
            XCTAssertEqual(migratedLibrary.trainingPlans.count, 1)

            let plan = try XCTUnwrap(migratedLibrary.trainingPlans.first)
            XCTAssertEqual(plan.id, "legacy-plan")
            XCTAssertEqual(plan.name, "Legacy Plan")
            XCTAssertEqual(plan.updatedAt, plan.createdAt)

            let items = plan.items.sorted { $0.order < $1.order }
            XCTAssertEqual(items.map(\.exerciseId), ["0001", "0002"])
            XCTAssertEqual(items.map(\.sets), [3, 2])
            XCTAssertEqual(items.map(\.reps), [12, 8])
            XCTAssertEqual(items.map(\.setStatesRaw), ["101", "11"])
            XCTAssertNil(items[0].completedAt)
            XCTAssertEqual(
                items[1].completedAt,
                Date(timeIntervalSince1970: 1_700_000_006)
            )
            XCTAssertTrue(
                items.allSatisfy {
                    $0.restSecondsRaw == DefaultRestSeconds
                }
            )
            XCTAssertEqual(
                try context.fetchCount(FetchDescriptor<WorkoutSession>()),
                0
            )
        }
    }

    func testEditingV2TemplateFieldsPreservesLegacyCompletionData() throws {
        let plan = library.addPlan(named: "Legacy state")
        library.addToPlan(plan, exerciseId: "legacy", sets: 3, reps: 12)
        let item = try XCTUnwrap(plan.items.first)
        item.setStatesRaw = "101"
        let legacyCompletion = Date(timeIntervalSince1970: 10_000)
        item.completedAt = legacyCompletion
        try container.mainContext.save()

        library.updateItem(item, sets: 4, reps: 8, restSeconds: 120)

        XCTAssertEqual(item.sets, 4)
        XCTAssertEqual(item.reps, 8)
        XCTAssertEqual(item.restSeconds, 120)
        XCTAssertEqual(item.setStatesRaw, "101")
        XCTAssertEqual(item.completedAt, legacyCompletion)
    }

    func testWorkoutCanAdjustSetCountAndExerciseOrder() throws {
        let first = makeExercise(id: "first")
        let second = makeExercise(id: "second", name: "barbell row")
        let session = try XCTUnwrap(workout.startQuickWorkout())
        workout.addExercise(first, to: session)
        workout.addExercise(second, to: session)
        let firstWorkout = try XCTUnwrap(
            session.exercises.first { $0.exerciseId == first.id }
        )

        workout.updateSetCount(for: firstWorkout, to: 5)
        workout.moveExercise(firstWorkout, by: 1)

        XCTAssertEqual(firstWorkout.sets.count, 5)
        XCTAssertEqual(session.sortedExercises.last?.exerciseId, first.id)

        workout.updateSetCount(for: firstWorkout, to: 2)
        XCTAssertEqual(firstWorkout.sets.count, 2)
    }

    func testShrinkingSetCountRenumbersRetainedCompletedSets() throws {
        let exercise = makeExercise()
        let session = try XCTUnwrap(workout.startQuickWorkout())
        workout.addExercise(exercise, to: session, sets: 5, reps: 8)
        let workoutExercise = try XCTUnwrap(session.exercises.first)
        let originalSets = workoutExercise.sortedSets

        workout.select(exercise: workoutExercise, set: originalSets[4])
        workout.complete(originalSets[4], actualReps: 8, weightKg: 20)
        workout.updateSetCount(for: workoutExercise, to: 1)

        XCTAssertEqual(workoutExercise.sortedSets.count, 1)
        XCTAssertEqual(workoutExercise.sortedSets.map(\.order), [0])
        XCTAssertNotNil(workoutExercise.sortedSets[0].completedAt)
        XCTAssertEqual(workoutExercise.plannedSets, 1)

        workout.updateSetCount(for: workoutExercise, to: 3)
        XCTAssertEqual(workoutExercise.sortedSets.map(\.order), [0, 1, 2])
    }

    func testSkippedExerciseCanBeSelectedAndUnskipped() throws {
        let first = makeExercise(id: "first")
        let second = makeExercise(id: "second", name: "barbell row")
        let third = makeExercise(id: "third", name: "barbell squat")
        let session = try XCTUnwrap(workout.startQuickWorkout())
        workout.addExercise(first, to: session)
        workout.addExercise(second, to: session)
        workout.addExercise(third, to: session)
        let secondWorkout = try XCTUnwrap(
            session.exercises.first { $0.exerciseId == second.id }
        )

        workout.toggleSkipped(secondWorkout)
        XCTAssertTrue(secondWorkout.isSkipped)

        workout.select(exercise: secondWorkout)
        XCTAssertEqual(workout.currentExercise(in: session)?.id, secondWorkout.id)

        workout.toggleSkipped(secondWorkout)
        XCTAssertFalse(secondWorkout.isSkipped)
        XCTAssertEqual(workout.currentExercise(in: session)?.id, secondWorkout.id)
    }

    func testOnlySkippedExerciseRemainsReachableForUnskip() throws {
        let exercise = makeExercise()
        let session = try XCTUnwrap(workout.startQuickWorkout())
        workout.addExercise(exercise, to: session)
        let onlyExercise = try XCTUnwrap(session.exercises.first)

        workout.toggleSkipped(onlyExercise)

        XCTAssertTrue(onlyExercise.isSkipped)
        XCTAssertEqual(workout.currentExercise(in: session)?.id, onlyExercise.id)

        workout.toggleSkipped(onlyExercise)
        XCTAssertFalse(onlyExercise.isSkipped)
    }

    func testWorkoutVolumeFormattingUsesKgRepsUnits() {
        XCTAssertEqual(WorkoutFormatting.volume(500), "500 kg·reps")
        XCTAssertEqual(WorkoutFormatting.volume(1_250), "1.2k kg·reps")
    }

    func testDeletingCurrentMiddleExerciseReordersAndSelectsRetainedExercise() throws {
        let first = makeExercise(id: "first")
        let second = makeExercise(id: "second", name: "barbell row")
        let third = makeExercise(id: "third", name: "barbell squat")
        let session = try XCTUnwrap(workout.startQuickWorkout())
        workout.addExercise(first, to: session)
        workout.addExercise(second, to: session)
        workout.addExercise(third, to: session)
        let middle = try XCTUnwrap(
            session.exercises.first { $0.exerciseId == second.id }
        )
        workout.select(exercise: middle)

        workout.deleteExercise(middle)

        XCTAssertEqual(session.sortedExercises.map(\.exerciseId), ["first", "third"])
        XCTAssertEqual(session.sortedExercises.map(\.order), [0, 1])
        XCTAssertNotEqual(session.currentExerciseId, middle.id)
        XCTAssertTrue(
            session.sortedExercises.contains {
                $0.id == session.currentExerciseId
            }
        )
    }

    func testRestoreKeepsNewestActiveSessionAndAbandonsDuplicates() throws {
        let older = WorkoutSession(
            startedAt: Date(timeIntervalSince1970: 100),
            status: .active
        )
        let newer = WorkoutSession(
            startedAt: Date(timeIntervalSince1970: 200),
            status: .active
        )
        container.mainContext.insert(older)
        container.mainContext.insert(newer)
        try container.mainContext.save()

        let restored = ActiveWorkoutStore(container: container)

        XCTAssertEqual(restored.activeSession?.id, newer.id)
        XCTAssertEqual(older.status, .abandoned)
        XCTAssertNotNil(older.endedAt)
    }

    func testRestoreCollapsesMoreThanTwentyActiveSessionsToOne() throws {
        var sessions: [WorkoutSession] = []
        for index in 0..<25 {
            let session = WorkoutSession(
                startedAt: Date(timeIntervalSince1970: TimeInterval(index)),
                status: .active
            )
            sessions.append(session)
            container.mainContext.insert(session)
        }
        try container.mainContext.save()

        let restored = ActiveWorkoutStore(container: container)
        let activeValue = WorkoutStatus.active.rawValue
        let activeDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.statusRaw == activeValue }
        )

        XCTAssertEqual(restored.activeSession?.id, sessions.last?.id)
        XCTAssertEqual(
            try container.mainContext.fetchCount(activeDescriptor),
            1
        )
    }

    func testMetricsIncludeSkippedSetsButExcludeSkippedCompletedExercise() {
        let session = WorkoutSession(
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 700),
            status: .completed
        )
        let completedExercise = WorkoutExercise(
            exerciseId: "one",
            exerciseNameZH: "动作一",
            exerciseNameEN: "One",
            order: 0,
            plannedSets: 2,
            targetReps: 10
        )
        let completed = SetLog(
            order: 0,
            targetReps: 10,
            actualReps: 8,
            weightKg: 12.5,
            completedAt: Date(timeIntervalSince1970: 200)
        )
        let incomplete = SetLog(order: 1, targetReps: 10)
        completed.workoutExercise = completedExercise
        incomplete.workoutExercise = completedExercise
        completedExercise.session = session

        let skippedExercise = WorkoutExercise(
            exerciseId: "two",
            exerciseNameZH: "动作二",
            exerciseNameEN: "Two",
            order: 1,
            isSkipped: true
        )
        let skippedSet = SetLog(
            order: 0,
            targetReps: 12,
            actualReps: 12,
            weightKg: 100,
            completedAt: Date(timeIntervalSince1970: 300)
        )
        skippedSet.workoutExercise = skippedExercise
        skippedExercise.session = session

        let metrics = WorkoutMetrics.calculate(for: session)

        XCTAssertEqual(metrics.duration, 600)
        XCTAssertEqual(metrics.plannedSets, 3)
        XCTAssertEqual(metrics.completedSets, 2)
        XCTAssertEqual(metrics.totalReps, 20)
        XCTAssertEqual(metrics.totalVolume, 1_300)
        XCTAssertEqual(metrics.completedExercises, 1)
    }

    func testMetricsCoverEmptyWarmupAndWeightlessSets() {
        let start = Date(timeIntervalSince1970: 100)
        let empty = WorkoutSession(startedAt: start, status: .active)
        XCTAssertEqual(
            WorkoutMetrics.calculate(
                for: empty,
                now: start.addingTimeInterval(30)
            ),
            WorkoutMetrics(
                duration: 30,
                plannedSets: 0,
                completedSets: 0,
                totalReps: 0,
                totalVolume: 0,
                completedExercises: 0
            )
        )

        let exercise = WorkoutExercise(
            exerciseId: "warmup",
            exerciseNameZH: "热身动作",
            exerciseNameEN: "Warmup",
            order: 0,
            plannedSets: 2,
            targetReps: 10
        )
        let warmup = SetLog(
            order: 0,
            targetReps: 10,
            actualReps: 12,
            weightKg: 2.5,
            completedAt: start,
            isWarmup: true
        )
        let weightless = SetLog(
            order: 1,
            targetReps: 10,
            actualReps: 8,
            weightKg: nil,
            completedAt: start
        )
        exercise.session = empty
        warmup.workoutExercise = exercise
        weightless.workoutExercise = exercise

        let metrics = WorkoutMetrics.calculate(
            for: empty,
            now: start.addingTimeInterval(60)
        )
        XCTAssertEqual(metrics.plannedSets, 2)
        XCTAssertEqual(metrics.completedSets, 2)
        XCTAssertEqual(metrics.totalReps, 20)
        XCTAssertEqual(metrics.totalVolume, 30)
        XCTAssertEqual(metrics.completedExercises, 1)
    }

    func testAutoRestTimerPreferenceCanDisableAutomaticStart() throws {
        let suiteName = "WorkoutStoreTests-\(UUID().uuidString)"
        let preferences = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { preferences.removePersistentDomain(forName: suiteName) }
        preferences.set(false, forKey: ActiveWorkoutStore.autoStartRestTimerKey)

        let store = ActiveWorkoutStore(
            container: container,
            preferences: preferences
        )
        let exercise = makeExercise()
        let plan = library.addPlan(named: "No automatic rest")
        library.addToPlan(
            plan,
            exerciseId: exercise.id,
            sets: 2,
            reps: 8,
            restSeconds: 90
        )
        let session = try XCTUnwrap(
            store.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let firstSet = try XCTUnwrap(session.exercises.first?.sortedSets.first)

        store.complete(
            firstSet,
            actualReps: 8,
            weightKg: nil,
            at: Date(timeIntervalSince1970: 1_000)
        )

        XCTAssertNil(session.restEndsAt)
        XCTAssertNil(session.restPausedRemaining)

        store.restTimerSoundEnabled = true
        XCTAssertEqual(
            preferences.bool(forKey: ActiveWorkoutStore.restTimerSoundKey),
            true
        )
    }

    func testNextSetInheritsCompletedSetWeight() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Weight")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 2, reps: 8)
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let sets = try XCTUnwrap(session.exercises.first?.sortedSets)

        workout.complete(sets[0], actualReps: 8, weightKg: 42.5)

        XCTAssertEqual(sets[1].weightKg, 42.5)
        XCTAssertEqual(sets[1].actualReps, 8)
    }

    func testCompletedSessionRejectsFurtherSetChangesAndKeepsEndDate() throws {
        let exercise = makeExercise()
        let plan = library.addPlan(named: "Immutable History")
        library.addToPlan(plan, exerciseId: exercise.id, sets: 1, reps: 10)
        let session = try XCTUnwrap(
            workout.start(plan: plan, exercisesById: [exercise.id: exercise])
        )
        let set = try XCTUnwrap(session.exercises.first?.sets.first)
        workout.complete(set, actualReps: 10, weightKg: 20)
        let end = Date(timeIntervalSince1970: 5_000)
        _ = workout.finishActiveSession(at: end)

        workout.update(set, actualReps: 1, weightKg: 1)
        workout.undo(set)

        XCTAssertEqual(set.actualReps, 10)
        XCTAssertEqual(set.weightKg, 20)
        XCTAssertNotNil(set.completedAt)
        XCTAssertEqual(session.endedAt, end)
        XCTAssertNil(workout.finishActiveSession(at: end.addingTimeInterval(100)))
        XCTAssertEqual(session.endedAt, end)
    }

    func testUnknownStoredStatusFallsBackToAbandoned() {
        let session = WorkoutSession()
        session.statusRaw = "unknown-status"

        XCTAssertEqual(session.status, .abandoned)
    }

    func testHistoryPaginationIsNewestFirst() throws {
        let base = Date(timeIntervalSince1970: 10_000)
        for index in 0..<5 {
            let session = WorkoutSession(
                startedAt: base.addingTimeInterval(TimeInterval(index)),
                endedAt: base.addingTimeInterval(TimeInterval(index)),
                status: .completed
            )
            container.mainContext.insert(session)
        }
        try container.mainContext.save()

        let firstPage = workout.completedSessions(limit: 2)
        let secondPage = workout.completedSessions(limit: 2, offset: 2)

        XCTAssertEqual(firstPage.map(\.endedAt), [
            base.addingTimeInterval(4),
            base.addingTimeInterval(3)
        ])
        XCTAssertEqual(secondPage.map(\.endedAt), [
            base.addingTimeInterval(2),
            base.addingTimeInterval(1)
        ])
    }

    func testDeletingHistoryCascadesToExercisesAndSets() throws {
        let session = WorkoutSession(
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200),
            status: .completed
        )
        let exercise = WorkoutExercise(
            exerciseId: "cascade",
            exerciseNameZH: "级联动作",
            exerciseNameEN: "Cascade",
            order: 0
        )
        let setLog = SetLog(order: 0, targetReps: 12)
        exercise.session = session
        setLog.workoutExercise = exercise
        container.mainContext.insert(session)
        container.mainContext.insert(exercise)
        container.mainContext.insert(setLog)
        try container.mainContext.save()

        workout.deleteHistory(session)

        XCTAssertEqual(
            try container.mainContext.fetchCount(FetchDescriptor<WorkoutSession>()),
            0
        )
        XCTAssertEqual(
            try container.mainContext.fetchCount(FetchDescriptor<WorkoutExercise>()),
            0
        )
        XCTAssertEqual(
            try container.mainContext.fetchCount(FetchDescriptor<SetLog>()),
            0
        )
    }

    func testDeletingHistorySaveFailureKeepsRecordAndReportsError() throws {
        let session = WorkoutSession(
            startedAt: Date(timeIntervalSince1970: 100),
            endedAt: Date(timeIntervalSince1970: 200),
            status: .completed
        )
        container.mainContext.insert(session)
        try container.mainContext.save()
        let context = container.mainContext
        let failingStore = ActiveWorkoutStore(
            container: container,
            saveAction: {
                throw ForcedPersistenceError.saveFailed
            },
            rollbackAction: {
                context.rollback()
            }
        )

        XCTAssertFalse(failingStore.deleteHistory(session))
        XCTAssertNotNil(failingStore.lastErrorMessage)
        XCTAssertEqual(
            try context.fetchCount(FetchDescriptor<WorkoutSession>()),
            1
        )
    }

    private func makeExercise(
        id: String = "exercise-1",
        name: String = "barbell bench press"
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            category: "strength",
            bodyPart: "chest",
            equipment: "barbell",
            instructions: ["zh": "步骤", "en": "Steps"],
            instructionSteps: ["zh": ["步骤"], "en": ["Step"]],
            muscleGroup: "chest",
            secondaryMuscles: [],
            target: "pectorals",
            mediaId: id,
            image: "\(id).jpg",
            gifUrl: "\(id).gif",
            attribution: Exercise.gymVisualAttribution,
            createdAt: "2026-07-31"
        )
    }
}
