import Foundation

enum SpacedRepetitionEngine {
    enum Rating: Int {
        case forgot = 0    // 不认识
        case hard = 3      // 模糊
        case good = 4      // 认识
        case easy = 5      // 太简单了
    }

    static func review(card: SRSCard, rating: Rating) -> SRSCard {
        var updated = card
        let q = Double(rating.rawValue)

        if rating == .forgot {
            updated.repetitions = 0
            updated.interval = 1
        } else {
            if updated.repetitions == 0 {
                updated.interval = 1
            } else if updated.repetitions == 1 {
                updated.interval = 6
            } else {
                updated.interval = Int(Double(updated.interval) * updated.easeFactor)
            }
            updated.repetitions += 1
        }

        // Update ease factor using SM-2 formula
        let newEF = updated.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        updated.easeFactor = max(1.3, newEF)

        updated.lastReviewDate = Date()
        updated.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: updated.interval,
            to: Date()
        ) ?? Date()

        return updated
    }

    static func isDueForReview(_ card: SRSCard) -> Bool {
        card.nextReviewDate <= Date()
    }
}
