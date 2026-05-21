import Foundation

// Local-only DailyQuoteRepository — loads from bundled JSON

protocol DailyQuoteRepositoryProtocol {
    func fetchAll() async throws -> [DailyQuote]
    func fetchByCategory(_ category: QuoteCategory) async throws -> [DailyQuote]
    func getQuoteOfTheDay() async throws -> DailyQuote
    func getRandomQuote() async throws -> DailyQuote?
}

final class DailyQuoteRepository: DailyQuoteRepositoryProtocol, Sendable {

    private func loadFromBundle() -> [DailyQuote] {
        guard let url = Bundle.main.url(forResource: "daily_quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([DailyQuote].self, from: data) else {
            return []
        }
        return items
    }

    func fetchAll() async throws -> [DailyQuote] {
        loadFromBundle()
    }

    func fetchByCategory(_ category: QuoteCategory) async throws -> [DailyQuote] {
        loadFromBundle().filter { $0.category == category }
    }

    /// Returns a deterministic quote based on today's date
    func getQuoteOfTheDay() async throws -> DailyQuote {
        let quotes = loadFromBundle()
        guard !quotes.isEmpty else {
            return DailyQuote.preview
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let dayHash = (components.year ?? 0) * 1000 + (components.month ?? 0) * 100 + (components.day ?? 0)
        let index = abs(dayHash) % quotes.count
        return quotes[index]
    }

    func getRandomQuote() async throws -> DailyQuote? {
        let quotes = loadFromBundle()
        return quotes.randomElement()
    }
}
