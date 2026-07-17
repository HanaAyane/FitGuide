import SwiftUI

struct ExercisesTabView: View {
    @EnvironmentObject var store: ExerciseStore
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var bodyParts: Set<String> = []
    @State private var equipments: Set<String> = []
    @State private var targets: Set<String> = []

    private var hasFilters: Bool {
        !bodyParts.isEmpty || !equipments.isEmpty || !targets.isEmpty
    }

    private var filteredExercises: [Exercise] {
        store.filtered(bodyParts: bodyParts, equipments: equipments, targets: targets)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                ScrollView {
                    VStack(spacing: Spacing.l.rawValue) {
                        if !searchText.isEmpty {
                            SearchResultsList(exercises: store.search(query: searchText))
                        } else if hasFilters {
                            filterSummary
                            if filteredExercises.isEmpty {
                                emptyFilter
                            } else {
                                BodyPartSectionGrid(exercises: filteredExercises)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                                ForEach(store.bodyParts, id: \.self) { part in
                                    if let group = store.byBodyPart[part] {
                                        VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                                            BodyPartHeader(bodyPart: part, count: group.count)
                                            BodyPartSectionGrid(exercises: group)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.m.rawValue)
                    .padding(.top, Spacing.m.rawValue)
                }
            }
            .navigationTitle("FitGuide")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("搜索动作 / 肌群 / 器械  Search"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters.toggle()
                    } label: {
                        Image(systemName: hasFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasFilters ? Color.accentColor : .textPrimary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(
                    bodyParts: $bodyParts,
                    equipments: $equipments,
                    targets: $targets,
                    onClear: {
                        bodyParts.removeAll()
                        equipments.removeAll()
                        targets.removeAll()
                    }
                )
            }
            .navigationDestination(for: Exercise.self) { ex in
                ExerciseDetailView(exercise: ex)
            }
        }
    }

    private var filterSummary: some View {
        GlassCard(padding: Spacing.s.rawValue) {
            HStack(spacing: Spacing.s.rawValue) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .foregroundColor(Color.accentColor)
                Text("\(filteredExercises.count) 个结果 · Results")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Button {
                    bodyParts.removeAll()
                    equipments.removeAll()
                    targets.removeAll()
                } label: {
                    Text("清除全部")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }

    private var emptyFilter: some View {
        VStack(spacing: Spacing.s.rawValue) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.textSecondary)
            Text("没有符合的动作")
                .font(.headline)
                .foregroundColor(.textPrimary)
            Text("No matching exercises")
                .font(.subheadline.smallCaps())
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

private struct FilterSheet: View {
    @Binding var bodyParts: Set<String>
    @Binding var equipments: Set<String>
    @Binding var targets: Set<String>
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ExerciseStore

    private var bodyPartChips: [ChipItem] {
        store.distinctValues(for: \.bodyPart).map {
            ChipItem(
                value: $0,
                zhLabel: ZH.bodyPart[$0.lowercased()] ?? $0,
                enLabel: $0.capitalized
            )
        }
    }

    private var equipmentChips: [ChipItem] {
        store.distinctValues(for: \.equipment).map {
            ChipItem(
                value: $0,
                zhLabel: ZH.equipment[$0.lowercased()] ?? $0,
                enLabel: $0.capitalized
            )
        }
    }

    private var targetChips: [ChipItem] {
        store.distinctValues(for: \.target).map {
            ChipItem(
                value: $0,
                zhLabel: ZH.target[$0.lowercased()] ?? $0,
                enLabel: $0.capitalized
            )
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                        FilterChipGroup(title: "部位", subtitle: "Body Part", items: bodyPartChips, selection: $bodyParts)
                        FilterChipGroup(title: "器械", subtitle: "Equipment", items: equipmentChips, selection: $equipments)
                        FilterChipGroup(title: "目标肌群", subtitle: "Target", items: targetChips, selection: $targets)
                    }
                    .padding(Spacing.m.rawValue)
                }
            }
            .navigationTitle("筛选 Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("按多维度组合搜索")
                        .font(.caption.smallCaps())
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("应用", action: { dismiss() })
                        .foregroundColor(Color.accentColor)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button(role: .destructive) {
                        onClear()
                        dismiss()
                    } label: {
                        Label("清除筛选", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Label("查看结果", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
        }
    }
}