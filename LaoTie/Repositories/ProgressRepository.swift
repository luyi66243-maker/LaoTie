import Foundation

// Local-only ProgressRepository — stores data via UserDefaults + JSON files
// Replace with Firestore version when Firebase SDK is available

protocol ProgressRepositoryProtocol {
    func fetchSRSCards() async throws -> [SRSCard]
    func saveSRSCard(_ card: SRSCard) async throws
    func fetchProgress() async throws -> LearningProgress
    func updateProgress(_ progress: LearningProgress) async throws
}

final class ProgressRepository: ProgressRepositoryProtocol, Sendable {

    private var userId: String? {
        UserDefaults.standard.string(forKey: "laotie_user_id")
    }

    private var srsFileURL: URL? {
        guard let userId else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[ProgressRepository] Cannot access document directory")
            return nil
        }
        return dir.appendingPathComponent("srs_\(userId).json")
    }

    private var progressFileURL: URL? {
        guard let userId else { return nil }
        guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("[ProgressRepository] Cannot access document directory")
            return nil
        }
        return dir.appendingPathComponent("progress_\(userId).json")
    }

    func fetchSRSCards() async throws -> [SRSCard] {
        guard let url = srsFileURL,
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([SRSCard].self, from: data) else {
            return []
        }
        return cards
    }

    func saveSRSCard(_ card: SRSCard) async throws {
        var cards = try await fetchSRSCards()
        cards.removeAll { $0.vocabularyId == card.vocabularyId }
        cards.append(card)
        guard let url = srsFileURL else { return }
        do {
            let data = try JSONEncoder().encode(cards)
            try data.write(to: url)
        } catch {
            print("[ProgressRepository] Failed to save SRS card: \(error)")
        }
    }

    func fetchProgress() async throws -> LearningProgress {
        guard let url = progressFileURL,
              let data = try? Data(contentsOf: url),
              let progress = try? JSONDecoder().decode(LearningProgress.self, from: data) else {
            return .empty
        }
        return progress
    }

    func updateProgress(_ progress: LearningProgress) async throws {
        guard let url = progressFileURL else { return }
        do {
            let data = try JSONEncoder().encode(progress)
            try data.write(to: url)
        } catch {
            print("[ProgressRepository] Failed to update progress: \(error)")
        }
    }
}
