import Foundation

// Local-only DialogueRepository — loads from bundled JSON

protocol DialogueRepositoryProtocol {
    func fetchAll() async throws -> [Dialogue]
}

final class DialogueRepository: DialogueRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [Dialogue] {
        guard let url = Bundle.main.url(forResource: "dialogues", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([Dialogue].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async throws -> [Dialogue] {
        return loadFromBundle()
    }
}
