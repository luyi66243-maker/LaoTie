import Foundation

// Local-only LeaderboardRepository — uses sample data
// Replace with Firestore version when Firebase SDK is available

protocol LeaderboardRepositoryProtocol {
    func fetchTopEntries(limit: Int) async throws -> [LeaderboardEntry]
    func updateEntry(_ entry: LeaderboardEntry) async throws
}

final class LeaderboardRepository: LeaderboardRepositoryProtocol, Sendable {

    func fetchTopEntries(limit: Int = 50) async throws -> [LeaderboardEntry] {
        // Return sample leaderboard data for offline mode
        [
            LeaderboardEntry(id: "1", nickname: "铁岭小翠", avatarURL: nil, totalScore: 2800, currentTitle: "地道老铁", updatedAt: Date()),
            LeaderboardEntry(id: "2", nickname: "哈尔滨大雪人", avatarURL: nil, totalScore: 2350, currentTitle: "半个东北人", updatedAt: Date()),
            LeaderboardEntry(id: "3", nickname: "长春玉米棒", avatarURL: nil, totalScore: 1900, currentTitle: "东北通行证", updatedAt: Date()),
            LeaderboardEntry(id: "4", nickname: "沈阳鸡架王", avatarURL: nil, totalScore: 1500, currentTitle: "东北通行证", updatedAt: Date()),
            LeaderboardEntry(id: "5", nickname: "广东靓仔", avatarURL: nil, totalScore: 800, currentTitle: "南方小土豆", updatedAt: Date()),
        ]
    }

    func updateEntry(_ entry: LeaderboardEntry) async throws {
        // No-op in local mode
    }
}
