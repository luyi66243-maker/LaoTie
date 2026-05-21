import Foundation

// MARK: - Quiz

enum QuestionType: String, Codable, Sendable {
    case multipleChoice = "multiple_choice"
    case matching = "matching"
    case listening = "listening"
    case fillInBlank = "fill_in_blank"
}

struct QuizQuestion: Codable, Identifiable, Sendable {
    var id: String
    var type: QuestionType
    var prompt: String
    var audioFileName: String?
    var options: [String]?
    var matchingPairs: [MatchingPair]?
    var correctAnswer: String
    var explanation: String

    struct MatchingPair: Codable, Sendable {
        var dongbei: String
        var standard: String
    }
}

struct QuizLevel: Codable, Identifiable, Sendable {
    var id: String
    var levelNumber: Int
    var title: String
    var subtitle: String
    var province: String
    var city: String
    var questions: [QuizQuestion]
    var passingScore: Int
    var rewardXP: Int
    var rewardTitle: String?

    static let preview = QuizLevel(
        id: "level_1",
        levelNumber: 1,
        title: "长春关",
        subtitle: "东北话入门测试",
        province: "吉林",
        city: "长春",
        questions: [
            QuizQuestion(
                id: "q1",
                type: .multipleChoice,
                prompt: "\"嘎哈\"是什么意思？",
                options: ["吃饭", "干什么", "睡觉", "走路"],
                correctAnswer: "干什么",
                explanation: "\"嘎哈\"就是\"干啥\"的意思，东北人每天都在说！"
            )
        ],
        passingScore: 60,
        rewardXP: 100,
        rewardTitle: nil
    )
}

struct QuizResult: Codable, Sendable {
    var levelId: String
    var score: Int
    var totalQuestions: Int
    var correctCount: Int
    var stars: Int // 1-3
    var completedAt: Date
}
