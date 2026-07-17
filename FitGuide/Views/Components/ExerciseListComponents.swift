import SwiftUI

struct BodyPartHeader: View {
    let bodyPart: String
    let count: Int

    private var zhName: String { ZH.bodyPart[bodyPart.lowercased()] ?? bodyPart }

    var body: some View {
        GlassCard(padding: Spacing.s.rawValue) {
            HStack(alignment: .firstTextBaseline) {
                Text(zhName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(bodyPart.capitalized)
                    .font(.subheadline.smallCaps())
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct BodyPartSectionGrid: View {
    let exercises: [Exercise]

    var body: some View {
        LazyVGrid(columns: GridColumns.adaptive, spacing: Spacing.m.rawValue) {
            ForEach(exercises) { ex in
                ExerciseCardView(exercise: ex)
            }
        }
    }
}

struct SearchResultsList: View {
    let exercises: [Exercise]

    var body: some View {
        if exercises.isEmpty {
            VStack(spacing: Spacing.s.rawValue) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.textSecondary)
                Text("未找到结果")
                    .font(.headline)
                    .foregroundColor(.textPrimary)
                Text("No results")
                    .font(.subheadline.smallCaps())
                    .foregroundColor(.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 80)
        } else {
            LazyVGrid(columns: GridColumns.adaptive, spacing: Spacing.m.rawValue) {
                ForEach(exercises) { ex in
                    ExerciseCardView(exercise: ex)
                }
            }
        }
    }
}