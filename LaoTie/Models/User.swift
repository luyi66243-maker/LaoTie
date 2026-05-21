import Foundation

struct LaoTieUser: Codable, Identifiable, Sendable {
    var id: String
    var nickname: String
    var avatarURL: String?
    var region: String
    var totalScore: Int
    var currentStreak: Int
    var titles: [String]
    var createdAt: Date
    var lastActiveAt: Date

    static let preview = LaoTieUser(
        id: "preview-user",
        nickname: "南方小土豆",
        region: "广东",
        totalScore: 1280,
        currentStreak: 7,
        titles: ["南方小土豆", "东北通行证"],
        createdAt: Date(),
        lastActiveAt: Date()
    )
}
