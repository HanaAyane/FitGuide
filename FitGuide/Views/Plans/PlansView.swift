import SwiftUI

struct PlansView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore
    @State private var showCreate = false
    @State private var newName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                if library.trainingPlans.isEmpty {
                    VStack(spacing: Spacing.s.rawValue) {
                        Spacer()
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(.textSecondary)
                        Text("还没有训练计划")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        Text("No plans yet")
                            .font(.subheadline.smallCaps())
                            .foregroundColor(.textSecondary)
                        Button {
                            showCreate.toggle()
                        } label: {
                            Label("新建计划 New Plan", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(Color.accentColor)
                        }
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                            ForEach(library.trainingPlans) { plan in
                                NavigationLink {
                                    PlanEditorView(plan: plan)
                                } label: {
                                    PlanCard(plan: plan)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            Button {
                                showCreate.toggle()
                            } label: {
                                Label("新建计划 New Plan", systemImage: "plus.circle")
                                    .font(.subheadline)
                                    .foregroundColor(Color.accentColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(Spacing.m.rawValue)
                                    .background(
                                        ZStack {
                                            RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                                .fill(.ultraThinMaterial)
                                            RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                                        }
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, Spacing.m.rawValue)
                        .padding(.top, Spacing.m.rawValue)
                    }
                }
            }
            .navigationTitle("训练计划")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Exercise.self) { ex in
                ExerciseDetailView(exercise: ex)
            }
            .alert("新建计划 New Plan", isPresented: $showCreate) {
                TextField("计划名称 Plan name", text: $newName)
                Button("取消", role: .cancel) { newName = "" }
                Button("创建", action: {
                    let name = newName.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        _ = library.addPlan(named: name)
                        newName = ""
                    }
                })
            }
        }
    }
}

private struct PlanCard: View {
    let plan: TrainingPlan

    var body: some View {
        GlassCard {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Text("\(plan.items.count) 个动作 · Items")
                        .font(.caption.smallCaps())
                        .foregroundColor(.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct PlanEditorView: View {
    @Bindable var plan: TrainingPlan
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore
    @State private var renaming = false
    @State private var renameText = ""

    private var pendingItems: [TrainingPlanItem] {
        plan.items.filter { !$0.isCompleted }.sorted { $0.order < $1.order }
    }

    private var completedItems: [TrainingPlanItem] {
        plan.items.filter { $0.isCompleted }.sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var body: some View {
        ZStack {
            SpaceBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                    HStack {
                        Text(plan.name)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        if !completedItems.isEmpty {
                            Button {
                                library.uncompleteAllItems(in: plan)
                            } label: {
                                Label("重置 Reset", systemImage: "arrow.counterclockwise")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        Button {
                            renameText = plan.name
                            renaming.toggle()
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .padding(.horizontal, Spacing.s.rawValue)

                    let total = plan.items.count
                    let done = completedItems.count
                    if total > 0 {
                        GlassCard(padding: Spacing.s.rawValue) {
                            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                                HStack {
                                    Text("进度 Progress")
                                        .font(.caption.smallCaps())
                                        .foregroundColor(.textSecondary)
                                    Spacer()
                                    Text("\(done)/\(total)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundColor(Color.accentColor)
                                }
                                ProgressView(value: Double(done), total: Double(total))
                                    .tint(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, Spacing.s.rawValue)
                    }

                    if plan.items.isEmpty {
                        GlassCard(padding: Spacing.l.rawValue) {
                            Text("从动作详情页右上角菜单”加入计划”添加\nAdd from exercise details")
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        if !pendingItems.isEmpty {
                            sectionHeader(zh: "待完成", en: "Pending", count: pendingItems.count)
                            ForEach(pendingItems) { item in
                                planItemRow(item)
                            }
                        }
                        if !completedItems.isEmpty {
                            sectionHeader(zh: "已完成", en: "Completed", count: completedItems.count)
                            ForEach(completedItems) { item in
                                planItemRow(item)
                            }
                        }
                    }
                }
                .padding(Spacing.m.rawValue)
            }
        }
        .navigationTitle("计划编辑")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Exercise.self) { ex in
            ExerciseDetailView(exercise: ex)
        }
        .alert("重命名计划 Rename Plan", isPresented: $renaming) {
            TextField("名称", text: $renameText)
            Button("取消", role: .cancel) { }
            Button("保存", action: {
                let n = renameText.trimmingCharacters(in: .whitespaces)
                if !n.isEmpty { library.renamePlan(plan, to: n) }
            })
        }
    }

    private func sectionHeader(zh: String, en: String, count: Int) -> some View {
        HStack {
            Text(zh)
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text(en.uppercased())
                .font(.caption2.smallCaps())
                .foregroundColor(.textSecondary)
            Spacer()
            Text("\(count)")
                .font(.subheadline.monospacedDigit())
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal, Spacing.s.rawValue)
        .padding(.top, Spacing.s.rawValue)
    }

    @ViewBuilder
    private func planItemRow(_ item: TrainingPlanItem) -> some View {
        if let ex = store.exercises.first(where: { $0.id == item.exerciseId }) {
            GlassCard(padding: Spacing.s.rawValue) {
                VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                    HStack {
                        NavigationLink {
                            ExerciseDetailView(exercise: ex)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.nameZH)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(item.isCompleted ? .textSecondary : .textPrimary)
                                    .strikethrough(item.isCompleted, color: .textSecondary)
                                Text(ex.name.capitalized)
                                    .font(.caption2.smallCaps())
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                        Spacer()
                        Button(role: .destructive) {
                            library.deleteItem(item)
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }

                    if item.isCompleted {
                        Text("\(item.sets)/\(item.sets) · \(item.reps) 次/组")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(Color.accentColor)
                    } else {
                        HStack(spacing: Spacing.xs.rawValue) {
                            ForEach(0..<item.sets, id: \.self) { i in
                                let done = i < item.setStates.count && item.setStates[i]
                                Button {
                                    library.toggleSet(item, at: i)
                                } label: {
                                    Image(systemName: done ? "circle.fill" : "circle")
                                        .font(.system(size: 20, weight: .regular))
                                        .foregroundColor(done ? Color.accentColor : .textSecondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        VStack(spacing: Spacing.xs.rawValue) {
                            HStack {
                                Text("进度 \(item.completedCount)/\(item.sets) · 次数 \(item.reps)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(.textSecondary)
                                Spacer()
                            }
                            HStack(spacing: Spacing.l.rawValue) {
                                Stepper(value: Binding(get: { item.sets }, set: { library.updateItem(item, sets: $0, reps: item.reps) }), in: 1...10) {
                                    HStack(spacing: Spacing.xs.rawValue) {
                                        Text("组数")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.textSecondary)
                                        Text("\(item.sets)")
                                            .font(.subheadline.monospacedDigit().weight(.semibold))
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                                Stepper(value: Binding(get: { item.reps }, set: { library.updateItem(item, sets: item.sets, reps: $0) }), in: 1...50) {
                                    HStack(spacing: Spacing.xs.rawValue) {
                                        Text("次数")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.textSecondary)
                                        Text("\(item.reps)")
                                            .font(.subheadline.monospacedDigit().weight(.semibold))
                                            .foregroundColor(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}