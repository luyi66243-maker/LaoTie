import UIKit

@MainActor
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func correctAnswer() {
        notification(.success)
    }

    static func wrongAnswer() {
        notification(.error)
    }

    static func levelUp() {
        impact(.heavy)
    }
}
