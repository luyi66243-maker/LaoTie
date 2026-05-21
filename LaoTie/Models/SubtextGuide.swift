import Foundation

// MARK: - 东北话潜台词人情世故指南模型

enum SubtextScenario: String, Codable, CaseIterable, Sendable {
    case greeting = "打招呼"
    case invitation = "邀请"
    case dinner = "饭局"
    case refusal = "拒绝"
    case compliment = "夸奖"
    case warning = "警告"
    case argument = "吵架"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .greeting: "hand.wave.fill"
        case .invitation: "envelope.fill"
        case .dinner: "fork.knife"
        case .refusal: "xmark.circle.fill"
        case .compliment: "star.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .argument: "bolt.fill"
        }
    }
}

struct SubtextGuide: Codable, Identifiable, Sendable {
    var id: String
    var scenario: SubtextScenario
    var literalMeaning: String // 字面意思
    var actualMeaning: String // 实际意思
    var properResponse: [String] // 正确回应方式
    var usageContext: String // 使用场景说明
    var examples: [SubtextExample]
    var difficulty: Int // 1-5, 5最难理解
    var audioFileName: String?
    
    static let preview = SubtextGuide(
        id: "st001",
        scenario: .invitation,
        literalMeaning: "来就来呗，还拿啥东西啊",
        actualMeaning: "嘴上说客气，其实心里很认可你的礼数，下次来记得还带东西",
        properResponse: [
            "哎呀，这不是应该的嘛！",
            "都是些不值钱的玩意儿，别嫌弃！",
            "下次可不带了啊（其实下次还要带）"
        ],
        usageContext: "去东北人家里串门、拜年、拜访时常用。东北人讲究礼数，带礼物是对主人的尊重。",
        examples: [
            SubtextExample(
                dialogue: "甲：来就来呗，还拿啥东西啊！乙：哎呀，这不是应该的嘛！",
                explanation: "甲嘴上说客气，但心里很高兴你懂礼数；乙的回应既谦虚又给足了面子"
            )
        ],
        difficulty: 4,
        audioFileName: "st001_audio"
    )
}

struct SubtextExample: Codable, Sendable {
    var dialogue: String
    var explanation: String
}
