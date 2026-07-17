import SwiftUI

struct SpaceBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.spaceTop, .spaceMid, .spaceBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            if !reduceMotion {
                FloatingGlowBlob(color: .accentColor, size: 320, duration: 4.2, offset: CGPoint(x: -120, y: -260))
                FloatingGlowBlob(color: .accentColor.opacity(0.55), size: 260, duration: 5.0, offset: CGPoint(x: 150, y: 220))
            }
        }
        .ignoresSafeArea()
    }
}

private struct FloatingGlowBlob: View {
    let color: Color
    let size: CGFloat
    let duration: Double
    let offset: CGPoint

    @State private var phase: CGFloat = 0

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 110)
            .opacity(0.55)
            .offset(x: offset.x + 14 * sin(phase), y: offset.y + 18 * cos(phase * 0.9))
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    phase = .pi
                }
            }
    }
}