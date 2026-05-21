import Foundation

protocol ScenicRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [Scenic]
}

final class ScenicRepository: ScenicRepositoryProtocol, Sendable {
    func fetchAll() async throws -> [Scenic] {
        guard let url = Bundle.main.url(forResource: "scenics", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        do {
            let scenics = try JSONDecoder().decode([Scenic].self, from: data)
            logImageAudit(scenics)
            return scenics
        } catch {
            print("[ScenicRepository] Failed to decode scenics JSON: \(error)")
            return []
        }
    }

    private func logImageAudit(_ scenics: [Scenic]) {
        let exactCount = scenics.filter { $0.imageMatchType == .exact }.count
        let representativeCount = scenics.filter { $0.imageMatchType == .representative }.count
        let pendingCount = scenics.filter { $0.imageMatchType == .pending }.count

        print("[ScenicImageAudit] exact=\(exactCount), representative=\(representativeCount), pending=\(pendingCount)")

        if pendingCount > 0 {
            let pendingPreview = scenics
                .filter { $0.imageMatchType == .pending }
                .prefix(8)
                .map { "\($0.name)(\($0.id))" }
                .joined(separator: ", ")
            print("[ScenicImageAudit] Pending examples: \(pendingPreview)")
        }
    }
}
