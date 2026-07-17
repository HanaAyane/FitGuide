import SwiftUI

enum Spacing: CGFloat {
    case xs = 4
    case s = 8
    case m = 16
    case l = 24
    case xl = 32
}

enum Radii: CGFloat {
    case card = 20
    case chip = 12
}

extension Color {
    static let spaceTop = Color("SpaceTop")
    static let spaceMid = Color("SpaceMid")
    static let spaceBottom = Color("SpaceBottom")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
}