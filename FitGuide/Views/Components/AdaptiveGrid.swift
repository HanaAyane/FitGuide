import SwiftUI

enum GridColumns {
    static let count: Int = {
        let w = UIScreen.main.bounds.width
        return w >= 430 ? 3 : 2
    }()

    static var adaptive: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: Spacing.m.rawValue), count: count)
    }
}