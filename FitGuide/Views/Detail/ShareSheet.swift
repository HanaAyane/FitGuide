import SwiftUI
import UIKit

struct ShareSheet: View {
    let exercise: Exercise
    @State private var copied = false
    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        let zhStr = (exercise.instructionSteps["zh"] ?? []).enumerated().map { i, s in "\(i+1). \(s)" }.joined(separator: "\n")
        let enStr = (exercise.instructionSteps["en"] ?? []).enumerated().map { i, s in "\(i+1). \(s)" }.joined(separator: "\n")
        return """
        \(exercise.nameZH) · \(exercise.name.capitalized)

        动作步骤
        \(zhStr)

        Steps
        \(enStr)

        © Gym visual — https://gymvisual.com/
        """
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
                        GlassCard {
                            VStack(alignment: .leading, spacing: Spacing.s.rawValue) {
                                Text(shareText)
                                    .font(.footnote)
                                    .foregroundColor(.textPrimary)
                                    .textSelection(.enabled)
                            }
                        }
                        Button {
                            UIPasteboard.general.string = shareText
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "已复制 Copied" : "复制双语步骤 Copy")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.m.rawValue)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                        .strokeBorder(Color.accentColor.opacity(0.4), lineWidth: 1)
                                }
                            )
                        }
                        ShareLink(item: shareText, subject: Text("\(exercise.nameZH) · \(exercise.name)")) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("系统分享 Share")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(Spacing.m.rawValue)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                        .fill(.ultraThinMaterial)
                                    RoundedRectangle(cornerRadius: Radii.card.rawValue)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                }
                            )
                        }
                        AttributionFooter()
                    }
                    .padding(Spacing.m.rawValue)
                }
            }
            .navigationTitle("分享 Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("完成", action: { dismiss() })
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
}