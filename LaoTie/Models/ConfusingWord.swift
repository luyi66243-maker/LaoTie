import Foundation

// MARK: - 易混淆词和南北用词差异模型

enum WordComparisonType: String, Codable, CaseIterable, Sendable {
    case confusing = "易混淆词"
    case northSouthDifference = "南北用词差异"
    case taboo = "禁忌词"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .confusing: "questionmark.circle.fill"
        case .northSouthDifference: "map.fill"
        case .taboo: "exclamationmark.triangle.fill"
        }
    }
}

struct ConfusingWord: Codable, Identifiable, Sendable {
    var id: String
    var type: WordComparisonType
    var dongbeiWord: String
    var dongbeiPinyin: String
    var standardWord: String
    var standardPinyin: String
    var meaning: String
    var usageNote: String?
    var examples: [String]
    var isTaboo: Bool
    var tabooLevel: Int? // 1-5, 5是最禁忌
    var dongbeiAudioFileName: String?
    var standardAudioFileName: String?
    
    static let preview = ConfusingWord(
        id: "cw001",
        type: .northSouthDifference,
        dongbeiWord: "洗澡",
        dongbeiPinyin: "xǐ zǎo",
        standardWord: "冲凉",
        standardPinyin: "chōng liáng",
        meaning: "在东北，'洗澡'通常指去澡堂子洗大澡，包括搓澡、汗蒸等全套服务；而在南方，'冲凉'一般只是简单冲洗身体。",
        usageNote: "如果你在东北邀请朋友去'洗澡'，可能会被理解为去澡堂子享受全套服务哦！",
        examples: [
            "走啊，去洗澡啊？（东北：去澡堂子）",
            "天太热了，冲个凉吧（南方：简单冲洗）"
        ],
        isTaboo: false,
        tabooLevel: nil,
        dongbeiAudioFileName: "xizao_dongbei",
        standardAudioFileName: "chongliang_standard"
    )
}
