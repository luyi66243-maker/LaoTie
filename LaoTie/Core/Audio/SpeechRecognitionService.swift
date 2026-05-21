import Speech
import Foundation

@MainActor
final class SpeechRecognitionService: ObservableObject {
    @Published var isRecognizing = false
    @Published var recognizedText = ""
    @Published var error: String?

    private let speechRecognizer: SFSpeechRecognizer? = {
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
        if recognizer == nil {
            print("[SpeechRecognitionService] Failed to create SFSpeechRecognizer for zh-CN, falling back to default")
        }
        return recognizer ?? SFSpeechRecognizer()
    }()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func recognizeFromFile(url: URL) async -> String? {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            error = "语音识别不可用"
            return nil
        }

        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false

        return await withCheckedContinuation { continuation in
            recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, err in
                if let err {
                    self?.error = err.localizedDescription
                    continuation.resume(returning: nil)
                    return
                }
                if let result, result.isFinal {
                    let text = result.bestTranscription.formattedString
                    self?.recognizedText = text
                    continuation.resume(returning: text)
                }
            }
        }
    }

    func scorePronounciation(recognized: String, target: String) -> PronunciationScore {
        let cleanRecognized = normalized(recognized)
        let cleanTarget = normalized(target)

        let distance = levenshteinDistance(cleanRecognized, cleanTarget)
        let maxLen = max(cleanRecognized.count, cleanTarget.count, 1)
        let similarity = 1.0 - (Double(distance) / Double(maxLen))
        let rawScore = Int(similarity * 100)
        let score = max(0, min(100, rawScore))

        let grade: PronunciationScore.Grade = switch score {
        case 90...100: .excellent
        case 70..<90: .good
        case 50..<70: .fair
        default: .needsPractice
        }

        return PronunciationScore(score: score, grade: grade, recognized: recognized, target: target)
    }

    private func normalized(_ text: String) -> String {
        text.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "，", with: "")
            .replacingOccurrences(of: "。", with: "")
            .replacingOccurrences(of: "！", with: "")
            .replacingOccurrences(of: "？", with: "")
    }

    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)

        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }

        for i in 1...m {
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,       // deletion
                    matrix[i][j - 1] + 1,       // insertion
                    matrix[i - 1][j - 1] + cost  // substitution
                )
            }
        }

        return matrix[m][n]
    }
}

struct PronunciationScore: Sendable {
    let score: Int
    let grade: Grade
    let recognized: String
    let target: String

    enum Grade: String, Sendable {
        case excellent = "优秀"
        case good = "不错"
        case fair = "加油"
        case needsPractice = "再来一次"

        var emoji: String {
            switch self {
            case .excellent: "🌟"
            case .good: "👍"
            case .fair: "💪"
            case .needsPractice: "🔄"
            }
        }
    }
}
