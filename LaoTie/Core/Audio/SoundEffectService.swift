import AVFoundation

class SoundEffectService: @unchecked Sendable {
    static let shared = SoundEffectService()
    private var audioPlayer: AVAudioPlayer?

    enum SoundEffect: String {
        case buttonTap = "button_tap"
        case correct = "correct"
        case wrong = "wrong"
        case achievement = "achievement"
        case streak = "streak"
    }

    func play(_ effect: SoundEffect) {
        // 尝试从 Bundle 加载音频文件
        // 如果文件不存在，静默失败（音效文件后续可以添加）
        guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") ??
              Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else {
            return // 音频文件不存在时静默失败
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            print("音效播放失败: \(error)")
        }
    }
}
