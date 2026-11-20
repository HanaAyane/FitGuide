import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    @EnvironmentObject var library: LibraryStore
    @EnvironmentObject var store: ExerciseStore
    @State private var showShareSheet = false
    @State private var showPlanPicker = false
    @State private var copied = false

    var body: some View {
        ZStack {
            SpaceBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.l.rawValue) {
                    titleBlock
                    gifBlock
                    metadataBlock
                    stepsBlock
                    AttributionFooter()
                }
                .padding(.horizontal, Spacing.m.rawValue)
                .padding(.vertical, Spacing.m.rawValue)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(exercise.nameZH)
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    Text(exercise.name.capitalized)
                        .font(.caption2.smallCaps())
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: Spacing.s.rawValue) {
                    Button {
                        showShareSheet.toggle()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.textPrimary)
                    }
                    Button {
                        showPlanPicker.toggle()
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            library.recordRecent(exerciseId: exercise.id)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(exercise: exercise)
        }
        .sheet(isPresented: $showPlanPicker) {
            PlanPickerSheet(exerciseId: exercise.id)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
            Text(exercise.nameZH)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(exercise.name.capitalized)
                .font(.title3.smallCaps())
                .foregroundColor(.textSecondary)
        }
    }

    private var gifBlock: some View {
        GlassCard(padding: Spacing.s.rawValue) {
            if let url = ExerciseStore.gifURL(for: exercise) {
                GIFPlayerView(url: url)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(Text("\(exercise.nameZH)，主目标肌群：\(exercise.targetZH)"))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 220)
                    .overlay(
                        Image(systemName: "play.slash")
                            .foregroundColor(.textSecondary)
                    )
            }
        }
    }

    private var metadataBlock: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                metaRow(icon: "figure.stand", zh: exercise.bodyPartZH, en: exercise.bodyPart, label: "部位 Body Part")
                Divider().opacity(0.2)
                metaRow(icon: "scope", zh: exercise.targetZH, en: exercise.target, label: "主要目标 Target")
                Divider().opacity(0.2)
                metaRow(icon: "person.fill.viewfinder", zh: exercise.muscleGroupZH, en: exercise.muscleGroup, label: "肌群 Muscle Group")
                Divider().opacity(0.2)
                metaRow(icon: "dumbbell", zh: exercise.equipmentZH, en: exercise.equipment, label: "器械 Equipment")
                if !exercise.secondaryMuscles.isEmpty {
                    Divider().opacity(0.2)
                    VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                        Text("辅助肌群 Secondary")
                            .font(.caption2.smallCaps())
                            .foregroundColor(.textSecondary)
                        Text(exercise.secondaryMuscles.joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }

    private func metaRow(icon: String, zh: String, en: String, label: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m.rawValue) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(zh)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.textPrimary)
                Text(en.capitalized)
                    .font(.caption2.smallCaps())
                    .foregroundColor(.textSecondary)
            }
            Spacer()
        }
    }

    private var stepsBlock: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                HStack {
                    Text("动作步骤")
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("Steps")
                        .font(.subheadline.smallCaps())
                        .foregroundColor(.textSecondary)
                }
                BilingualStepView(
                    zhSteps: exercise.instructionSteps["zh"] ?? [],
                    enSteps: exercise.instructionSteps["en"] ?? []
                )
            }
        }
    }
}
