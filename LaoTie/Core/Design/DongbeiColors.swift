import SwiftUI

enum DongbeiColors {
    static let dahong = Color(hex: 0xD62828)
    static let cuilu = Color(hex: 0x2D6A4F)
    static let jinhuang = Color(hex: 0xF4A261)
    static let huabufen = Color(hex: 0xE76F51)
    static let binglan = Color(hex: 0xA8DADC)
    static let qianlan = Color(hex: 0x83C5BE)
    static let snowWhite = Color(hex: 0xF1FAEE)
    static let meihei = Color(hex: 0x1D3557)

    static let cardBackground = Color.white
    static let pageBackground = Color(hex: 0xFAF5F0)

    // MARK: - Semantic Colors
    static let success = cuilu
    static let warning = jinhuang
    static let error = dahong
    static let info = binglan

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [dahong, Color(hex: 0xE63946)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let dahongGradient = LinearGradient(
        colors: [dahong, jinhuang],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let warmGradient = LinearGradient(
        colors: [Color(hex: 0xD62828), Color(hex: 0xF4A261), Color(hex: 0xF9C74F)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
