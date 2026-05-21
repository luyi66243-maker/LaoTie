import Foundation

// MARK: - DailyQuote

struct DailyQuote: Codable, Identifiable, Sendable {
    let id: String
    let category: QuoteCategory
    let dongbeiText: String     // 东北话原文
    let standardText: String    // 普通话翻译
    let explanation: String     // 解释/背景
    let mood: String            // 适用心情/场景

    static let preview = DailyQuote(
        id: "q1",
        category: .duJiTang,
        dongbeiText: "努力不一定成功，但不努力是真舒坦",
        standardText: "努力不一定成功，但不努力真的很舒服",
        explanation: "东北式自嘲幽默，带着一股子洒脱劲儿",
        mood: "摸鱼时刻"
    )
}

// MARK: - QuoteCategory

enum QuoteCategory: String, Codable, CaseIterable, Sendable {
    case duJiTang = "duJiTang"
    case tuWeiQingHua = "tuWeiQingHua"
    case yanYu = "yanYu"
    case jingDianYuLu = "jingDianYuLu"

    var displayName: String {
        switch self {
        case .duJiTang: "毒鸡汤"
        case .tuWeiQingHua: "土味情话"
        case .yanYu: "东北谚语"
        case .jingDianYuLu: "经典语录"
        }
    }

    var icon: String {
        switch self {
        case .duJiTang: "cup.and.saucer.fill"
        case .tuWeiQingHua: "heart.fill"
        case .yanYu: "book.closed.fill"
        case .jingDianYuLu: "star.fill"
        }
    }
}
