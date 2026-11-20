import SwiftUI

struct PlansView: View {
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var exerciseStore: ExerciseStore
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore

    @State private var showCreatePlan = false
    @State private var newPlanName = ""
    @State private var presentedSession: WorkoutSession?

    private var recentSessions: [WorkoutSession] {
        workoutStore.completedSessions(limit: 3)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                        if workoutStore.activeSession != nil {
                            activeWorkoutCard
                        } else {
                            quickStartCard
                        }
                        plansSection

                        if !recentSessions.isEmpty {
                            recentSection
                        }
                    }
                    .padding(Spacing.m.rawValue)
                }
            }
            .navigationTitle("训练 Training")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreatePlan = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新建训练计划 New training plan")
                }
            }
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
            .fullScreenCover(item: $presentedSession) { session in
                WorkoutSessionView(session: session)
            }
            .alert("新建计划 New Plan", isPresented: $showCreatePlan) {
                TextField("计划名称 Plan name", text: $newPlanName)
                Button("取消 Cancel", role: .cancel) {
                    newPlanName = ""
                }
                Button("创建 Create") {
                    let name = newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !name.isEmpty {
                        _ = library.addPlan(named: name)
                        newPlanName = ""
                    }
                }
            }
            .alert(
                "无法完成操作 · Operation failed",
                isPresented: Binding(
                    get: { library.lastErrorMessage != nil || workoutStore.lastErrorMessage != nil },
                    set: { presented in
                        if !presented {
                            library.clearError()
                            workoutStore.clearError()
                        }
                    }
                )
            ) {
                Button("好 OK", role: .cancel) {
                    library.clearError()
                    workoutStore.clearError()
                }
            } message: {
                Text(
                    workoutStore.lastErrorMessage
                        ?? library.lastErrorMessage
                        ?? "未知错误 Unknown error"
                )
            }
        }
    }

    private var activeWorkoutCard: some View {
        Button {
            presentedSession = workoutStore.activeSession
        } label: {
            GlassCard {
                HStack(spacing: Spacing.m.rawValue) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color.accentColor)
                    VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                        Text("继续训练")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text(workoutStore.activeSession?.displayName ?? "CONTINUE WORKOUT")
                            .font(.caption.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("打开正在进行的训练 Open active workout")
        .accessibilityIdentifier("training.continueWorkout")
    }

    private var quickStartCard: some View {
        Button {
            if let session = workoutStore.startQuickWorkout() {
                presentedSession = session
            }
        } label: {
            GlassCard {
                HStack(spacing: Spacing.m.rawValue) {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("快速开始")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("QUICK START")
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "play.fill")
                        .foregroundColor(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("快速开始 Quick Start")
        .accessibilityIdentifier("training.quickStart")
    }

    @ViewBuilder
    private var plansSection: some View {
        sectionHeader(zh: "训练计划", en: "Plans")

        if library.trainingPlans.isEmpty {
            GlassCard {
                VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                    Text("还没有训练计划")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("Create a reusable plan or start a free workout.")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Button("新建计划 New Plan") {
                        showCreatePlan = true
                    }
                    .foregroundColor(Color.accentColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            ForEach(library.trainingPlans) { plan in
                PlanCard(
                    plan: plan,
                    canStart: exerciseStore.isReady,
                    start: {
                        start(plan)
                    }
                )
            }
        }
    }

    private var recentSection: some View {
        Group {
            HStack {
                sectionHeader(zh: "最近训练", en: "Recent")
                Spacer()
                NavigationLink {
                    WorkoutHistoryView()
                } label: {
                    Text("全部 All")
                        .font(.caption)
                        .foregroundColor(Color.accentColor)
                }
                .accessibilityIdentifier("training.history.all")
            }

            ForEach(recentSessions) { session in
                NavigationLink {
                    WorkoutSummaryView(session: session, isHistory: true)
                } label: {
                    WorkoutHistoryRow(session: session)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("training.recent.row")
            }
        }
    }

    private func sectionHeader(zh: String, en: String) -> some View {
        HStack(spacing: Spacing.s.rawValue) {
            Text(zh)
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(en.uppercased())
                .font(.caption2.smallCaps())
                .foregroundColor(.textSecondary)
        }
        .padding(.top, Spacing.s.rawValue)
    }

    private func start(_ plan: TrainingPlan) {
        // A plan start is never allowed to create a second active session. This
        // also lets a tap on a plan's play button recover cleanly after the app
        // has restored an in-progress workout from disk.
        if let active = workoutStore.activeSession {
            presentedSession = active
            return
        }
        guard exerciseStore.isReady else { return }

        let byId = Dictionary(
            uniqueKeysWithValues: exerciseStore.exercises.map { ($0.id, $0) }
        )
        if let session = workoutStore.start(plan: plan, exercisesById: byId) {
            presentedSession = session
        }
    }
}

private struct PlanCard: View {
    let plan: TrainingPlan
    let canStart: Bool
    let start: () -> Void

    var body: some View {
        GlassCard {
            HStack(spacing: Spacing.m.rawValue) {
                NavigationLink {
                    PlanEditorView(plan: plan)
                } label: {
                    VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                        Text(plan.name)
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("\(plan.items.count) 个动作 · \(plan.items.count) ITEMS")
                            .font(.caption.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button(action: start) {
                    Image(systemName: canStart ? "play.fill" : "hourglass")
                        .font(.headline)
                        .foregroundColor(Color.accentColor)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor.opacity(0.12), in: Circle())
                }
                .disabled(plan.items.isEmpty || !canStart)
                .opacity(plan.items.isEmpty || !canStart ? 0.35 : 1)
                .accessibilityLabel(
                    canStart
                        ? "开始 \(plan.name) Start plan"
                        : "动作库加载中 Loading exercise catalog"
                )
                .accessibilityIdentifier("training.planStart")
            }
        }
    }
}

struct PlanEditorView: View {
    @Bindable var plan: TrainingPlan
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var library: LibraryStore
    @EnvironmentObject private var exerciseStore: ExerciseStore
    @EnvironmentObject private var workoutStore: ActiveWorkoutStore

    @State private var renaming = false
    @State private var renameText = ""
    @State private var presentedSession: WorkoutSession?
    @State private var confirmDeletePlan = false

    private var sortedItems: [TrainingPlanItem] {
        plan.items.sorted { $0.order < $1.order }
    }

    var body: some View {
        ZStack {
            SpaceBackground()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(plan.name)
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(.textPrimary)
                                    Text("\(plan.items.count) ITEMS · REUSABLE TEMPLATE")
                                        .font(.caption2.smallCaps())
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                                Button {
                                    renameText = plan.name
                                    renaming = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .frame(width: 44, height: 44)
                                }
                                .accessibilityLabel("重命名计划 Rename plan")
                            }

                            Button {
                                start(plan)
                            } label: {
                                Label(
                                    exerciseStore.isReady
                                        ? "开始训练 Start Workout"
                                        : "加载动作库中 Loading Catalog",
                                    systemImage: exerciseStore.isReady ? "play.fill" : "hourglass"
                                )
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.s.rawValue)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.accentColor)
                            .disabled(plan.items.isEmpty || !exerciseStore.isReady)
                        }
                    }

                    if sortedItems.isEmpty {
                        GlassCard {
                            Text("从动作详情页加入动作\nAdd exercises from exercise details")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                            PlanTemplateItemCard(
                                item: item,
                                exercise: exerciseStore.exercises.first { $0.id == item.exerciseId },
                                canMoveUp: index > 0,
                                canMoveDown: index < sortedItems.count - 1
                            )
                        }
                    }

                    Button(role: .destructive) {
                        confirmDeletePlan = true
                    } label: {
                        Label("删除计划 Delete Plan", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, Spacing.m.rawValue)
                }
                .padding(Spacing.m.rawValue)
            }
        }
        .navigationTitle("计划模板 Plan")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $presentedSession) { session in
            WorkoutSessionView(session: session)
        }
        .alert("重命名计划 Rename Plan", isPresented: $renaming) {
            TextField("名称 Name", text: $renameText)
            Button("取消 Cancel", role: .cancel) {}
            Button("保存 Save") {
                let name = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    library.renamePlan(plan, to: name)
                }
            }
        }
        .confirmationDialog(
            "确认删除这个计划？Delete this plan?",
            isPresented: $confirmDeletePlan,
            titleVisibility: .visible
        ) {
            Button("删除 Delete", role: .destructive) {
                library.deletePlan(plan)
                dismiss()
            }
            Button("取消 Cancel", role: .cancel) {}
        }
        .alert(
            "无法完成操作 · Operation failed",
            isPresented: Binding(
                get: {
                    workoutStore.lastErrorMessage != nil
                        || library.lastErrorMessage != nil
                },
                set: {
                    if !$0 {
                        workoutStore.clearError()
                        library.clearError()
                    }
                }
            )
        ) {
            Button("好 OK", role: .cancel) {
                workoutStore.clearError()
                library.clearError()
            }
        } message: {
            Text(
                workoutStore.lastErrorMessage
                    ?? library.lastErrorMessage
                    ?? "未知错误 Unknown error"
            )
        }
    }

    private func start(_ plan: TrainingPlan) {
        if let active = workoutStore.activeSession {
            presentedSession = active
            return
        }
        guard exerciseStore.isReady else { return }

        let byId = Dictionary(
            uniqueKeysWithValues: exerciseStore.exercises.map { ($0.id, $0) }
        )
        if let session = workoutStore.start(plan: plan, exercisesById: byId) {
            presentedSession = session
        }
    }
}

private struct PlanTemplateItemCard: View {
    @Bindable var item: TrainingPlanItem
    let exercise: Exercise?
    let canMoveUp: Bool
    let canMoveDown: Bool

    @EnvironmentObject private var library: LibraryStore
    @State private var confirmDelete = false

    var body: some View {
        GlassCard(padding: Spacing.s.rawValue) {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise?.nameZH ?? "动作不可用")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text((exercise?.name ?? "EXERCISE UNAVAILABLE").uppercased())
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Button {
                        library.moveItem(item, by: -1)
                    } label: {
                        Image(systemName: "arrow.up")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(!canMoveUp)
                    Button {
                        library.moveItem(item, by: 1)
                    } label: {
                        Image(systemName: "arrow.down")
                            .frame(width: 36, height: 36)
                    }
                    .disabled(!canMoveDown)
                    Button(role: .destructive) {
                        confirmDelete = true
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("删除动作 Delete exercise")
                }

                Stepper(
                    "组数 Sets：\(item.sets)",
                    value: Binding(
                        get: { item.sets },
                        set: { library.updateItem(item, sets: $0, reps: item.reps) }
                    ),
                    in: 1...10
                )
                Stepper(
                    "次数 Reps：\(item.reps)",
                    value: Binding(
                        get: { item.reps },
                        set: { library.updateItem(item, sets: item.sets, reps: $0) }
                    ),
                    in: 1...50
                )
                Stepper(
                    "休息 Rest：\(item.restSeconds) 秒",
                    value: Binding(
                        get: { item.restSeconds },
                        set: { library.updateItem(item, sets: item.sets, reps: item.reps, restSeconds: $0) }
                    ),
                    in: 0...300,
                    step: 15
                )
            }
            .foregroundColor(.textPrimary)
        }
        .confirmationDialog(
            "从计划中删除这个动作？Remove this exercise from the plan?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("删除 Delete", role: .destructive) {
                library.deleteItem(item)
            }
            Button("取消 Cancel", role: .cancel) {}
        }
    }
}
