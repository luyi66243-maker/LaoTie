import SwiftUI

enum Theme {
    // MARK: - Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacingXXL: CGFloat = 48

    // MARK: - Corner Radius
    static let cornerRadiusSM: CGFloat = 8
    static let cornerRadiusMD: CGFloat = 12
    static let cornerRadiusLG: CGFloat = 16
    static let cornerRadiusXL: CGFloat = 24

    // MARK: - Font Styles
    static let titleFont: Font = .system(size: 28, weight: .black, design: .rounded)
    static let headlineFont: Font = .system(size: 20, weight: .bold, design: .rounded)
    static let bodyFont: Font = .system(.body, design: .rounded)
    static let captionFont: Font = .system(.caption, design: .rounded)
    static let dongbeiWordFont: Font = .system(size: 36, weight: .heavy, design: .rounded)
    static let pinyinFont: Font = .system(size: 14, weight: .medium, design: .monospaced)

    // MARK: - Extended Font Styles
    static let largeTitleFont: Font = .system(size: 36, weight: .black, design: .rounded)
    static let subheadlineFont: Font = .system(size: 15, weight: .semibold, design: .rounded)
    static let labelFont: Font = .system(size: 13, weight: .medium, design: .rounded)
    static let smallLabelFont: Font = .system(size: 11, weight: .medium, design: .rounded)
    static let badgeFont: Font = .system(size: 10, weight: .bold, design: .rounded)
    static let tinyFont: Font = .system(size: 9, weight: .medium, design: .rounded)

    // MARK: - Shadows
    static let cardShadow: some ShapeStyle = Color.black.opacity(0.08)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowColor: Color = .black.opacity(0.06)
    static let cardShadowY: CGFloat = 4
}
