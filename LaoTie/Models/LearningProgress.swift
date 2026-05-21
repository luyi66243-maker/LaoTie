import Foundation

struct SRSCard: Codable, Identifiable, Sendable {
    var id: String { vocabularyId }
    var vocabularyId: String
    var easeFactor: Double
    var interval: Int
    var repetitions: Int
    var nextReviewDate: Date
    var lastReviewDate: Date

    static func new(vocabularyId: String) -> SRSCard {
        SRSCard(
            vocabularyId: vocabularyId,
            easeFactor: 2.5,
            interval: 0,
            repetitions: 0,
            nextReviewDate: Date(),
            lastReviewDate: Date()
        )
    }
}

struct LearningProgress: Codable, Sendable {
    var userId: String
    var vocabularyLearned: Set<String>
    var dialoguesCompleted: Set<String>
    var quizResults: [String: QuizResult]
    var totalXP: Int
    var currentLevel: Int
    var unlockedTitles: [String]

    static let empty = LearningProgress(
        userId: "",
        vocabularyLearned: [],
        dialoguesCompleted: [],
        quizResults: [:],
        totalXP: 0,
        currentLevel: 1,
        unlockedTitles: ["南方小土豆"]
    )
}

struct LeaderboardEntry: Codable, Identifiable, Sendable {
    var id: String
    var nickname: String
    var avatarURL: String?
    var totalScore: Int
    var currentTitle: String
    var updatedAt: Date
}
