import AVFoundation
import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "AudioPlayer")

/// Audio playback style — dongbei dialect gets warmth/depth processing.
enum AudioPlaybackStyle: Sendable {
    case standard
    case dongbei
}

struct AudioPreflightReport: Sendable {
    var bundledAudioCount: Int
    var localTTSAvailable: Bool
    var cloudTTSEnabled: Bool
    var cloudTTSConfigured: Bool
    var suggestions: [String]
}

@MainActor
final class AudioPlayerService: ObservableObject {
    private static let showFallbackToastKey = "laotie_audio_show_fallback_toast"
    private static let lastFailureReasonKey = "laotie_audio_last_failure_reason"
    private static let lastFailureAtKey = "laotie_audio_last_failure_at"

    static var isFallbackToastEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: showFallbackToastKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: showFallbackToastKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: showFallbackToastKey) }
    }

    struct FailureDiagnostics: Sendable {
        var reason: String?
        var happenedAt: Date?
    }

    static func latestFailureDiagnostics() -> FailureDiagnostics {
        let reason = UserDefaults.standard.string(forKey: lastFailureReasonKey)
        let timestamp = UserDefaults.standard.double(forKey: lastFailureAtKey)
        let date = timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        return FailureDiagnostics(reason: reason, happenedAt: date)
    }

    @Published var isPlaying = false
    @Published var currentAudioId: String?

    private var audioPlayer: AVAudioPlayer?
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var timePitchNode: AVAudioUnitTimePitch?
    private var reverbNode: AVAudioUnitReverb?
    private var eqNode: AVAudioUnitEQ?
    private let cacheDirectory: URL
    private let ttsService = DongbeiTTSService()
    private var bundledAudioURLCache: [String: URL] = [:]

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("AudioCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("Audio session configuration failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    func playBundledAudio(
        named fileName: String,
        style: AudioPlaybackStyle = .standard,
        playbackId: String? = nil
    ) {
        guard let url = bundledAudioURL(named: fileName) else {
            logger.warning("Audio file not found: \(fileName)")
            Self.recordFailure(reason: "本地音频文件缺失：\(fileName)")
            return
        }
        let id = playbackId ?? fileName

        switch style {
        case .dongbei:
            playWithEngine(url: url, id: id)
        case .standard:
            playSimple(url: url, id: id)
        }
    }

    func playBundledAudioOrTTS(
        fileName: String?,
        text: String,
        style: AudioPlaybackStyle = .standard,
        playbackId: String? = nil,
        onFallbackToTTS: (() -> Void)? = nil,
        onPlaybackFailed: (() -> Void)? = nil
    ) {
        let id = playbackId ?? fileName ?? text
        if let fileName = fileName, !fileName.isEmpty {
            if bundledAudioURL(named: fileName) != nil {
                playBundledAudio(named: fileName, style: style, playbackId: id)
                return
            }
        }
        onFallbackToTTS?()
        stop()
        isPlaying = true
        currentAudioId = id
        Task { @MainActor in
            let started = await ttsService.speakWord(text, isDongbei: style == .dongbei)
            if !started {
                self.isPlaying = false
                self.currentAudioId = nil
                let reason = self.diagnoseTTSFailure()
                Self.recordFailure(reason: reason)
                onPlaybackFailed?()
                return
            }
            // Wait for TTS completion to drive button state
            if ttsService.isSpeaking {
                while ttsService.isSpeaking {
                    try? await Task.sleep(for: .seconds(0.15))
                }
            } else {
                try? await Task.sleep(for: .seconds(0.35))
            }
            if self.currentAudioId == id {
                self.isPlaying = false
                self.currentAudioId = nil
            }
        }
    }

    func playCachedOrRemote(fileName: String, remoteURL: URL, style: AudioPlaybackStyle = .standard) async {
        let localURL = cacheDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: localURL.path) {
            switch style {
            case .dongbei:
                playWithEngine(url: localURL, id: fileName)
            case .standard:
                playSimple(url: localURL, id: fileName)
            }
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
            switch style {
            case .dongbei:
                playWithEngine(url: localURL, id: fileName)
            case .standard:
                playSimple(url: localURL, id: fileName)
            }
        } catch {
            logger.error("Failed to download audio: \(error.localizedDescription)")
            Self.recordFailure(reason: "远程音频下载失败：\(error.localizedDescription)")
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playerNode?.stop()
        engine?.stop()
        engine = nil
        playerNode = nil
        timePitchNode = nil
        reverbNode = nil
        eqNode = nil
        ttsService.stop()
        isPlaying = false
        currentAudioId = nil
    }

    // MARK: - Simple playback (standard Chinese)

    private func playSimple(url: URL, id: String) {
        stop()
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
            currentAudioId = id

            let duration = audioPlayer?.duration ?? 0
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                if self.currentAudioId == id {
                    self.isPlaying = false
                    self.currentAudioId = nil
                }
            }
        } catch {
            logger.error("Failed to play audio: \(error.localizedDescription)")
            Self.recordFailure(reason: "音频播放失败：\(error.localizedDescription)")
        }
    }

    // MARK: - Bundle URL resolve

    private func bundledAudioURL(named fileName: String) -> URL? {
        if let cached = bundledAudioURLCache[fileName] {
            return cached
        }

        // Fast path: direct lookup in bundle root
        for ext in ["m4a", "mp3", "wav"] {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                bundledAudioURLCache[fileName] = url
                return url
            }
        }

        // Fallback: scan all audio files in bundle subdirectories once needed
        for ext in ["m4a", "mp3", "wav"] {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil),
               let matched = urls.first(where: { $0.deletingPathExtension().lastPathComponent == fileName }) {
                bundledAudioURLCache[fileName] = matched
                return matched
            }
        }
        return nil
    }

    // MARK: - Diagnostics

    static func runPreflight() -> AudioPreflightReport {
        let audioCount = (Bundle.main.urls(forResourcesWithExtension: "m4a", subdirectory: nil) ?? []).count
            + (Bundle.main.urls(forResourcesWithExtension: "mp3", subdirectory: nil) ?? []).count
            + (Bundle.main.urls(forResourcesWithExtension: "wav", subdirectory: nil) ?? []).count

        let localAvailable = AVSpeechSynthesisVoice(language: "zh-CN") != nil
        let cloudEnabled = VolcanoTTSService.isEnabled
        let cloudConfigured = VolcanoTTSService.isConfigured

        var suggestions: [String] = []
        if audioCount == 0 {
            suggestions.append("未扫描到本地音频文件，建议先补充核心词条音频资源。")
        }
        if !localAvailable {
            suggestions.append("系统本地中文语音不可用，建议在系统设置中下载中文语音。")
        }
        if cloudEnabled && !cloudConfigured {
            suggestions.append("已启用云端语音但未配置凭证，请填写 App ID 和 Token。")
        }
        if !cloudEnabled {
            suggestions.append("当前仅使用本地语音，若需更地道音色可启用云端语音。")
        }
        if suggestions.isEmpty {
            suggestions.append("音频链路状态良好，可正常播放与降级。")
        }

        return AudioPreflightReport(
            bundledAudioCount: audioCount,
            localTTSAvailable: localAvailable,
            cloudTTSEnabled: cloudEnabled,
            cloudTTSConfigured: cloudConfigured,
            suggestions: suggestions
        )
    }

    private func diagnoseTTSFailure() -> String {
        if let cloudReason = VolcanoTTSService.latestFailureDiagnostics().reason, !cloudReason.isEmpty {
            return cloudReason
        }
        if !VolcanoTTSService.isEnabled && AVSpeechSynthesisVoice(language: "zh-CN") == nil {
            return "本地语音不可用，且云端语音未启用。"
        }
        if VolcanoTTSService.isEnabled && !VolcanoTTSService.isConfigured && AVSpeechSynthesisVoice(language: "zh-CN") == nil {
            return "云端语音缺少凭证，同时本地语音不可用。"
        }
        if VolcanoTTSService.isEnabled && !VolcanoTTSService.isConfigured {
            return "云端语音已启用但凭证未配置。"
        }
        return "语音引擎启动失败，请稍后重试。"
    }

    private static func recordFailure(reason: String) {
        UserDefaults.standard.set(reason, forKey: lastFailureReasonKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFailureAtKey)
    }

    // MARK: - Engine playback with natural voice processing (dongbei)

    private func playWithEngine(url: URL, id: String) {
        stop()

        do {
            let audioFile = try AVAudioFile(forReading: url)
            let format = audioFile.processingFormat

            let eng = AVAudioEngine()
            let player = AVAudioPlayerNode()

            // TimePitch: slight pitch lowering + natural rate for dongbei warmth
            let timePitch = AVAudioUnitTimePitch()
            // Lower pitch by ~0.8 semitones — gives a warmer, deeper dongbei voice feel
            timePitch.pitch = Float.random(in: -100 ... -60)
            // Slightly slower for a more deliberate, expressive dongbei cadence
            timePitch.rate = Float.random(in: 0.92 ... 0.97)

            // Reverb: subtle room feel to remove sterile TTS quality
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(.smallRoom)
            reverb.wetDryMix = Float.random(in: 12 ... 18)

            // Build audio graph: player -> timePitch -> reverb -> mainMixer
            // Simplified audio graph without EQ to avoid potential crashes
            eng.attach(player)
            eng.attach(timePitch)
            eng.attach(reverb)

            eng.connect(player, to: timePitch, format: format)
            eng.connect(timePitch, to: reverb, format: format)
            eng.connect(reverb, to: eng.mainMixerNode, format: format)

            try eng.start()

            player.scheduleFile(audioFile, at: nil) { [weak self] in
                // Callback when playback finishes
                Task { @MainActor in
                    if self?.currentAudioId == id {
                        self?.stop()
                    }
                }
            }
            player.play()

            self.engine = eng
            self.playerNode = player
            self.timePitchNode = timePitch
            self.reverbNode = reverb
            isPlaying = true
            currentAudioId = id

        } catch {
            logger.error("Failed to play with engine: \(error.localizedDescription)")
            Self.recordFailure(reason: "方言音色引擎启动失败，已尝试标准播放：\(error.localizedDescription)")
            // Fall back to simple playback
            playSimple(url: url, id: id)
        }
    }
}
