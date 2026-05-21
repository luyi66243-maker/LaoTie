import Foundation

// MARK: - DongbeiMeme

enum MemeCategory: String, Codable, CaseIterable, Sendable {
    case classicMeme = "classicMeme"
    case cultureTip = "cultureTip"
    case xiehouyu = "xiehouyu"
    case usageGuide = "usageGuide"

    var displayName: String {
        switch self {
        case .classicMeme: "经典梗"
        case .cultureTip: "文化科普"
        case .xiehouyu: "歇后语"
        case .usageGuide: "用法百科"
        }
    }

    var icon: String {
        switch self {
        case .classicMeme: "flame.fill"
        case .cultureTip: "book.fill"
        case .xiehouyu: "text.quote"
        case .usageGuide: "character.book.closed.fill"
        }
    }
}

struct DongbeiMeme: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let category: MemeCategory
    let content: String
    let origin: String?
    let usage: String
    let funFact: String?
    let examples: [String]

    static let preview = DongbeiMeme(
        id: "meme_classic_001",
        title: "你瞅啥？瞅你咋地！",
        category: .classicMeme,
        content: "东北最经典的对话，堪称东北社交的灵魂对白。两句话构成了一个完整的社交闭环。",
        origin: "源自东北民间日常生活",
        usage: "当被人盯着看时的标准回应",
        funFact: "这句话其实是东北人表达自信和不服输精神的方式",
        examples: ["你瞅啥？我瞅你咋地！", "别瞅了，再瞅就削你！"]
    )
}
