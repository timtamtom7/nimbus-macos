import SwiftUI

struct Theme {

    // MARK: - Colors

    static let primary = Color.blue
    static let secondary = Color.gray
    static let accent = Color.blue.opacity(0.8)
    static let background = Color(nsColor: NSColor.windowBackgroundColor)
    static let surface = Color(nsColor: NSColor.controlBackgroundColor)
    static let textPrimary = Color(nsColor: NSColor.labelColor)
    static let textSecondary = Color(nsColor: NSColor.secondaryLabelColor)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32

    // MARK: - Corner Radius

    static let cornerRadius: CGFloat = 8
    static let cornerRadiusSmall: CGFloat = 4

    // MARK: - Font Sizes

    static let fontSizeSmall: CGFloat = 11
    static let fontSizeMedium: CGFloat = 13
    static let fontSizeLarge: CGFloat = 15

    // MARK: - Shadows

    static let shadowRadius: CGFloat = 4
    static let shadowOpacity: CGFloat = 0.1
}

// MARK: - View Modifiers

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.surface)
            .cornerRadius(Theme.cornerRadius)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
