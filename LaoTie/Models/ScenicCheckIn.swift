import Foundation

// MARK: - Check-in record

struct ScenicCheckIn: Codable, Identifiable, Sendable {
    var id: String
    var scenicId: String
    var scenicName: String
    var province: String
    var photoFileName: String
    var submittedAt: Date
    var status: CheckInStatus
    var reviewedAt: Date?
    var rewardXP: Int
    var authenticity: Authenticity

    enum CheckInStatus: String, Codable, Sendable {
        case pending = "pending"       // 审核中
        case approved = "approved"     // 审核通过
        case rejected = "rejected"     // 审核未通过
    }

    struct Authenticity: Codable, Sendable {
        var locationVerified: Bool
        var distanceMeters: Double?
        var hasCaptureTimeMetadata: Bool
        var captureTimeWithin72Hours: Bool
        var hasGPSMetadata: Bool

        enum Level: String, Codable, Sendable {
            case high = "high"
            case medium = "medium"
            case low = "low"

            var label: String {
                switch self {
                case .high: return "高可信"
                case .medium: return "中可信"
                case .low: return "基础可信"
                }
            }
        }

        var score: Int {
            var value = 0
            if locationVerified { value += 1 }
            if hasCaptureTimeMetadata { value += 1 }
            if captureTimeWithin72Hours { value += 1 }
            if hasGPSMetadata { value += 1 }
            return value
        }

        var level: Level {
            if score >= 3 { return .high }
            if score >= 2 { return .medium }
            return .low
        }

        var summary: String {
            let locationText = locationVerified ? "位置校验通过" : "位置信息不足"
            let timeText = hasCaptureTimeMetadata
                ? (captureTimeWithin72Hours ? "拍摄时间近期" : "拍摄时间较早")
                : "缺少拍摄时间元数据"
            let gpsText = hasGPSMetadata ? "含GPS元数据" : "无GPS元数据"
            return "\(locationText) · \(timeText) · \(gpsText)"
        }

        static let baseline = Authenticity(
            locationVerified: false,
            distanceMeters: nil,
            hasCaptureTimeMetadata: false,
            captureTimeWithin72Hours: false,
            hasGPSMetadata: false
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, scenicId, scenicName, province, photoFileName, submittedAt, status, reviewedAt, rewardXP, authenticity
    }

    init(
        id: String,
        scenicId: String,
        scenicName: String,
        province: String,
        photoFileName: String,
        submittedAt: Date,
        status: CheckInStatus,
        reviewedAt: Date?,
        rewardXP: Int,
        authenticity: Authenticity = .baseline
    ) {
        self.id = id
        self.scenicId = scenicId
        self.scenicName = scenicName
        self.province = province
        self.photoFileName = photoFileName
        self.submittedAt = submittedAt
        self.status = status
        self.reviewedAt = reviewedAt
        self.rewardXP = rewardXP
        self.authenticity = authenticity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        scenicId = try container.decode(String.self, forKey: .scenicId)
        scenicName = try container.decode(String.self, forKey: .scenicName)
        province = try container.decode(String.self, forKey: .province)
        photoFileName = try container.decode(String.self, forKey: .photoFileName)
        submittedAt = try container.decode(Date.self, forKey: .submittedAt)
        status = try container.decode(CheckInStatus.self, forKey: .status)
        reviewedAt = try container.decodeIfPresent(Date.self, forKey: .reviewedAt)
        rewardXP = try container.decode(Int.self, forKey: .rewardXP)
        authenticity = try container.decodeIfPresent(Authenticity.self, forKey: .authenticity) ?? .baseline
    }
}

// MARK: - Achievement

struct Achievement: Codable, Identifiable, Sendable {
    var id: String
    var title: String
    var description: String
    var icon: String
    var requirement: Int          // 达成所需打卡数
    var rewardXP: Int
    var unlockedAt: Date?

    var isUnlocked: Bool { unlockedAt != nil }

    static let allAchievements: [Achievement] = [
        Achievement(id: "ach_first", title: "初次打卡", description: "完成第一次风景打卡", icon: "flag.fill", requirement: 1, rewardXP: 50),
        Achievement(id: "ach_3", title: "小小探险家", description: "累计打卡3个风景", icon: "figure.walk", requirement: 3, rewardXP: 100),
        Achievement(id: "ach_5", title: "东北新手", description: "累计打卡5个风景", icon: "camera.fill", requirement: 5, rewardXP: 150),
        Achievement(id: "ach_10", title: "风景猎人", description: "累计打卡10个风景", icon: "binoculars.fill", requirement: 10, rewardXP: 300),
        Achievement(id: "ach_20", title: "东北达人", description: "累计打卡20个风景", icon: "star.fill", requirement: 20, rewardXP: 500),
        Achievement(id: "ach_30", title: "三省通行证", description: "累计打卡30个风景", icon: "map.fill", requirement: 30, rewardXP: 800),
        Achievement(id: "ach_50", title: "东北半壁江山", description: "累计打卡50个风景", icon: "mountain.2.fill", requirement: 50, rewardXP: 1200),
        Achievement(id: "ach_80", title: "资深老铁", description: "累计打卡80个风景", icon: "medal.fill", requirement: 80, rewardXP: 2000),
        Achievement(id: "ach_100", title: "东北全景大师", description: "打卡全部100个风景", icon: "trophy.fill", requirement: 100, rewardXP: 5000),
    ]
}

// MARK: - Leaderboard entry for check-ins

struct CheckInLeaderboardEntry: Codable, Identifiable, Sendable {
    var id: String
    var nickname: String
    var checkInCount: Int
    var latestScenic: String
    var totalXP: Int
    var authenticityLevel: ScenicCheckIn.Authenticity.Level

    enum CodingKeys: String, CodingKey {
        case id, nickname, checkInCount, latestScenic, totalXP, authenticityLevel
    }

    init(
        id: String,
        nickname: String,
        checkInCount: Int,
        latestScenic: String,
        totalXP: Int,
        authenticityLevel: ScenicCheckIn.Authenticity.Level = .medium
    ) {
        self.id = id
        self.nickname = nickname
        self.checkInCount = checkInCount
        self.latestScenic = latestScenic
        self.totalXP = totalXP
        self.authenticityLevel = authenticityLevel
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        nickname = try container.decode(String.self, forKey: .nickname)
        checkInCount = try container.decode(Int.self, forKey: .checkInCount)
        latestScenic = try container.decode(String.self, forKey: .latestScenic)
        totalXP = try container.decode(Int.self, forKey: .totalXP)
        authenticityLevel = try container.decodeIfPresent(ScenicCheckIn.Authenticity.Level.self, forKey: .authenticityLevel) ?? .medium
    }
}
