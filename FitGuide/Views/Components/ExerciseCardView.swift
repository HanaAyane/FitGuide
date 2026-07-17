import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise

    var body: some View {
        NavigationLink(value: exercise) {
            GlassCard(padding: Spacing.s.rawValue) {
                VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                    ThumbnailView(exercise: exercise)

                    Text(exercise.nameZH)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(exercise.name.capitalized)
                        .font(.caption2.smallCaps())
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)

                    HStack(spacing: Spacing.xs.rawValue) {
                        Image(systemName: "target")
                            .font(.system(size: 9))
                        Text(exercise.targetZH)
                            .font(.caption2)
                        Text("·")
                            .font(.caption2)
                        Text(exercise.equipmentZH)
                            .font(.caption2)
                    }
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(exercise.nameZH)，\(exercise.name)，目标肌群 \(exercise.targetZH)，器械 \(exercise.equipmentZH)"))
        .accessibilityHint(Text("查看动作详情"))
    }
}

struct ThumbnailView: View {
    let exercise: Exercise
    var height: CGFloat = 110

    var body: some View {
        Group {
            if let url = ExerciseStore.imageURL(for: exercise),
               let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.textSecondary)
                    )
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}