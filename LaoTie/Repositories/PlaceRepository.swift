import Foundation

final class PlaceRepository: Sendable {

    private func loadFromBundle() -> [DongbeiPlace] {
        guard let url = Bundle.main.url(forResource: "places", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([DongbeiPlace].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async -> [DongbeiPlace] {
        loadFromBundle()
    }

    func search(_ query: String) async -> [DongbeiPlace] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }
        return loadFromBundle().filter { place in
            place.name.lowercased().contains(q)
            || place.province.lowercased().contains(q)
            || place.culture.lowercased().contains(q)
            || place.signatureDishes.contains { $0.lowercased().contains(q) }
            || place.famousSpots.contains { $0.lowercased().contains(q) }
        }
    }
}
