import Foundation

// MARK: - XP Transaction Model

struct XPTransaction: Codable, Identifiable, Sendable {
    let id: String
    let source: String          // 来源描述
    let sourceType: XPSourceType
    let amount: Int             // 正数=获取，负数=消耗
    let balance: Int            // 交易后余额
    let timestamp: Date

    enum XPSourceType: String, Codable, Sendable {
        case quizPass           // 闯关通过
        case checkIn            // 景点打卡
        case dailyTaskReward    // 每日任务奖励
        case achievementUnlock  // 成就解锁
        case streakBonus        // 连续打卡奖励
        case ticketExchange     // 补卡券兑换（消耗）
        case milestoneReward    // 里程碑奖励
    }
}

// MARK: - XP Service

final class XPService: @unchecked Sendable {

    static let shared = XPService()

    private let progressRepo = ProgressRepository()
    private let userIdKey = "laotie_user_id"
    private let scoreKey = "laotie_score"

    /// XP 变化通知
    static let xpDidChangeNotification = Notification.Name("laotie_xp_did_change")

    private init() {}

    // MARK: - Public API

    /// 增加 XP（统一入口）
    @discardableResult
    func addXP(amount: Int, sourceType: XPTransaction.XPSourceType, description: String) async -> Int {
        guard amount > 0 else { return getCurrentXPSync() }

        // 1. 更新 ProgressRepository（单一真实源）
        var progress: LearningProgress
        do {
            progress = try await progressRepo.fetchProgress()
        } catch {
            progress = .empty
        }

        progress.totalXP += amount
        do {
            try await progressRepo.updateProgress(progress)
        } catch {
            print("[XPService] 保存进度失败: \(error)")
        }

        // 2. 同步到 UserDefaults
        UserDefaults.standard.set(progress.totalXP, forKey: scoreKey)

        // 3. 记录流水
        let transaction = XPTransaction(
            id: UUID().uuidString,
            source: description,
            sourceType: sourceType,
            amount: amount,
            balance: progress.totalXP,
            timestamp: Date()
        )
        saveTransaction(transaction)

        // 4. 发送通知
        NotificationCenter.default.post(
            name: Self.xpDidChangeNotification,
            object: nil,
            userInfo: ["xp": progress.totalXP, "change": amount]
        )

        return progress.totalXP
    }

    /// 扣减 XP（补卡券兑换等）
    @discardableResult
    func deductXP(amount: Int, sourceType: XPTransaction.XPSourceType, description: String) async -> (success: Bool, newXP: Int) {
        guard amount > 0 else { return (false, getCurrentXPSync()) }

        var progress: LearningProgress
        do {
            progress = try await progressRepo.fetchProgress()
        } catch {
            return (false, getCurrentXPSync())
        }

        guard progress.totalXP >= amount else {
            return (false, progress.totalXP)
        }

        progress.totalXP -= amount
        do {
            try await progressRepo.updateProgress(progress)
        } catch {
            print("[XPService] 保存进度失败: \(error)")
            return (false, progress.totalXP + amount)
        }

        UserDefaults.standard.set(progress.totalXP, forKey: scoreKey)

        let transaction = XPTransaction(
            id: UUID().uuidString,
            source: description,
            sourceType: sourceType,
            amount: -amount,
            balance: progress.totalXP,
            timestamp: Date()
        )
        saveTransaction(transaction)

        NotificationCenter.default.post(
            name: Self.xpDidChangeNotification,
            object: nil,
            userInfo: ["xp": progress.totalXP, "change": -amount]
        )

        return (true, progress.totalXP)
    }

    /// 获取当前 XP（异步，从 ProgressRepository 读取）
    func getCurrentXP() async -> Int {
        do {
            let progress = try await progressRepo.fetchProgress()
            // 同步到 UserDefaults 确保一致
            UserDefaults.standard.set(progress.totalXP, forKey: scoreKey)
            return progress.totalXP
        } catch {
            return getCurrentXPSync()
        }
    }

    /// 获取当前 XP（同步，从 UserDefaults 快速读取）
    func getCurrentXPSync() -> Int {
        UserDefaults.standard.integer(forKey: scoreKey)
    }

    /// 获取 XP 流水记录
    func getTransactionHistory() -> [XPTransaction] {
        let fileURL = transactionFileURL()
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let transactions = try? decoder.decode([XPTransaction].self, from: data) else {
            return []
        }
        return transactions.sorted { $0.timestamp > $1.timestamp }
    }

    /// 启动时同步 XP（从 ProgressRepository 同步到 UserDefaults）
    func syncXPOnLaunch() async {
        let xp = await getCurrentXP()
        UserDefaults.standard.set(xp, forKey: scoreKey)
    }

    // MARK: - Private

    private var currentUserId: String {
        UserDefaults.standard.string(forKey: userIdKey) ?? "default"
    }

    private func transactionFileURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("xp_history_\(currentUserId).json")
    }

    private func saveTransaction(_ transaction: XPTransaction) {
        var history = getTransactionHistory()
        history.insert(transaction, at: 0)

        // 保留最近 500 条记录
        if history.count > 500 {
            history = Array(history.prefix(500))
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(history) {
            try? data.write(to: transactionFileURL())
        }
    }
}
