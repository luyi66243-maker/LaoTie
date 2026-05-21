import Foundation

// Local-only MemeRepository — loads from bundled JSON

protocol MemeRepositoryProtocol {
    func fetchAll() async throws -> [DongbeiMeme]
    func fetchByCategory(_ category: MemeCategory) async throws -> [DongbeiMeme]
    func search(_ query: String) async throws -> [DongbeiMeme]
}

final class MemeRepository: MemeRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [DongbeiMeme] {
        guard let url = Bundle.main.url(forResource: "memes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([DongbeiMeme].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async throws -> [DongbeiMeme] {
        loadFromBundle()
    }

    func fetchByCategory(_ category: MemeCategory) async throws -> [DongbeiMeme] {
        loadFromBundle().filter { $0.category == category }
    }

    func search(_ query: String) async throws -> [DongbeiMeme] {
        let q = query.lowercased()
        return loadFromBundle().filter {
            $0.title.lowercased().contains(q) ||
            $0.content.lowercased().contains(q) ||
            $0.usage.lowercased().contains(q) ||
            $0.examples.contains(where: { $0.lowercased().contains(q) })
        }
    }
}
