import AVFoundation
import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "DongbeiTTS")

/// Speaks dongbei-flavored encouragement/praise.
/// Uses Volcano Engine "东北老铁" cloud TTS when configured, otherwise falls back to local AVSpeechSynthesizer.
@MainActor
final class DongbeiTTSService: ObservableObject {
    @Published var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private let delegate = TTSDelegate()
    private let volcanoTTS = VolcanoTTSService()

    init() {
        synthesizer.delegate = delegate
    }

    // MARK: - Praise phrases (闯关成功)

    static let praiseOnPass: [String] = [
        "老铁，你也太牛了吧！杠杠的！",
        "哎呀妈呀，满分啊！贼厉害！",
        "铁子，你这脑瓜子，嘎嘎好使啊！",
        "整得漂亮！你就是东北话小天才！",
        "嗯哪！答的贼好，必须给你点个赞！",
        "老铁没毛病！这关被你拿捏了！",
        "哇塞，你这水平，可以去东北当翻译了！",
        "厉害了我的铁子！一路过关斩将！",
        "不得不说，你是真有尿性！佩服！",
        "稀罕你啊老铁，答的太棒了！",
        "你这是开挂了吧？整得明明白白！",
        "铁子，我看好你，继续往前冲！",
    ]

    static let praiseOnGoodScore: [String] = [
        "不错不错，铁子有两下子啊！",
        "嗯哪，过关了！继续保持！",
        "整挺好！再接再厉铁子！",
        "杠杠的！过了就是胜利！",
        "你小子可以啊，东北话学得挺溜！",
        "过关了老铁！来来来，唠两块钱的！",
        "行啊铁子，这水平可以的！",
        "嘎嘎好！加把劲儿冲满分！",
    ]

    // MARK: - Encouragement phrases (答题答错)

    static let encourageOnWrong: [String] = [
        "没事儿铁子，这题确实有点难整！",
        "别灰心老铁，谁还没答错过呢！",
        "拉倒拉倒，下道题咱整回来！",
        "这不算啥，练练就会了，再来！",
        "哎呀，差一丢丢！下次准能整对！",
        "铁子别慌，东北话本来就不好整！",
        "没事儿，错了才能记住，继续造！",
        "嗯哪，这个容易搞混，下次就记住了！",
        "别泄气铁子，你已经很厉害了！",
        "没关系，老铁，学习哪有不犯错的！",
        "这题坑人，不怪你，咱下题整回来！",
        "加油铁子！失败是成功他妈！",
    ]

    // MARK: - Fail encouragement (闯关失败)

    static let encourageOnFail: [String] = [
        "铁子别上火，回去再练练，下次准过！",
        "差一点点儿！再来一次肯定行！",
        "没事儿老铁，东北话这玩意儿得慢慢整！",
        "拉倒吧这次，回去好好唠唠，下次过！",
        "别磕碜，学东西哪有一次就成的！",
        "铁子，这才哪到哪，再整一回！",
        "没过就没过呗，天塌不下来，再来！",
        "别灰心，你比上次进步老多了！",
    ]

    // MARK: - Public API

    func speakPraise(passed: Bool, score: Int) {
        let phrases: [String]
        if !passed {
            phrases = Self.encourageOnFail
        } else if score >= 90 {
            phrases = Self.praiseOnPass
        } else {
            phrases = Self.praiseOnGoodScore
        }
        if let phrase = phrases.randomElement() {
            speakWithBestEngine(phrase)
        }
    }

    func speakWrongAnswer() {
        speakWithBestEngine(Self.encourageOnWrong.randomElement() ?? "没事儿铁子，这题确实有点难整！")
    }

    func speakCorrectAnswer() {
        let quickPraise = [
            "嗯哪！对了！", "杠杠的！", "整对了！", "贼棒！",
            "没毛病！", "稀罕你！", "可以啊铁子！", "厉害了！",
        ]
        speakWithBestEngine(quickPraise.randomElement() ?? "嗯哪！对了！")
    }

    func speakWord(_ word: String, isDongbei: Bool) async -> Bool {
        if isDongbei && VolcanoTTSService.isEnabled, VolcanoTTSService.isConfigured {
            let cloudStarted = await volcanoTTS.speak(word)
            if cloudStarted { return true }
            return speakLocal(word)
        } else {
            return speakLocal(word)
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        volcanoTTS.stop()
        isSpeaking = false
    }

    // MARK: - Engine selection

    private func speakWithBestEngine(_ text: String) {
        stop()
        isSpeaking = true

        if VolcanoTTSService.isEnabled, VolcanoTTSService.isConfigured {
            // Use cloud dongbei TTS
            Task { @MainActor in
                _ = await volcanoTTS.speak(text)
                self.isSpeaking = volcanoTTS.isSpeaking
                // Monitor completion
                while volcanoTTS.isSpeaking {
                    try? await Task.sleep(for: .seconds(0.2))
                }
                self.isSpeaking = false
            }
        } else {
            // Fallback to local AVSpeechSynthesizer
            _ = speakLocal(text)
        }
    }

    // MARK: - Local TTS fallback

    func speakLocal(_ text: String) -> Bool {
        guard AVSpeechSynthesisVoice(language: "zh-CN") != nil else {
            isSpeaking = false
            return false
        }
        isSpeaking = true
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.pitchMultiplier = Float.random(in: 0.88...0.95)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * Float.random(in: 0.88...0.95)
        utterance.preUtteranceDelay = 0.15
        utterance.volume = 1.0

        delegate.onFinish = { [weak self] in
            Task { @MainActor in
                self?.isSpeaking = false
            }
        }

        synthesizer.speak(utterance)
        return true
    }
}

// MARK: - Delegate

private class TTSDelegate: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    var onFinish: (() -> Void)?

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish?()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        onFinish?()
    }
}
