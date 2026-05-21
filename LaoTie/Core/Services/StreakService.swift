import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "StreakService")

// MARK: - Streak Data Model

struct StreakData: Codable, Sendable {
    var currentStreak: Int
    var lastLearningDate: String?  // yyyy-MM-dd
    var makeupTickets: Int         // 向后兼容，从 loadTickets() 计算
    var todayLearned: Bool         // transient, computed on load

    static let empty = StreakData(currentStreak: 0, lastLearningDate: nil, makeupTickets: 0, todayLearned: false)
}

// MARK: - Streak Service

final class StreakService: Sendable {

    /// 向后兼容：兑换起步价
    static let ticketCostXP = 100
    /// 月度兑换上限
    static let monthlyExchangeLimit = 10
    /// 单月补卡上限
    static let monthlyUsageLimit = 5
    /// 补卡最大可追溯天数
    static let maxMakeupDays = 30

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = .current
        return f
    }()

    // MARK: - Keys

    private enum Keys {
        static let streak = "laotie_streak"
        static let lastDate = "laotie_streak_last_date"
        static let tickets = "laotie_streak_tickets" // 快速缓存，向后兼容
        static let autoMakeup = "laotie_auto_makeup"
    }

    // MARK: - Auto Makeup Switch

    /// 自动补卡开关（UserDefaults）
    var isAutoMakeupEnabled: Bool {
        get { UserDefaults.standard.object(forKey: Keys.autoMakeup) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Keys.autoMakeup) }
    }

    // MARK: - Ticket File Storage

    private var currentUserId: String {
        UserDefaults.standard.string(forKey: "laotie_user_id") ?? "default"
    }

    private var ticketFileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("tickets_\(currentUserId).json")
    }

    /// 加载所有补卡券（自动清理过期的已使用券）
    func loadTickets() -> [MakeupTicket] {
        guard let data = try? Data(contentsOf: ticketFileURL),
              let tickets = try? JSONDecoder().decode([MakeupTicket].self, from: data) else {
            return []
        }
        // 清理过期且已使用的券，保留未使用的（即使过期，也让用户看到）
        return tickets
    }

    /// 保存补卡券
    func saveTickets(_ tickets: [MakeupTicket]) {
        if let data = try? JSONEncoder().encode(tickets) {
            try? data.write(to: ticketFileURL)
        }
        // 同步快速缓存
        UserDefaults.standard.set(tickets.filter { $0.isValid }.count, forKey: Keys.tickets)
    }

    /// 获取有效券数量
    func validTicketCount() -> Int {
        loadTickets().filter { $0.isValid }.count
    }

    /// 获取即将过期的券（3天内）
    func expiringTickets() -> [MakeupTicket] {
        loadTickets().filter { $0.isValid && $0.daysUntilExpiry <= 3 }
    }

    // MARK: - Load Streak

    /// Load current streak data, automatically handling break detection
    func loadStreak() -> StreakData {
        let streak = UserDefaults.standard.integer(forKey: Keys.streak)
        let lastDateStr = UserDefaults.standard.string(forKey: Keys.lastDate)
        let today = Self.dateFormatter.string(from: Date())
        let validCount = validTicketCount()

        let todayLearned = lastDateStr == today

        // Check for break: if lastDate exists and is not today or yesterday
        if let lastDateStr, lastDateStr != today {
            let daysDiff = daysBetween(lastDateStr, today)

            if daysDiff > 1 {
                let missedDays = daysDiff - 1

                // 超过30天不可补，强制重置
                if missedDays > Self.maxMakeupDays {
                    logger.info("Streak broken: \(daysDiff) days gap exceeds max makeup days")
                    UserDefaults.standard.set(0, forKey: Keys.streak)
                    return StreakData(currentStreak: 0, lastLearningDate: lastDateStr,
                                     makeupTickets: validCount, todayLearned: false)
                }

                // 自动补卡模式
                if isAutoMakeupEnabled && validCount >= missedDays {
                    // Auto-consume tickets to cover missed days
                    var tickets = loadTickets()
                    var consumed = 0
                    for i in tickets.indices {
                        guard consumed < missedDays else { break }
                        if tickets[i].isValid {
                            tickets[i].isUsed = true
                            tickets[i].usedAt = Date()
                            tickets[i].usedForDate = lastDateStr
                            consumed += 1
                        }
                    }
                    saveTickets(tickets)
                    logger.info("Auto-used \(consumed) makeup ticket(s) to preserve streak of \(streak)")
                    return StreakData(currentStreak: streak, lastLearningDate: lastDateStr,
                                     makeupTickets: validTicketCount(), todayLearned: false)
                } else {
                    // Streak broken - reset
                    logger.info("Streak broken: \(daysDiff) days since last learning")
                    UserDefaults.standard.set(0, forKey: Keys.streak)
                    return StreakData(currentStreak: 0, lastLearningDate: lastDateStr,
                                     makeupTickets: validCount, todayLearned: false)
                }
            }
        }

        return StreakData(currentStreak: streak, lastLearningDate: lastDateStr,
                         makeupTickets: validCount, todayLearned: todayLearned)
    }

    // MARK: - Record Learning

    /// Call this when user completes any learning activity (quiz, dialogue, vocabulary review)
    /// Returns updated StreakData
    @discardableResult
    func recordLearning() -> StreakData {
        let today = Self.dateFormatter.string(from: Date())
        let lastDateStr = UserDefaults.standard.string(forKey: Keys.lastDate)
        var streak = UserDefaults.standard.integer(forKey: Keys.streak)

        if lastDateStr == today {
            // Already learned today, no change
            return StreakData(currentStreak: streak, lastLearningDate: today,
                             makeupTickets: validTicketCount(), todayLearned: true)
        }

        if let lastDateStr {
            let daysDiff = daysBetween(lastDateStr, today)

            if daysDiff == 1 {
                // Consecutive day - increment streak
                streak += 1
            } else if daysDiff > 1 {
                // Gap detected - check if tickets were already consumed by loadStreak
                if streak == 0 {
                    streak = 1
                } else {
                    // Tickets covered the gap, just increment
                    streak += 1
                }
            } else {
                streak = max(streak, 1)
            }
        } else {
            // First time learning ever
            streak = 1
            // 新用户首次打卡赠券
            grantNewUserBonus()
        }

        // Save
        UserDefaults.standard.set(streak, forKey: Keys.streak)
        UserDefaults.standard.set(today, forKey: Keys.lastDate)

        logger.info("Learning recorded. Streak: \(streak)")

        // 检查里程碑奖励
        if let milestone = checkMilestoneReward(streak: streak) {
            logger.info("Milestone reached: \(milestone.title), +\(milestone.tickets) tickets, +\(milestone.xp) XP")
        }

        return StreakData(currentStreak: streak, lastLearningDate: today,
                         makeupTickets: validTicketCount(), todayLearned: true)
    }

    // MARK: - Streak Bonus XP

    /// 计算连续天数对应的打卡 XP 奖励
    static func streakBonusXP(for streak: Int) -> Int {
        // 梯度：第1変10XP，每天+10，封顶100XP
        return min(streak * 10, 100)
    }

    // MARK: - Gradient Pricing Exchange

    /// 获取当前兑换价格
    func currentExchangePrice() -> Int {
        let monthKey = currentMonthKey()
        let exchangedThisMonth = getMonthlyExchangeCount(monthKey)

        if exchangedThisMonth < 2 { return 100 }      // 前2张
        if exchangedThisMonth < 5 { return 200 }       // 3-5张
        return 300                                      // 6张及以上
    }

    /// 本月已兑换数量
    func getMonthlyExchangeCount(_ monthKey: String) -> Int {
        UserDefaults.standard.integer(forKey: "laotie_exchange_count_\(monthKey)")
    }

    private func incrementMonthlyExchangeCount(_ monthKey: String) {
        let current = getMonthlyExchangeCount(monthKey)
        UserDefaults.standard.set(current + 1, forKey: "laotie_exchange_count_\(monthKey)")
    }

    /// 兑换补卡券（使用 XPService 扣费）
    func exchangeTicket() async -> (success: Bool, ticket: MakeupTicket?, message: String) {
        let monthKey = currentMonthKey()
        let exchangedCount = getMonthlyExchangeCount(monthKey)

        guard exchangedCount < Self.monthlyExchangeLimit else {
            return (false, nil, "本月兑换已达上限（10张）")
        }

        let price = currentExchangePrice()
        let result = await XPService.shared.deductXP(
            amount: price,
            sourceType: .ticketExchange,
            description: "兑换补卡券（\(price) XP）"
        )

        guard result.success else {
            let current = XPService.shared.getCurrentXPSync()
            return (false, nil, "积分不足，还差 \(price - current) XP")
        }

        let ticket = MakeupTicket.create(source: .xpExchange)
        var tickets = loadTickets()
        tickets.append(ticket)
        saveTickets(tickets)

        incrementMonthlyExchangeCount(monthKey)

        return (true, ticket, "兑换成功！有效期90天")
    }

    /// 向后兼容的同步兑换接口
    func exchangeTicket(currentXP: Int) -> (success: Bool, newXP: Int, newTickets: Int) {
        guard currentXP >= currentExchangePrice() else {
            return (false, currentXP, validTicketCount())
        }
        let price = currentExchangePrice()
        let newXP = currentXP - price

        let ticket = MakeupTicket.create(source: .xpExchange)
        var tickets = loadTickets()
        tickets.append(ticket)
        saveTickets(tickets)

        let monthKey = currentMonthKey()
        incrementMonthlyExchangeCount(monthKey)

        logger.info("Exchanged \(price) XP for makeup ticket")

        return (true, newXP, validTicketCount())
    }

    // MARK: - Ticket Usage

    /// 本月已使用补卡数
    func getMonthlyUsageCount() -> Int {
        let monthKey = currentMonthKey()
        return UserDefaults.standard.integer(forKey: "laotie_usage_count_\(monthKey)")
    }

    private func incrementMonthlyUsageCount() {
        let monthKey = currentMonthKey()
        let current = UserDefaults.standard.integer(forKey: "laotie_usage_count_\(monthKey)")
        UserDefaults.standard.set(current + 1, forKey: "laotie_usage_count_\(monthKey)")
    }

    /// 使用补卡券
    func useTicket(forDate dateString: String) -> (success: Bool, message: String) {
        let monthlyUsed = getMonthlyUsageCount()
        guard monthlyUsed < Self.monthlyUsageLimit else {
            return (false, "本月补卡已达上限（5天）")
        }

        var tickets = loadTickets()
        guard let index = tickets.firstIndex(where: { $0.isValid }) else {
            return (false, "没有可用的补卡券")
        }

        tickets[index].isUsed = true
        tickets[index].usedAt = Date()
        tickets[index].usedForDate = dateString
        saveTickets(tickets)

        incrementMonthlyUsageCount()

        return (true, "补卡成功！")
    }

    /// 手动使用补卡券恢复连续天数（向后兼容）
    func useTicketToRestore(brokenStreak: Int) -> StreakData {
        let result = useTicket(forDate: Self.dateFormatter.string(from: Date()))
        guard result.success else {
            return loadStreak()
        }

        let restoredStreak = max(brokenStreak, 1)
        UserDefaults.standard.set(restoredStreak, forKey: Keys.streak)

        let today = Self.dateFormatter.string(from: Date())
        let lastDate = UserDefaults.standard.string(forKey: Keys.lastDate)

        logger.info("Used ticket to restore streak to \(restoredStreak)")

        return StreakData(currentStreak: restoredStreak, lastLearningDate: lastDate,
                         makeupTickets: validTicketCount(), todayLearned: lastDate == today)
    }

    // MARK: - Milestone Rewards

    /// 检查并发放里程碑奖励（连续天数达到里程碑时调用）
    @discardableResult
    func checkMilestoneReward(streak: Int) -> (tickets: Int, xp: Int, title: String)? {
        let milestones: [(days: Int, tickets: Int, xp: Int, title: String)] = [
            (7, 1, 100, "东北话入门"),
            (30, 5, 500, "半个东北人"),
            (100, 15, 2000, "地道老铁"),
            (365, 50, 10000, "东北话大师")
        ]

        guard let milestone = milestones.first(where: { $0.days == streak }) else { return nil }

        // 检查是否已领取过此里程碑
        let claimedKey = "laotie_milestone_\(milestone.days)_claimed"
        guard !UserDefaults.standard.bool(forKey: claimedKey) else { return nil }

        // 发放补卡券
        var tickets = loadTickets()
        for _ in 0..<milestone.tickets {
            tickets.append(MakeupTicket.create(source: .milestoneReward))
        }
        saveTickets(tickets)

        // 发放 XP
        Task {
            await XPService.shared.addXP(
                amount: milestone.xp,
                sourceType: .milestoneReward,
                description: "里程碑「\(milestone.title)」奖励"
            )
        }

        UserDefaults.standard.set(true, forKey: claimedKey)

        return (milestone.tickets, milestone.xp, milestone.title)
    }

    /// 新用户首次打卡赠券
    func grantNewUserBonus() {
        let key = "laotie_new_user_bonus_granted"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        var tickets = loadTickets()
        for _ in 0..<2 {
            tickets.append(MakeupTicket.create(source: .newUserBonus))
        }
        saveTickets(tickets)
        UserDefaults.standard.set(true, forKey: key)
        logger.info("Granted 2 new user bonus tickets")
    }

    // MARK: - Helpers

    private func currentMonthKey() -> String {
        Self.monthFormatter.string(from: Date())
    }

    private func daysBetween(_ dateStr1: String, _ dateStr2: String) -> Int {
        guard let d1 = Self.dateFormatter.date(from: dateStr1),
              let d2 = Self.dateFormatter.date(from: dateStr2) else { return 0 }
        let cal = Calendar.current
        let components = cal.dateComponents([.day], from: cal.startOfDay(for: d1), to: cal.startOfDay(for: d2))
        return abs(components.day ?? 0)
    }
}

// MARK: - Daily Task

struct DailyTaskProgress: Codable, Sendable {
    var date: String
    var dailyWordCompleted: Bool
    var quizAnsweredCount: Int
    var dialoguePracticeCount: Int
    var reviewCount: Int
    var rewardClaimed: Bool

    static let quizTarget = 3
    static let dialogueTarget = 1
    static let reviewTarget = 1

    enum CodingKeys: String, CodingKey {
        case date, dailyWordCompleted, quizAnsweredCount, dialoguePracticeCount, reviewCount, rewardClaimed
    }

    var quizCompleted: Bool { quizAnsweredCount >= Self.quizTarget }
    var dialogueCompleted: Bool { dialoguePracticeCount >= Self.dialogueTarget }
    var reviewCompleted: Bool { reviewCount >= Self.reviewTarget }

    var completedTaskCount: Int {
        var count = 0
        if dailyWordCompleted { count += 1 }
        if quizCompleted { count += 1 }
        if dialogueCompleted { count += 1 }
        if reviewCompleted { count += 1 }
        return count
    }

    var completionRate: Double {
        Double(completedTaskCount) / 4.0
    }

    var canClaimReward: Bool {
        completedTaskCount >= 4 && !rewardClaimed
    }

    static func empty(for date: String) -> DailyTaskProgress {
        DailyTaskProgress(
            date: date,
            dailyWordCompleted: false,
            quizAnsweredCount: 0,
            dialoguePracticeCount: 0,
            reviewCount: 0,
            rewardClaimed: false
        )
    }

    init(
        date: String,
        dailyWordCompleted: Bool,
        quizAnsweredCount: Int,
        dialoguePracticeCount: Int,
        reviewCount: Int,
        rewardClaimed: Bool
    ) {
        self.date = date
        self.dailyWordCompleted = dailyWordCompleted
        self.quizAnsweredCount = quizAnsweredCount
        self.dialoguePracticeCount = dialoguePracticeCount
        self.reviewCount = reviewCount
        self.rewardClaimed = rewardClaimed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        dailyWordCompleted = try c.decode(Bool.self, forKey: .dailyWordCompleted)
        quizAnsweredCount = try c.decode(Int.self, forKey: .quizAnsweredCount)
        dialoguePracticeCount = try c.decode(Int.self, forKey: .dialoguePracticeCount)
        reviewCount = try c.decode(Int.self, forKey: .reviewCount)
        rewardClaimed = try c.decodeIfPresent(Bool.self, forKey: .rewardClaimed) ?? false
    }
}

extension Notification.Name {
    static let dailyTaskProgressDidChange = Notification.Name("dailyTaskProgressDidChange")
}

final class DailyTaskService: Sendable {
    private enum Keys {
        static let base = "laotie_daily_tasks"
        static let rewardXP = 120
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    func loadTodayProgress() -> DailyTaskProgress {
        let today = Self.dateFormatter.string(from: Date())
        let key = storageKey(for: today)

        guard let data = UserDefaults.standard.data(forKey: key),
              let progress = try? JSONDecoder().decode(DailyTaskProgress.self, from: data) else {
            return .empty(for: today)
        }
        return progress
    }

    @discardableResult
    func markDailyWordCompleted() -> DailyTaskProgress {
        updateToday { progress in
            progress.dailyWordCompleted = true
        }
    }

    @discardableResult
    func addQuizAnswered(count: Int = 1) -> DailyTaskProgress {
        updateToday { progress in
            progress.quizAnsweredCount = min(
                progress.quizAnsweredCount + max(0, count),
                DailyTaskProgress.quizTarget
            )
        }
    }

    @discardableResult
    func addDialoguePractice(count: Int = 1) -> DailyTaskProgress {
        updateToday { progress in
            progress.dialoguePracticeCount = min(
                progress.dialoguePracticeCount + max(0, count),
                DailyTaskProgress.dialogueTarget
            )
        }
    }

    @discardableResult
    func addReviewSession(count: Int = 1) -> DailyTaskProgress {
        updateToday { progress in
            progress.reviewCount = min(
                progress.reviewCount + max(0, count),
                DailyTaskProgress.reviewTarget
            )
        }
    }

    @discardableResult
    func claimRewardIfEligible() -> Bool {
        var claimed = false
        _ = updateToday { progress in
            if progress.canClaimReward {
                progress.rewardClaimed = true
                claimed = true
            }
        }
        return claimed
    }

    static var dailyRewardXP: Int { Keys.rewardXP }

    @discardableResult
    private func updateToday(_ mutate: (inout DailyTaskProgress) -> Void) -> DailyTaskProgress {
        var progress = loadTodayProgress()
        mutate(&progress)
        save(progress)
        NotificationCenter.default.post(name: .dailyTaskProgressDidChange, object: nil)
        return progress
    }

    private func save(_ progress: DailyTaskProgress) {
        let key = storageKey(for: progress.date)
        guard let data = try? JSONEncoder().encode(progress) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func storageKey(for date: String) -> String {
        "\(Keys.base)_\(date)"
    }
}

// MARK: - Wrong Answer Review Schedule

struct ReviewScheduleItem: Codable, Identifiable, Sendable {
    var id: String
    var wordId: String
    var questionPrompt: String
    var dueDate: String
    var stage: Int
    var isCompleted: Bool
}

extension Notification.Name {
    static let reviewScheduleDidChange = Notification.Name("reviewScheduleDidChange")
}

final class ReviewScheduleService: Sendable {
    private let storageKey = "laotie_wrong_answer_review_schedule_v1"
    private let intervals = [1, 3, 7]

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    func todayDueCount() -> Int {
        let today = todayString()
        return loadItems().filter { !$0.isCompleted && $0.dueDate <= today }.count
    }

    func dueWordIDsToday() -> Set<String> {
        let today = todayString()
        return Set(loadItems().filter { !$0.isCompleted && $0.dueDate <= today }.map(\.wordId))
    }

    func dueItemsToday() -> [ReviewScheduleItem] {
        let today = todayString()
        return loadItems()
            .filter { !$0.isCompleted && $0.dueDate <= today }
            .sorted { lhs, rhs in
                if lhs.dueDate == rhs.dueDate {
                    return lhs.stage < rhs.stage
                }
                return lhs.dueDate < rhs.dueDate
            }
    }

    func scheduleWrongAnswer(wordId: String, questionPrompt: String) {
        var items = loadItems()
        if items.contains(where: { $0.wordId == wordId && !$0.isCompleted }) {
            return
        }

        let firstDue = dateByAddingDays(intervals[0], from: Date())
        let item = ReviewScheduleItem(
            id: "review_\(wordId)",
            wordId: wordId,
            questionPrompt: questionPrompt,
            dueDate: Self.dateFormatter.string(from: firstDue),
            stage: 0,
            isCompleted: false
        )
        items.insert(item, at: 0)
        saveItems(items)
    }

    @discardableResult
    func markReviewed(wordId: String) -> Bool {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.wordId == wordId && !$0.isCompleted }) else {
            return false
        }

        var item = items[index]
        let nextStage = item.stage + 1
        if nextStage >= intervals.count {
            item.stage = nextStage
            item.isCompleted = true
        } else {
            item.stage = nextStage
            item.dueDate = Self.dateFormatter.string(from: dateByAddingDays(intervals[nextStage], from: Date()))
        }

        items[index] = item
        saveItems(items)
        return true
    }

    private func loadItems() -> [ReviewScheduleItem] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let items = try? JSONDecoder().decode([ReviewScheduleItem].self, from: data) else {
            return []
        }
        return items
    }

    private func saveItems(_ items: [ReviewScheduleItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
        NotificationCenter.default.post(name: .reviewScheduleDidChange, object: nil)
    }

    private func todayString() -> String {
        Self.dateFormatter.string(from: Date())
    }

    private func dateByAddingDays(_ days: Int, from date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }
}
