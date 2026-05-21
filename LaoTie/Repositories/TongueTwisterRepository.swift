import Foundation

// Local-only TongueTwisterRepository — loads from bundled JSON

protocol TongueTwisterRepositoryProtocol {
    func fetchAll() async throws -> [TongueTwister]
    func fetchByCategory(_ category: String) async throws -> [TongueTwister]
    func fetchByDifficulty(_ difficulty: Int) async throws -> [TongueTwister]
}

final class TongueTwisterRepository: TongueTwisterRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [TongueTwister] {
        guard let url = Bundle.main.url(forResource: "tongue_twisters", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([TongueTwister].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async throws -> [TongueTwister] {
        loadFromBundle()
    }

    func fetchByCategory(_ category: String) async throws -> [TongueTwister] {
        loadFromBundle().filter { $0.category == category }
    }

    func fetchByDifficulty(_ difficulty: Int) async throws -> [TongueTwister] {
        loadFromBundle().filter { $0.difficulty == difficulty }
    }
}
