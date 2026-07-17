import SwiftUI
import SwiftData

struct FavoritesTabView: View {
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                        recentSection
                        if let df = library.defaultFavorites {
                            favoritesSection(list: df, isDefault: true)
                        }
                        ForEach(library.customLists) { list in
                            favoritesSection(list: list, isDefault: false)
                        }
                        Spacer(minLength: Spacing.xl.rawValue)
                    }
                    .padding(.horizontal, Spacing.m.rawValue)
                    .padding(.top, Spacing.m.rawValue)
                }
            }
            .navigationTitle("收藏")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Exercise.self) { ex in
                ExerciseDetailView(exercise: ex)
            }
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        let recentItems = library.recentViews.prefix(20).compactMap { rv -> Exercise? in
            store.exercises.first { $0.id == rv.exerciseId }
        }
        if !recentItems.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                HStack {
                    Text("最近看过")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("Recent".uppercased())
                        .font(.caption2.smallCaps())
                        .foregroundColor(.textSecondary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.m.rawValue) {
                        ForEach(Array(recentItems)) { ex in
                            NavigationLink(value: ex) {
                                RecentChip(exercise: ex)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func favoritesSection(list: FavoriteList, isDefault: Bool) -> some View {
        let items = list.items.compactMap { item -> Exercise? in
            store.exercises.first { $0.id == item.exerciseId }
        }
        VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
            HStack {
                Text(isDefault ? "我的收藏" : list.name)
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("\(items.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.textSecondary)
            }
            if items.isEmpty {
                GlassCard(padding: Spacing.l.rawValue) {
                    Text(isDefault ? "点开动作右上角书签加入收藏" : "空列表 · Empty")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                LazyVGrid(columns: GridColumns.adaptive, spacing: Spacing.m.rawValue) {
                    ForEach(items) { ex in
                        ExerciseCardView(exercise: ex)
                    }
                }
            }
        }
    }
}

private struct RecentChip: View {
    let exercise: Exercise

    var body: some View {
        VStack(spacing: Spacing.xs.rawValue) {
            if let url = ExerciseStore.imageURL(for: exercise),
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 70, height: 70)
            }
            Text(exercise.nameZH)
                .font(.caption2.weight(.semibold))
                .foregroundColor(.textPrimary)
                .lineLimit(1)
                .frame(width: 100)
        }
        .padding(Spacing.s.rawValue)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: Radii.card.rawValue)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: Radii.card.rawValue)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
        )
    }
}