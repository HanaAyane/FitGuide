import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore
    @State private var sessionToDelete: WorkoutSession?
    @State private var sessions: [WorkoutSession] = []
    @State private var reachedEnd = false
    private let pageSize = 30

    var body: some View {
        ZStack {
            SpaceBackground()
            if sessions.isEmpty {
                ContentUnavailableView {
                    Label("还没有训练历史", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Completed workouts will appear here.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.m.rawValue) {
                        ForEach(sessions) { session in
                            NavigationLink {
                                WorkoutSummaryView(session: session, isHistory: true)
                            } label: {
                                WorkoutHistoryRow(session: session)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    sessionToDelete = session
                                } label: {
                                    Label("删除 Delete", systemImage: "trash")
                                }
                            }
                            .onAppear {
                                if session.id == sessions.last?.id {
                                    loadNextPage()
                                }
                            }
                        }

                        if !reachedEnd {
                            ProgressView()
                                .tint(Color.accentColor)
                                .padding()
                        }
                    }
                    .padding(Spacing.m.rawValue)
                }
                .refreshable {
                    reload()
                }
            }
        }
        .navigationTitle("训练历史 History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if sessions.isEmpty {
                reload()
            }
        }
        .confirmationDialog(
            "删除这条训练记录？Delete this workout?",
            isPresented: Binding(
                get: { sessionToDelete != nil },
                set: { if !$0 { sessionToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除 Delete", role: .destructive) {
                if let sessionToDelete {
                    if workoutStore.deleteHistory(sessionToDelete) {
                        sessions.removeAll { $0.id == sessionToDelete.id }
                    }
                }
                sessionToDelete = nil
            }
            Button("取消 Cancel", role: .cancel) {
                sessionToDelete = nil
            }
        }
        .alert(
            "无法读取训练历史 · Unable to load history",
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

    private func reload() {
        sessions = []
        reachedEnd = false
        loadNextPage()
    }

    private func loadNextPage() {
        guard !reachedEnd else { return }
        let page = workoutStore.completedSessions(
            limit: pageSize,
            offset: sessions.count
        )
        let existingIDs = Set(sessions.map(\.id))
        sessions.append(contentsOf: page.filter { !existingIDs.contains($0.id) })
        reachedEnd = page.count < pageSize
    }
}

struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        let metrics = WorkoutMetrics.calculate(for: session)
        GlassCard {
            HStack(spacing: Spacing.m.rawValue) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(Color.accentColor.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text(session.displayName)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(
                        "\(metrics.completedExercises) 动作 Exercises · "
                            + "\(metrics.completedSets) 组 Sets · "
                            + WorkoutFormatting.duration(metrics.duration)
                    )
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct WorkoutSummaryView: View {
    @Bindable var session: WorkoutSession
    let isHistory: Bool
    var onDone: (() -> Void)?

    @EnvironmentObject private var exerciseStore: ExerciseStore

    init(
        session: WorkoutSession,
        isHistory: Bool,
        onDone: (() -> Void)? = nil
    ) {
        self.session = session
        self.isHistory = isHistory
        self.onDone = onDone
    }

    var body: some View {
        let metrics = WorkoutMetrics.calculate(for: session)
        ZStack {
            SpaceBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                    header(metrics)
                    metricGrid(metrics)

                    Text("动作明细 Exercise Details")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .padding(.top, Spacing.s.rawValue)

                    ForEach(session.sortedExercises) { exercise in
                        exerciseCard(exercise)
                    }

                    if let onDone {
                        Button {
                            onDone()
                        } label: {
                            Text("完成 Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.s.rawValue)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.accentColor)
                        .padding(.top, Spacing.m.rawValue)
                        .accessibilityIdentifier("workout.summary.done")
                    }
                }
                .padding(Spacing.m.rawValue)
            }
        }
        .navigationTitle(isHistory ? "训练详情 Details" : "训练完成 Complete")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ metrics: WorkoutMetrics) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 42))
                    .foregroundColor(Color.accentColor)
                Text(session.displayName)
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)
                Text(session.startedAt.formatted(date: .complete, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Text("本次训练已保存 · WORKOUT SAVED LOCALLY")
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
                    .accessibilityIdentifier("workout.summary.saved")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metricGrid(_ metrics: WorkoutMetrics) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: Spacing.s.rawValue),
                GridItem(.flexible(), spacing: Spacing.s.rawValue)
            ],
            spacing: Spacing.s.rawValue
        ) {
            metricCard("时长", "Duration", WorkoutFormatting.duration(metrics.duration))
            metricCard("动作", "Exercises", "\(metrics.completedExercises)")
            metricCard("完成组", "Sets", "\(metrics.completedSets)/\(metrics.plannedSets)")
            metricCard("总次数", "Reps", "\(metrics.totalReps)")
            if metrics.totalVolume > 0 {
                metricCard("训练量", "Volume", WorkoutFormatting.volume(metrics.totalVolume))
            }
        }
    }

    private func metricCard(_ zh: String, _ en: String, _ value: String) -> some View {
        GlassCard(padding: Spacing.s.rawValue) {
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundColor(Color.accentColor)
                Text(zh)
                    .font(.caption)
                    .foregroundColor(.textPrimary)
                Text(en.uppercased())
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func exerciseCard(_ exercise: WorkoutExercise) -> some View {
        GlassCard(padding: Spacing.s.rawValue) {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.exerciseNameZHSnapshot)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text(exercise.exerciseNameENSnapshot.uppercased())
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    if exercise.isSkipped {
                        Label("跳过 Skipped", systemImage: "forward.fill")
                            .font(.caption2)
                            .foregroundColor(.textSecondary)
                    }
                }

                ForEach(exercise.sortedSets) { setLog in
                    HStack {
                        Text("第 \(setLog.order + 1) 组 · Set \(setLog.order + 1)")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        if setLog.completedAt != nil {
                            Text(setDescription(setLog))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.textPrimary)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Color.accentColor)
                        } else {
                            Text("未完成 Incomplete")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }

                if isHistory,
                   let currentExercise = exerciseStore.exercises.first(
                       where: { $0.id == exercise.exerciseId }
                   ) {
                    NavigationLink {
                        ExerciseDetailView(exercise: currentExercise)
                    } label: {
                        Label(
                            "查看动作参考 View exercise guide",
                            systemImage: "figure.strengthtraining.traditional"
                        )
                        .font(.caption)
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 44,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .foregroundColor(Color.accentColor)
                }
            }
        }
    }

    private func setDescription(_ setLog: SetLog) -> String {
        if let weight = setLog.weightKg {
            return "\(String(format: "%g", weight)) kg × \(setLog.actualReps)"
        }
        return "\(setLog.actualReps) reps"
    }
}

enum WorkoutFormatting {
    static func duration(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    static func volume(_ volume: Double) -> String {
        if volume >= 1_000 {
            return String(format: "%.1fk kg·reps", volume / 1_000)
        }
        return String(format: "%g kg·reps", volume)
    }
}
