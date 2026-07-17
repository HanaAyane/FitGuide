import SwiftUI

struct AttributionFooter: View {
    var body: some View {
        VStack(spacing: Spacing.xs.rawValue) {
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)
            Text("© Gym visual — gymvisual.com")
                .font(.caption2)
                .foregroundColor(.textSecondary)
            if let url = URL(string: "https://gymvisual.com/") {
                Link(destination: url) {
                    HStack(spacing: Spacing.xs.rawValue) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption2)
                        Text("查看媒体来源  View source")
                            .font(.caption2.smallCaps())
                    }
                    .foregroundColor(Color.accentColor)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.s.rawValue)
    }
}