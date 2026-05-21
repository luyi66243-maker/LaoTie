import XCTest
@testable import LaoTie

final class SpeechScoringTests: XCTestCase {
    let service = SpeechRecognitionService()

    func testPerfectMatch() {
        let score = service.scorePronounciation(recognized: "你嘎哈去啊", target: "你嘎哈去啊")
        XCTAssertEqual(score.score, 100)
        XCTAssertEqual(score.grade, .excellent)
    }

    func testCloseMatch() {
        let score = service.scorePronounciation(recognized: "你嘎哈去", target: "你嘎哈去啊")
        XCTAssertGreaterThanOrEqual(score.score, 70)
        XCTAssertTrue(score.grade == .excellent || score.grade == .good)
    }

    func testPartialMatch() {
        let score = service.scorePronounciation(recognized: "你好", target: "你嘎哈去啊")
        XCTAssertLessThan(score.score, 70)
    }

    func testEmptyRecognized() {
        let score = service.scorePronounciation(recognized: "", target: "你嘎哈去啊")
        XCTAssertEqual(score.score, 0)
        XCTAssertEqual(score.grade, .needsPractice)
    }

    func testPunctuationIgnored() {
        let score = service.scorePronounciation(recognized: "你嘎哈去啊？", target: "你嘎哈去啊")
        XCTAssertEqual(score.score, 100)
    }
}
