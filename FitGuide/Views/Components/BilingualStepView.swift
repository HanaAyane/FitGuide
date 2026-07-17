import SwiftUI

struct BilingualStepView: View {
    let zhSteps: [String]
    let enSteps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.m.rawValue) {
            if zhSteps.isEmpty && enSteps.isEmpty {
                Text("暂无步骤 / No steps available")
                    .foregroundColor(.textSecondary)
                    .font(.subheadline)
            } else {
                let count = max(zhSteps.count, enSteps.count)
                ForEach(0..<count, id: \.self) { i in
                    stepRow(index: i + 1,
                            zh: i < zhSteps.count ? zhSteps[i] : "",
                            en: i < enSteps.count ? enSteps[i] : "")
                }
            }
        }
    }

    private func stepRow(index: Int, zh: String, en: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m.rawValue) {
            Text("\(index)")
                .font(.headline.monospacedDigit())
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .overlay(Circle().strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1))
                )
            VStack(alignment: .leading, spacing: Spacing.xs.rawValue) {
                if !zh.isEmpty {
                    Text(zh)
                        .font(.body)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                if !en.isEmpty {
                    Text(en)
                        .font(.footnote.smallCaps())
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                }
            }
            Spacer(minLength: 0)
        }
    }
}