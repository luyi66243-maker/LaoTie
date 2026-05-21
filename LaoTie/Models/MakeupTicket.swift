import Foundation

struct MakeupTicket: Codable, Identifiable, Sendable {
    let id: String
    let obtainedAt: Date
    let expiresAt: Date
    let source: TicketSource
    var isUsed: Bool
    var usedAt: Date?
    var usedForDate: String?  // yyyy-MM-dd，补哪天的卡

    enum TicketSource: String, Codable, Sendable {
        case xpExchange         // XP 兑换
        case milestoneReward    // 里程碑奖励
        case newUserBonus       // 新用户福利
        case dailyTaskReward    // 每日任务奖励（预留）
    }

    var isExpired: Bool {
        Date() > expiresAt
    }

    var isValid: Bool {
        !isUsed && !isExpired
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day ?? 0
    }

    /// 创建一张新补卡券（有效期 90 天）
    static func create(source: TicketSource) -> MakeupTicket {
        let now = Date()
        return MakeupTicket(
            id: UUID().uuidString,
            obtainedAt: now,
            expiresAt: Calendar.current.date(byAdding: .day, value: 90, to: now) ?? now,
            source: source,
            isUsed: false,
            usedAt: nil,
            usedForDate: nil
        )
    }
}
