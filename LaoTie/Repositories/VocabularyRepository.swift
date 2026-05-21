import Foundation

// Local-only VocabularyRepository — loads from bundled JSON
// Replace with Firestore version when Firebase SDK is available

protocol VocabularyRepositoryProtocol {
    func fetchAll() async throws -> [Vocabulary]
    func fetchByCategory(_ category: VocabularyCategory) async throws -> [Vocabulary]
    func fetchByDifficulty(_ difficulty: Difficulty) async throws -> [Vocabulary]
}

final class VocabularyRepository: VocabularyRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [Vocabulary] {
        guard let url = Bundle.main.url(forResource: "vocabularies", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([Vocabulary].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async throws -> [Vocabulary] {
        return loadFromBundle()
    }

    func fetchByCategory(_ category: VocabularyCategory) async throws -> [Vocabulary] {
        return loadFromBundle().filter { $0.category == category }
    }

    func fetchByDifficulty(_ difficulty: Difficulty) async throws -> [Vocabulary] {
        return loadFromBundle().filter { $0.difficulty == difficulty }
    }
}
