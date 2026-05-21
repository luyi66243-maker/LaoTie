import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "AchievementService")

// MARK: - Profile Achievement Model

struct ProfileAchievement: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let icon: String
    let description: String
    let category: Category
    let condition: Condition
    let rewardXP: Int
    var isUnlocked: Bool
    var unlockedAt: Date?

    enum Category: String, Codable, Sendable {
        case milestone = "里程碑"
        case quiz = "闯关"
        case dialogue = "唠嗑"
        case vocabulary = "词汇"
        case checkin = "打卡"
        case streak = "坚持"
    }

    enum Condition: Codable, Sendable {
        case always
        case quizLevels(Int)
        case vocabularyCount(Int)
        case dialogueCount(Int)
        case checkinCount(Int)
        case streakDays(Int)
        case totalXP(Int)
    }

    static let all: [ProfileAchievement] = [
        ProfileAchievement(
            id: "pa_potato", title: "南方小土豆", icon: "🥔",
            description: "注册成为唠嗑小馆用户，开启东北之旅",
            category: .milestone, condition: .always, rewardXP: 50,
            isUnlocked: true, unlockedAt: nil
        ),
        ProfileAchievement(
            id: "pa_pass", title: "东北通行证", icon: "🎫",
            description: "通过第一个闯关关卡",
            category: .quiz, condition: .quizLevels(1), rewardXP: 100,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_half", title: "半个东北人", icon: "🧣",
            description: "累计学习20个东北话词汇",
            category: .vocabulary, condition: .vocabularyCount(20), rewardXP: 200,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_laotie", title: "地道老铁", icon: "🔥",
            description: "累计通过10个闯关关卡",
            category: .quiz, condition: .quizLevels(10), rewardXP: 500,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_certified", title: "铁子认证", icon: "🏅",
            description: "完成3个唠嗑场景练习",
            category: .dialogue, condition: .dialogueCount(3), rewardXP: 300,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_fur", title: "貂皮大衣", icon: "🧥",
            description: "连续学习7天，坚持就是胜利",
            category: .streak, condition: .streakDays(7), rewardXP: 200,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_chatking", title: "唠嗑之王", icon: "👑",
            description: "完成全邐10个唠嗑场景",
            category: .dialogue, condition: .dialogueCount(10), rewardXP: 1000,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_maxlevel", title: "满级老铁", icon: "💎",
            description: "通过全邐60个闯关关卡",
            category: .quiz, condition: .quizLevels(60), rewardXP: 5000,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_firstcheckin", title: "初次打卡", icon: "📸",
            description: "完成第一次风景打卡",
            category: .checkin, condition: .checkinCount(1), rewardXP: 100,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_hunter", title: "风景猎人", icon: "🔭",
            description: "累计打匁10个东北景点",
            category: .checkin, condition: .checkinCount(10), rewardXP: 500,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_scholar", title: "学霸附体", icon: "📚",
            description: "累计学习50个东北话词汇",
            category: .vocabulary, condition: .vocabularyCount(50), rewardXP: 300,
            isUnlocked: false
        ),
        ProfileAchievement(
            id: "pa_expert", title: "东北百科", icon: "🎓",
            description: "累计获得5000经验值",
            category: .milestone, condition: .totalXP(5000), rewardXP: 2000,
            isUnlocked: false
        ),
    ]
}

// MARK: - Achievement Service

final class AchievementService: Sendable {
    private let progressRepo = ProgressRepository()
    private let checkInRepo = CheckInRepository()

    private var fileURL: URL? {
        guard let userId = UserDefaults.standard.string(forKey: "laotie_user_id") else { return nil }
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("profile_achievements_\(userId).json")
    }

    /// Load saved achievements, merging with latest definitions
    func loadAchievements() async -> [ProfileAchievement] {
        var saved: [ProfileAchievement] = []
        if let url = fileURL,
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([ProfileAchievement].self, from: data) {
            saved = decoded
        }

        // Merge: use saved unlock status, but ensure all definitions are present
        let savedMap = Dictionary(uniqueKeysWithValues: saved.map { ($0.id, $0) })
        return ProfileAchievement.all.map { def in
            if let existing = savedMap[def.id] {
                var merged = def
                merged.isUnlocked = existing.isUnlocked
                merged.unlockedAt = existing.unlockedAt
                return merged
            }
            return def
        }
    }

    /// Check and update all achievements based on current progress
    func refreshAchievements() async -> (achievements: [ProfileAchievement], newlyUnlocked: [ProfileAchievement]) {
        var achievements = await loadAchievements()

        // Gather progress data
        let progress = (try? await progressRepo.fetchProgress()) ?? .empty
        let checkIns = (try? await checkInRepo.fetchCheckIns()) ?? []
        let approvedCheckIns = checkIns.filter { $0.status == .approved }.count
        let streak = UserDefaults.standard.integer(forKey: "laotie_streak")

        let quizCompleted = progress.quizResults.count
        let vocabLearned = progress.vocabularyLearned.count
        let dialoguesCompleted = progress.dialoguesCompleted.count
        let totalXP = progress.totalXP

        var newlyUnlocked: [ProfileAchievement] = []

        for i in achievements.indices {
            guard !achievements[i].isUnlocked else { continue }

            let shouldUnlock: Bool = switch achievements[i].condition {
            case .always:
                true
            case .quizLevels(let n):
                quizCompleted >= n
            case .vocabularyCount(let n):
                vocabLearned >= n
            case .dialogueCount(let n):
                dialoguesCompleted >= n
            case .checkinCount(let n):
                approvedCheckIns >= n
            case .streakDays(let n):
                streak >= n
            case .totalXP(let n):
                totalXP >= n
            }

            if shouldUnlock {
                achievements[i].isUnlocked = true
                achievements[i].unlockedAt = Date()
                newlyUnlocked.append(achievements[i])
                logger.info("Achievement unlocked: \(achievements[i].title)")

                // 发放 XP 奖励
                let xpReward = achievements[i].rewardXP
                let title = achievements[i].title
                Task {
                    await XPService.shared.addXP(
                        amount: xpReward,
                        sourceType: .achievementUnlock,
                        description: "成就解锁「\(title)」"
                    )
                }
            }
        }

        // Persist
        await save(achievements)

        return (achievements, newlyUnlocked)
    }

    private func save(_ achievements: [ProfileAchievement]) async {
        guard let url = fileURL else { return }
        if let data = try? JSONEncoder().encode(achievements) {
            try? data.write(to: url)
        }
    }
}
