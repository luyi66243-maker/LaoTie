import XCTest
@testable import LaoTie

final class ModelCodingTests: XCTestCase {

    func testVocabularyDecoding() throws {
        let json = """
        {
            "id": "v001",
            "dongbeiWord": "嘎哈",
            "standardWord": "干什么",
            "pinyin": "gàn shén me",
            "dongbeiPinyin": "gá há",
            "meaning": "做什么",
            "exampleSentence": "你嘎哈去啊？",
            "exampleTranslation": "你要去干什么？",
            "category": "日常寒暄",
            "difficulty": "初来乍到"
        }
        """.data(using: .utf8)!

        let vocab = try JSONDecoder().decode(Vocabulary.self, from: json)
        XCTAssertEqual(vocab.id, "v001")
        XCTAssertEqual(vocab.dongbeiWord, "嘎哈")
        XCTAssertEqual(vocab.category, .dailyGreeting)
        XCTAssertEqual(vocab.difficulty, .beginner)
    }

    func testVocabularyRoundTrip() throws {
        let vocab = Vocabulary.preview
        let data = try JSONEncoder().encode(vocab)
        let decoded = try JSONDecoder().decode(Vocabulary.self, from: data)
        XCTAssertEqual(decoded.id, vocab.id)
        XCTAssertEqual(decoded.dongbeiWord, vocab.dongbeiWord)
        XCTAssertEqual(decoded.category, vocab.category)
    }

    func testQuizLevelDecoding() throws {
        let json = """
        {
            "id": "level_1",
            "levelNumber": 1,
            "title": "铁岭关",
            "subtitle": "东北话入门",
            "passingScore": 60,
            "rewardXP": 100,
            "questions": [
                {
                    "id": "q1",
                    "type": "multiple_choice",
                    "prompt": "嘎哈是什么意思？",
                    "options": ["吃饭", "干什么"],
                    "correctAnswer": "干什么",
                    "explanation": "就是干什么"
                }
            ]
        }
        """.data(using: .utf8)!

        let level = try JSONDecoder().decode(QuizLevel.self, from: json)
        XCTAssertEqual(level.levelNumber, 1)
        XCTAssertEqual(level.questions.count, 1)
        XCTAssertEqual(level.questions[0].type, .multipleChoice)
    }

    func testSeedDataVocabulariesParsing() throws {
        guard let url = Bundle.main.url(forResource: "vocabularies", withExtension: "json") else {
            // In test target the bundle may not include resources; skip gracefully
            return
        }
        let data = try Data(contentsOf: url)
        let vocabs = try JSONDecoder().decode([Vocabulary].self, from: data)
        XCTAssertGreaterThan(vocabs.count, 0)
    }
}
