import Foundation

// Local-only QuizRepository — loads from bundled JSON

protocol QuizRepositoryProtocol {
    func fetchAllLevels() async throws -> [QuizLevel]
}

final class QuizRepository: QuizRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [QuizLevel] {
        guard let url = Bundle.main.url(forResource: "quizzes", withExtension: "json") else {
            print("[QuizRepository] quizzes.json 未找到")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let items = try JSONDecoder().decode([QuizLevel].self, from: data)
            return items.sorted { $0.levelNumber < $1.levelNumber }
        } catch {
            print("[QuizRepository] quizzes.json 解析失败: \(error)")
            return []
        }
    }

    func fetchAllLevels() async throws -> [QuizLevel] {
        return loadFromBundle()
    }
}
