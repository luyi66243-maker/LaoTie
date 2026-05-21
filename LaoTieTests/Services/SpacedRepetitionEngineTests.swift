import XCTest
@testable import LaoTie

final class SpacedRepetitionEngineTests: XCTestCase {

    func testNewCardStartsWithDefaultValues() {
        let card = SRSCard.new(vocabularyId: "test")
        XCTAssertEqual(card.easeFactor, 2.5)
        XCTAssertEqual(card.interval, 0)
        XCTAssertEqual(card.repetitions, 0)
    }

    func testForgotResetsRepetitions() {
        var card = SRSCard.new(vocabularyId: "test")
        card.repetitions = 3
        card.interval = 10

        let updated = SpacedRepetitionEngine.review(card: card, rating: .forgot)
        XCTAssertEqual(updated.repetitions, 0)
        XCTAssertEqual(updated.interval, 1)
    }

    func testGoodRatingIncreasesInterval() {
        let card = SRSCard.new(vocabularyId: "test")

        let after1 = SpacedRepetitionEngine.review(card: card, rating: .good)
        XCTAssertEqual(after1.interval, 1)
        XCTAssertEqual(after1.repetitions, 1)

        let after2 = SpacedRepetitionEngine.review(card: after1, rating: .good)
        XCTAssertEqual(after2.interval, 6)
        XCTAssertEqual(after2.repetitions, 2)

        let after3 = SpacedRepetitionEngine.review(card: after2, rating: .good)
        XCTAssertGreaterThan(after3.interval, 6)
        XCTAssertEqual(after3.repetitions, 3)
    }

    func testEaseFactorNeverDropsBelowMinimum() {
        var card = SRSCard.new(vocabularyId: "test")

        // Repeatedly fail to drive ease factor down
        for _ in 0..<20 {
            card = SpacedRepetitionEngine.review(card: card, rating: .forgot)
        }

        XCTAssertGreaterThanOrEqual(card.easeFactor, 1.3)
    }

    func testIsDueForReview() {
        var card = SRSCard.new(vocabularyId: "test")
        card.nextReviewDate = Date().addingTimeInterval(-3600)
        XCTAssertTrue(SpacedRepetitionEngine.isDueForReview(card))

        card.nextReviewDate = Date().addingTimeInterval(3600)
        XCTAssertFalse(SpacedRepetitionEngine.isDueForReview(card))
    }
}
