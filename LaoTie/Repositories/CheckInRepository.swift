import Foundation

protocol CheckInRepositoryProtocol: Sendable {
    func fetchCheckIns() async throws -> [ScenicCheckIn]
    func saveCheckIn(_ checkIn: ScenicCheckIn) async throws
    func fetchAchievements() async throws -> [Achievement]
    func saveAchievements(_ achievements: [Achievement]) async throws
    func fetchLeaderboard() async throws -> [CheckInLeaderboardEntry]
    func fetchCheckedInScenicIds() async throws -> Set<String>
}

final class CheckInRepository: CheckInRepositoryProtocol, Sendable {

    private var userId: String? {
        UserDefaults.standard.string(forKey: "laotie_user_id")
    }

    private var checkInsFileURL: URL? {
        guard let userId else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[CheckInRepository] Cannot access document directory")
            return nil
        }
        return dir.appendingPathComponent("checkins_\(userId).json")
    }

    private var achievementsFileURL: URL? {
        guard let userId else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[CheckInRepository] Cannot access document directory")
            return nil
        }
        return dir.appendingPathComponent("achievements_\(userId).json")
    }

    private var photosDirectory: URL? {
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[CheckInRepository] Cannot access document directory")
            return nil
        }
        let photosDir = dir.appendingPathComponent("checkin_photos", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: photosDir, withIntermediateDirectories: true)
        } catch {
            print("[CheckInRepository] Failed to create photos directory: \(error)")
        }
        return photosDir
    }

    func fetchCheckIns() async throws -> [ScenicCheckIn] {
        guard let url = checkInsFileURL else { return [] }
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([ScenicCheckIn].self, from: data)
            return items.sorted { $0.submittedAt > $1.submittedAt }
        } catch {
            print("[CheckInRepository] Failed to fetch check-ins: \(error)")
            return []
        }
    }

    func saveCheckIn(_ checkIn: ScenicCheckIn) async throws {
        var all = try await fetchCheckIns()
        all.removeAll { $0.id == checkIn.id }
        all.append(checkIn)
        guard let url = checkInsFileURL else { return }
        do {
            let data = try JSONEncoder().encode(all)
            try data.write(to: url)
        } catch {
            print("[CheckInRepository] Failed to save check-in: \(error)")
        }
    }

    func savePhoto(data: Data, fileName: String) throws -> URL {
        guard let dir = photosDirectory else {
            throw NSError(domain: "CheckInRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot access photos directory"])
        }
        let fileURL = dir.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }

    func photoURL(for fileName: String) -> URL? {
        photosDirectory?.appendingPathComponent(fileName)
    }

    func fetchAchievements() async throws -> [Achievement] {
        guard let url = achievementsFileURL else { return Achievement.allAchievements }
        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([Achievement].self, from: data)
            return items
        } catch {
            print("[CheckInRepository] Failed to fetch achievements: \(error)")
            return Achievement.allAchievements
        }
    }

    func saveAchievements(_ achievements: [Achievement]) async throws {
        guard let url = achievementsFileURL else { return }
        do {
            let data = try JSONEncoder().encode(achievements)
            try data.write(to: url)
        } catch {
            print("[CheckInRepository] Failed to save achievements: \(error)")
        }
    }

    /// Simulate auto-approval for V1.0 (no backend yet).
    /// In production, this would be replaced by a server-side review process.
    func simulateReview(for checkIn: ScenicCheckIn) async throws -> ScenicCheckIn {
        var reviewed = checkIn
        // Simulate a short delay, then auto-approve
        try? await Task.sleep(for: .seconds(2))
        reviewed.status = .approved
        reviewed.reviewedAt = Date()
        try await saveCheckIn(reviewed)
        return reviewed
    }

    func fetchLeaderboard() async throws -> [CheckInLeaderboardEntry] {
        // V1.0: Generate sample leaderboard + current user
        let checkIns = try await fetchCheckIns()
        let approvedCheckIns = checkIns.filter { $0.status == .approved }
        let approvedCount = approvedCheckIns.count
        let nickname = UserDefaults.standard.string(forKey: "laotie_nickname") ?? "我"
        let latest = checkIns.first(where: { $0.status == .approved })?.scenicName ?? ""
        let myAuthLevel = resolveAuthenticityLevel(for: approvedCheckIns)

        var entries: [CheckInLeaderboardEntry] = [
            .init(id: "lb1", nickname: "雪地里的广东仔", checkInCount: 42, latestScenic: "哈尔滨冰雪大世界", totalXP: 8600, authenticityLevel: .high),
            .init(id: "lb2", nickname: "福建小土豆", checkInCount: 35, latestScenic: "长白山天池", totalXP: 7200, authenticityLevel: .high),
            .init(id: "lb3", nickname: "浙江来的铁子", checkInCount: 28, latestScenic: "雾凇岛", totalXP: 5800, authenticityLevel: .medium),
            .init(id: "lb4", nickname: "湖南辣妹子闯东北", checkInCount: 21, latestScenic: "沈阳故宫", totalXP: 4500, authenticityLevel: .medium),
            .init(id: "lb5", nickname: "上海宁在哈尔滨", checkInCount: 15, latestScenic: "雪乡", totalXP: 3200, authenticityLevel: .medium),
            .init(id: "lb6", nickname: "海南怕冷星人", checkInCount: 12, latestScenic: "漠河北极村", totalXP: 2600, authenticityLevel: .low),
            .init(id: "lb7", nickname: "四川火锅遇铁锅", checkInCount: 8, latestScenic: "中央大街", totalXP: 1800, authenticityLevel: .low),
        ]

        if approvedCount > 0 {
            let me = CheckInLeaderboardEntry(
                id: "lb_me",
                nickname: nickname,
                checkInCount: approvedCount,
                latestScenic: latest,
                totalXP: approvedCount * 100,
                authenticityLevel: myAuthLevel
            )
            entries.append(me)
        }

        return entries.sorted { $0.checkInCount > $1.checkInCount }
    }

    func fetchCheckedInScenicIds() async throws -> Set<String> {
        let checkIns = try await fetchCheckIns()
        let approvedIds = checkIns.filter { $0.status == .approved }.map { $0.scenicId }
        return Set(approvedIds)
    }

    private func resolveAuthenticityLevel(for approvedCheckIns: [ScenicCheckIn]) -> ScenicCheckIn.Authenticity.Level {
        guard !approvedCheckIns.isEmpty else { return .low }
        let avgScore = Double(approvedCheckIns.map { $0.authenticity.score }.reduce(0, +)) / Double(approvedCheckIns.count)
        if avgScore >= 3 { return .high }
        if avgScore >= 2 { return .medium }
        return .low
    }
}
