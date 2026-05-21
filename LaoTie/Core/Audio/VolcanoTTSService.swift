import AVFoundation
import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "VolcanoTTS")

/// Volcano Engine (火山引擎) TTS service with "东北老铁" voice (BV021_streaming).
/// API docs: https://www.volcengine.com/docs/6561/1257584
@MainActor
final class VolcanoTTSService: ObservableObject {
    @Published var isSpeaking = false

    // MARK: - Config keys in UserDefaults

    private static let appIdKey = "volcano_tts_appid"
    private static let tokenKey = "volcano_tts_token"
    private static let enabledKey = "volcano_tts_enabled"
    private static let cacheHitKey = "volcano_tts_cache_hit_count"
    private static let cacheMissKey = "volcano_tts_cache_miss_count"
    private static let lastCacheClearKey = "volcano_tts_cache_last_clear_at"
    private static let lastFailureReasonKey = "volcano_tts_last_failure_reason"
    private static let lastFailureAtKey = "volcano_tts_last_failure_at"

    // Dongbei voice type
    private static let voiceType = "BV021_streaming"
    private static let cluster = "volcano_tts"
    private static let apiURL = "https://openspeech.bytedance.com/api/v1/tts"

    private var audioPlayer: AVAudioPlayer?
    private let cacheDir: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDir = caches.appendingPathComponent("VolcanoTTSCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    // MARK: - Config

    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    static var appId: String {
        get { UserDefaults.standard.string(forKey: appIdKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: appIdKey) }
    }

    static var token: String {
        get { UserDefaults.standard.string(forKey: tokenKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    static var isConfigured: Bool {
        !appId.isEmpty && !token.isEmpty
    }

    struct CacheDiagnostics: Sendable {
        var hitCount: Int
        var missCount: Int
        var hitRate: Double
        var lastClearedAt: Date?
    }

    struct FailureDiagnostics: Sendable {
        var reason: String?
        var happenedAt: Date?
    }

    static func cacheDiagnostics() -> CacheDiagnostics {
        let hit = UserDefaults.standard.integer(forKey: cacheHitKey)
        let miss = UserDefaults.standard.integer(forKey: cacheMissKey)
        let total = max(hit + miss, 1)
        let rate = Double(hit) / Double(total)
        let ts = UserDefaults.standard.double(forKey: lastCacheClearKey)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        return CacheDiagnostics(hitCount: hit, missCount: miss, hitRate: rate, lastClearedAt: date)
    }

    static func latestFailureDiagnostics() -> FailureDiagnostics {
        let reason = UserDefaults.standard.string(forKey: lastFailureReasonKey)
        let ts = UserDefaults.standard.double(forKey: lastFailureAtKey)
        let date = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
        return FailureDiagnostics(reason: reason, happenedAt: date)
    }

    // MARK: - Public API

    /// Synthesize text and play with dongbei voice. Falls back to local TTS if not configured.
    func speak(_ text: String) async -> Bool {
        stop()
        isSpeaking = true

        // Check cache first
        let cacheKey = text.hashValue
        let cacheFile = cacheDir.appendingPathComponent("\(cacheKey).mp3")
        if FileManager.default.fileExists(atPath: cacheFile.path) {
            Self.incrementCounter(for: Self.cacheHitKey)
            playAudioFile(cacheFile)
            return true
        }

        guard Self.isEnabled, Self.isConfigured else {
            Self.recordFailure(reason: "云端语音未启用或凭证未配置。")
            isSpeaking = false
            return false
        }

        do {
            let audioData = try await requestTTS(text: text)
            try audioData.write(to: cacheFile)
            Self.incrementCounter(for: Self.cacheMissKey)
            playAudioFile(cacheFile)
            return true
        } catch {
            let message = error.localizedDescription
            logger.error("Volcano TTS failed: \(message)")
            Self.recordFailure(reason: "云端语音请求失败：\(message)")
            isSpeaking = false
            return false
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isSpeaking = false
    }

    /// Clear all cached TTS audio
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        UserDefaults.standard.set(0, forKey: Self.cacheHitKey)
        UserDefaults.standard.set(0, forKey: Self.cacheMissKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.lastCacheClearKey)
    }

    private static func incrementCounter(for key: String) {
        let value = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(value, forKey: key)
    }

    private static func recordFailure(reason: String) {
        UserDefaults.standard.set(reason, forKey: lastFailureReasonKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFailureAtKey)
    }

    // MARK: - Network

    private func requestTTS(text: String) async throws -> Data {
        let reqId = UUID().uuidString

        let body: [String: Any] = [
            "app": [
                "appid": Self.appId,
                "token": "access_token",
                "cluster": Self.cluster
            ],
            "user": [
                "uid": "laotie_app_user"
            ],
            "audio": [
                "voice_type": Self.voiceType,
                "encoding": "mp3",
                "speed_ratio": 1.0,
                "volume_ratio": 1.0,
                "pitch_ratio": 1.0
            ],
            "request": [
                "reqid": reqId,
                "text": text,
                "text_type": "plain",
                "operation": "query"
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: body)

        guard let url = URL(string: Self.apiURL) else {
            throw VolcanoTTSError.httpError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer;\(Self.token)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VolcanoTTSError.httpError
        }

        // Parse response JSON
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? Int else {
            throw VolcanoTTSError.parseError
        }

        guard code == 3000 else {
            let message = json["message"] as? String ?? "Unknown error"
            logger.error("Volcano TTS API error: code=\(code) message=\(message)")
            throw VolcanoTTSError.apiError(code: code, message: message)
        }

        guard let base64Audio = json["data"] as? String,
              let audioData = Data(base64Encoded: base64Audio) else {
            throw VolcanoTTSError.noAudioData
        }

        return audioData
    }

    // MARK: - Playback

    private func playAudioFile(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            let duration = audioPlayer?.duration ?? 0
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(duration + 0.1))
                self.isSpeaking = false
            }
        } catch {
            logger.error("Failed to play TTS audio: \(error.localizedDescription)")
            Self.recordFailure(reason: "云端语音播放失败：\(error.localizedDescription)")
            isSpeaking = false
        }
    }
}

// MARK: - Errors

enum VolcanoTTSError: LocalizedError {
    case httpError
    case parseError
    case apiError(code: Int, message: String)
    case noAudioData

    var errorDescription: String? {
        switch self {
        case .httpError: "网络请求失败"
        case .parseError: "响应解析失败"
        case .apiError(_, let message): "API错误: \(message)"
        case .noAudioData: "未返回音频数据"
        }
    }
}
