import AVFoundation
import Foundation
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "AudioRecorder")

@MainActor
final class AudioRecorderService: ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private(set) var lastRecordingURL: URL?

    func startRecording() async -> Bool {
        let permission = await requestPermission()
        guard permission else { return false }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement)
            try AVAudioSession.sharedInstance().setActive(true)

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            lastRecordingURL = url
            isRecording = true
            startLevelMonitoring()
            return true
        } catch {
            logger.error("Recording failed: \(error.localizedDescription)")
            return false
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        stopLevelMonitoring()

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)

        return lastRecordingURL
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let recorder = self.audioRecorder else { return }
                recorder.updateMeters()
                let level = recorder.averagePower(forChannel: 0)
                let normalized = max(0, (level + 50) / 50)
                self.audioLevel = normalized
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
        audioLevel = 0
    }
}
