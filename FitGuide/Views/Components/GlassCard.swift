import SwiftUI

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = Radii.card.rawValue
    var padding: CGFloat = Spacing.m.rawValue
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            content()
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            content()
                .padding(padding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.18), .white.opacity(0.03)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                    }
                )
        }
    }
}