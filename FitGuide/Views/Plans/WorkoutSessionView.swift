import SwiftUI
import UIKit
import AudioToolbox

struct WorkoutSessionView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore
    @EnvironmentObject private var exerciseStore: ExerciseStore

    @State private var showExercisePicker = false
    @State private var referenceExercise: Exercise?
    @State private var confirmFinish = false
    @State private var confirmAbandon = false

    private var currentWorkoutExercise: WorkoutExercise? {
        workoutStore.currentExercise(in: session)
    }

    var body: some View {
        Group {
            if session.status == .completed {
                WorkoutSummaryView(session: session, isHistory: false) {
                    dismiss()
                }
            } else {
                NavigationStack {
                    ZStack {
                        SpaceBackground()
                        ScrollView {
                            VStack(spacing: Spacing.m.rawValue) {
                                workoutProgress

                                if let workoutExercise = currentWorkoutExercise {
                                    currentExerciseCard(workoutExercise)
                                } else {
                                    emptyWorkout
                                }

                                if !session.exercises.isEmpty {
                                    exerciseNavigator
                                }

                                Color.clear.frame(height: 190)
                            }
                            .padding(Spacing.m.rawValue)
                        }

                        VStack {
                            Spacer()
                            if workoutStore.remainingRestSeconds(in: session) > 0
                                || session.restPausedRemaining != nil {
                                RestTimerOverlay(session: session)
                                    .padding(Spacing.m.rawValue)
                            }
                        }
                    }
                    .navigationTitle(session.displayName)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                            }
                            .accessibilityLabel("退出并保留训练 Save and close workout")
                            .accessibilityIdentifier("workout.close")
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button {
                                    showExercisePicker = true
                                } label: {
                                    Label("添加动作 Add Exercise", systemImage: "plus")
                                }
                                Button {
                                    confirmFinish = true
                                } label: {
                                    Label("结束训练 Finish", systemImage: "checkmark.circle")
                                }
                                Button(role: .destructive) {
                                    confirmAbandon = true
                                } label: {
                                    Label("放弃训练 Abandon", systemImage: "xmark.circle")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .accessibilityLabel("训练操作 Workout options")
                            .accessibilityIdentifier("workout.sessionMenu")
                        }
                    }
                }
                .interactiveDismissDisabled()
                .sheet(isPresented: $showExercisePicker) {
                    WorkoutExercisePicker(session: session)
                }
                .sheet(item: $referenceExercise) { exercise in
                    NavigationStack {
                        ExerciseDetailView(exercise: exercise)
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("关闭 Close") {
                                        referenceExercise = nil
                                    }
                                }
                            }
                    }
                }
                .confirmationDialog(
                    unfinishedSets > 0
                        ? "还有 \(unfinishedSets) 组未完成，仍要结束吗？"
                            + " \(unfinishedSets) sets remain. Finish anyway?"
                        : "确认完成本次训练？ Finish this workout?",
                    isPresented: $confirmFinish,
                    titleVisibility: .visible
                ) {
                    Button("结束训练 Finish Workout") {
                        _ = workoutStore.finishActiveSession()
                    }
                    Button("继续训练 Continue", role: .cancel) {}
                }
                .confirmationDialog(
                    "放弃后会保留为未完成记录，但不会出现在完成历史中。"
                        + " It will be kept as abandoned and excluded from completed history.",
                    isPresented: $confirmAbandon,
                    titleVisibility: .visible
                ) {
                    Button("放弃训练 Abandon", role: .destructive) {
                        if workoutStore.abandonActiveSession() != nil {
                            dismiss()
                        }
                    }
                    Button("取消 Cancel", role: .cancel) {}
                }
                .alert(
                    "无法完成操作 · Operation failed",
                    isPresented: Binding(
                        get: { workoutStore.lastErrorMessage != nil },
                        set: { if !$0 { workoutStore.clearError() } }
                    )
                ) {
                    Button("好 OK", role: .cancel) {
                        workoutStore.clearError()
                    }
                } message: {
                    Text(workoutStore.lastErrorMessage ?? "未知错误 Unknown error")
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var unfinishedSets: Int {
        session.exercises
            .filter { !$0.isSkipped }
            .flatMap(\.sets)
            .filter { $0.completedAt == nil }
            .count
    }

    private var workoutProgress: some View {
        let metrics = WorkoutMetrics.calculate(for: session)
        return GlassCard(padding: Spacing.s.rawValue) {
            VStack(spacing: Spacing.xs.rawValue) {
                HStack {
                    Label("训练进度 Progress", systemImage: "chart.bar.fill")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text("\(metrics.completedSets)/\(metrics.plannedSets)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(Color.accentColor)
                }
                ProgressView(
                    value: Double(metrics.completedSets),
                    total: Double(max(1, metrics.plannedSets))
                )
                .tint(Color.accentColor)
                .accessibilityHidden(true)
            }
        }
    }

    private func currentExerciseCard(_ workoutExercise: WorkoutExercise) -> some View {
        let exercise = exerciseStore.exercises.first { $0.id == workoutExercise.exerciseId }
        let currentSet = workoutStore.currentSet(in: workoutExercise)

        return VStack(spacing: Spacing.m.rawValue) {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workoutExercise.exerciseNameZHSnapshot)
                                .font(.title2.weight(.bold))
                                .foregroundColor(.textPrimary)
                            Text(workoutExercise.exerciseNameENSnapshot.uppercased())
                                .font(.caption.smallCaps())
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        if let exercise {
                            Button {
                                referenceExercise = exercise
                            } label: {
                                Label("动作参考 Guide", systemImage: "figure.strengthtraining.traditional")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(Color.accentColor)
                        }
                        workoutExerciseMenu(workoutExercise)
                    }

                    if let exercise, let url = ExerciseStore.gifURL(for: exercise) {
                        GIFPlayerView(url: url)
                            .frame(height: 190)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: Radii.chip.rawValue))
                            .accessibilityLabel(
                                Text("\(exercise.nameZH)，主目标肌群：\(exercise.targetZH)")
                            )
                    }

                    if workoutExercise.isSkipped {
                        Label("已跳过 · SKIPPED", systemImage: "forward.fill")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .accessibilityLabel("动作已跳过 Exercise skipped")
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.s.rawValue) {
                            ForEach(workoutExercise.sortedSets) { setLog in
                                Button {
                                    workoutStore.select(exercise: workoutExercise, set: setLog)
                                } label: {
                                    Image(systemName: setSymbol(setLog))
                                        .font(.title3)
                                        .foregroundColor(setColor(setLog, currentSet: currentSet))
                                        .frame(minWidth: 44, minHeight: 44)
                                }
                                .accessibilityLabel(
                                    setAccessibilityLabel(setLog)
                                )
                                .disabled(workoutExercise.isSkipped)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if workoutExercise.isSkipped {
                GlassCard {
                    Text("此动作已跳过，可从动作菜单选择“取消跳过”。")
                        .font(.subheadline)
                        .foregroundColor(.textPrimary)
                    Text("This exercise is skipped. Use the exercise menu to unskip it.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            } else if let currentSet {
                CurrentSetEditor(
                    setLog: currentSet,
                    workoutExercise: workoutExercise
                )
                .id(currentSet.id)
            }
        }
    }

    private var emptyWorkout: some View {
        GlassCard {
            VStack(spacing: Spacing.m.rawValue) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color.accentColor)
                Text("添加第一个动作")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text("Add the first exercise to this workout.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Button("添加动作 Add Exercise") {
                    showExercisePicker = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
                .accessibilityIdentifier("workout.addExercise.empty")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func workoutExerciseMenu(_ exercise: WorkoutExercise) -> some View {
        let sorted = session.sortedExercises
        let index = sorted.firstIndex(where: { $0.id == exercise.id }) ?? 0

        return Menu {
            Button {
                workoutStore.updateSetCount(for: exercise, to: exercise.sets.count + 1)
            } label: {
                Label("增加一组 Add Set", systemImage: "plus.circle")
            }
            Button {
                workoutStore.updateSetCount(for: exercise, to: exercise.sets.count - 1)
            } label: {
                Label("减少一组 Remove Set", systemImage: "minus.circle")
            }
            .disabled(exercise.sets.count <= max(1, exercise.completedSetCount))

            Divider()
            Button {
                workoutStore.moveExercise(exercise, by: -1)
            } label: {
                Label("前移 Move Earlier", systemImage: "arrow.up")
            }
            .disabled(index == 0)
            Button {
                workoutStore.moveExercise(exercise, by: 1)
            } label: {
                Label("后移 Move Later", systemImage: "arrow.down")
            }
            .disabled(index >= sorted.count - 1)

            Divider()
            Button {
                workoutStore.toggleSkipped(exercise)
            } label: {
                Label(
                    exercise.isSkipped ? "取消跳过 Unskip" : "跳过动作 Skip",
                    systemImage: exercise.isSkipped ? "arrow.uturn.backward" : "forward.fill"
                )
            }
            Button(role: .destructive) {
                workoutStore.deleteExercise(exercise)
            } label: {
                Label("删除动作 Delete", systemImage: "trash")
            }
            .disabled(exercise.completedSetCount > 0)
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("动作操作 Exercise options")
    }

    private var exerciseNavigator: some View {
        let sorted = session.sortedExercises
        let currentIndex = currentWorkoutExercise.flatMap { current in
            sorted.firstIndex(where: { $0.id == current.id })
        } ?? 0

        return GlassCard(padding: Spacing.s.rawValue) {
            HStack {
                Button {
                    guard currentIndex > 0 else { return }
                    workoutStore.select(exercise: sorted[currentIndex - 1])
                } label: {
                    Label("上一个 Previous", systemImage: "chevron.left")
                }
                .disabled(currentIndex <= 0)

                Spacer()
                Text("\(min(currentIndex + 1, sorted.count))/\(sorted.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.textSecondary)
                Spacer()

                Button {
                    guard currentIndex < sorted.count - 1 else { return }
                    workoutStore.select(exercise: sorted[currentIndex + 1])
                } label: {
                    Label("下一个 Next", systemImage: "chevron.right")
                        .labelStyle(.titleAndIcon)
                }
                .disabled(currentIndex >= sorted.count - 1)
            }
            .font(.caption)
            .foregroundColor(Color.accentColor)
        }
    }

    private func setSymbol(_ setLog: SetLog) -> String {
        if setLog.completedAt != nil { return "checkmark.circle.fill" }
        if session.currentSetId == setLog.id { return "circle.inset.filled" }
        return "circle"
    }

    private func setColor(_ setLog: SetLog, currentSet: SetLog?) -> Color {
        if setLog.completedAt != nil { return Color.accentColor }
        if currentSet?.id == setLog.id { return .textPrimary }
        return .textSecondary
    }

    private func setAccessibilityLabel(_ setLog: SetLog) -> String {
        let status = setLog.completedAt == nil
            ? "未完成 Not completed"
            : "已完成 Completed"
        let weight = setLog.weightKg.map {
            "\(String(format: "%g", $0)) 千克 kilograms"
        } ?? "重量未填写 Weight not set"
        return "第 \(setLog.order + 1) 组 Set \(setLog.order + 1)，"
            + "目标 \(setLog.targetReps) 次 target \(setLog.targetReps) reps，"
            + "实际 \(setLog.actualReps) 次 actual \(setLog.actualReps) reps，"
            + "\(weight)，\(status)"
    }
}

private struct CurrentSetEditor: View {
    @Bindable var setLog: SetLog
    let workoutExercise: WorkoutExercise

    @EnvironmentObject private var workoutStore: ActiveWorkoutStore
    @State private var weightText: String
    @State private var reps: Int

    init(setLog: SetLog, workoutExercise: WorkoutExercise) {
        self.setLog = setLog
        self.workoutExercise = workoutExercise
        _weightText = State(
            initialValue: setLog.weightKg.map { String(format: "%g", $0) } ?? ""
        )
        _reps = State(initialValue: setLog.actualReps)
    }

    var body: some View {
        GlassCard {
            VStack(spacing: Spacing.m.rawValue) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("第 \(setLog.order + 1) 组")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("SET \(setLog.order + 1) OF \(workoutExercise.sets.count)")
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                        Text("目标 \(setLog.targetReps) 次 · TARGET \(setLog.targetReps) REPS")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if setLog.completedAt != nil {
                        Label("已完成 Done", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Color.accentColor)
                    }
                }

                HStack(spacing: Spacing.m.rawValue) {
                    VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                        Text("重量 Weight (kg)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        TextField("可选 Optional", text: $weightText)
                            .keyboardType(.decimalPad)
                            .font(.title2.monospacedDigit())
                            .foregroundColor(.textPrimary)
                            .padding(Spacing.s.rawValue)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityLabel("重量 Weight in kilograms")
                            .accessibilityValue(
                                weightText.isEmpty
                                    ? "未填写 Not set"
                                    : "\(weightText) kilograms"
                            )
                    }

                    VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                        Text("次数 Reps")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Stepper(value: $reps, in: 0...100) {
                            Text("\(reps)")
                                .font(.title2.monospacedDigit())
                                .foregroundColor(.textPrimary)
                        }
                        .padding(Spacing.s.rawValue)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("实际次数 Actual reps")
                        .accessibilityValue("\(reps)")
                    }
                }

                if setLog.completedAt == nil {
                    Button {
                        workoutStore.complete(
                            setLog,
                            actualReps: reps,
                            weightKg: parsedWeight
                        )
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    } label: {
                        Label("完成本组 Complete Set", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.s.rawValue)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.accentColor)
                    .accessibilityIdentifier("workout.completeSet")
                } else {
                    HStack {
                        Button("保存修改 Save Changes") {
                            workoutStore.update(
                                setLog,
                                actualReps: reps,
                                weightKg: parsedWeight
                            )
                        }
                        .buttonStyle(.bordered)

                        Button("撤销 Undo", role: .destructive) {
                            workoutStore.undo(setLog)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("workout.undoSet")
                    }
                }
            }
        }
    }

    private var parsedWeight: Double? {
        let normalized = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else { return nil }
        return value
    }
}

private struct RestTimerOverlay: View {
    @Bindable var session: WorkoutSession
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            let remaining = workoutStore.remainingRestSeconds(
                in: session,
                now: timeline.date
            )

            GlassCard(padding: Spacing.s.rawValue) {
                VStack(spacing: Spacing.s.rawValue) {
                    HStack(spacing: Spacing.m.rawValue) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 5)
                            Text(Self.format(seconds: remaining))
                                .font(
                                    .system(
                                        size: 20,
                                        weight: .semibold,
                                        design: .monospaced
                                    )
                                )
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .allowsTightening(true)
                        }
                        .frame(width: 64, height: 64)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("剩余休息时间 Rest time remaining")
                        .accessibilityValue(Self.format(seconds: remaining))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(
                                session.restPausedRemaining == nil
                                    ? "休息中 · RESTING"
                                    : "已暂停 · PAUSED"
                            )
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                            Text(nextSetDescription)
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("workout.rest.next")
                        }
                        Spacer(minLength: 0)
                    }

                    HStack(spacing: Spacing.m.rawValue) {
                        Spacer()
                        Button("+15s") {
                            workoutStore.extendRest(by: 15, in: session, now: timeline.date)
                        }
                        .font(.caption.monospacedDigit())
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel("延长十五秒 Add fifteen seconds")
                        .accessibilityIdentifier("workout.rest.extend")

                        Button {
                            if session.restPausedRemaining == nil {
                                workoutStore.pauseRest(in: session, now: timeline.date)
                            } else {
                                workoutStore.resumeRest(in: session, now: timeline.date)
                            }
                        } label: {
                            Image(
                                systemName: session.restPausedRemaining == nil
                                    ? "pause.fill"
                                    : "play.fill"
                            )
                            .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(
                            session.restPausedRemaining == nil
                                ? "暂停 Pause"
                                : "继续 Resume"
                        )
                        .accessibilityIdentifier("workout.rest.pauseResume")

                        Button {
                            workoutStore.skipRest(in: session)
                        } label: {
                            Image(systemName: "forward.end.fill")
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("跳过休息 Skip rest")
                        .accessibilityIdentifier("workout.rest.skip")
                        Spacer()
                    }
                }
                .foregroundColor(Color.accentColor)
            }
            .onChange(of: remaining) { oldValue, newValue in
                if oldValue > 0 && newValue == 0 {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    if workoutStore.restTimerSoundEnabled {
                        AudioServicesPlaySystemSound(1057)
                    }
                    workoutStore.reconcileRestTimer(in: session, now: timeline.date)
                }
            }
        }
    }

    private var nextSetDescription: String {
        guard let exercise = workoutStore.currentExercise(in: session),
              !exercise.isSkipped,
              let set = workoutStore.currentSet(in: exercise),
              set.completedAt == nil else {
            return "下一组：等待选择 · NEXT: SELECT A SET"
        }
        return "下一组：\(exercise.exerciseNameZHSnapshot) 第 \(set.order + 1) 组，"
            + "\(set.targetReps) 次 · NEXT: \(exercise.exerciseNameENSnapshot), "
            + "SET \(set.order + 1), \(set.targetReps) REPS"
    }

    private static func format(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

private struct WorkoutExercisePicker: View {
    @Bindable var session: WorkoutSession

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var exerciseStore: ExerciseStore
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore
    @State private var query = ""

    private var results: [Exercise] {
        let all = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? exerciseStore.exercises
            : exerciseStore.search(query: query)
        return Array(all.prefix(100))
    }

    var body: some View {
        NavigationStack {
            List(results) { exercise in
                Button {
                    workoutStore.addExercise(exercise, to: session)
                    dismiss()
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.nameZH)
                                .foregroundColor(.primary)
                            Text(exercise.name.uppercased())
                                .font(.caption2.smallCaps())
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle")
                            .foregroundColor(Color.accentColor)
                    }
                }
                .disabled(session.exercises.contains { $0.exerciseId == exercise.id })
                .accessibilityIdentifier("workout.exercise.add.\(exercise.id)")
            }
            .searchable(text: $query, prompt: "搜索动作 Search exercises")
            .navigationTitle("添加动作 Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消 Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
