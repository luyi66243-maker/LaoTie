import SwiftUI

struct SpeakingPracticeView: View {
    @StateObject private var viewModel = SpeakingPracticeViewModel()
    @State private var vocabularies: [Vocabulary] = []
    @State private var currentIndex = 0

    private let vocabRepo = VocabularyRepository()

    var body: some View {
        NavigationStack {
            ZStack {
                DongbeiColors.pageBackground.ignoresSafeArea()

                if vocabularies.isEmpty {
                    emptyState
                } else {
                    mainContent
                }
            }
            .navigationTitle("跟读练习")
            .task { await loadData() }
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("暂无练习内容")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if currentIndex < vocabularies.count {
            let vocab = vocabularies[currentIndex]
            VStack(spacing: Theme.spacingLG) {
            // Progress
            HStack {
                Text("\(currentIndex + 1) / \(vocabularies.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, Theme.spacingMD)

            Spacer()

            // Target phrase
            VStack(spacing: Theme.spacingSM) {
                Text("请跟读:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(vocab.exampleSentence)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(DongbeiColors.meihei)
                    .multilineTextAlignment(.center)

                Text(vocab.dongbeiPinyin)
                    .font(Theme.pinyinFont)
                    .foregroundStyle(.secondary)

                // Play reference audio
                HStack(spacing: Theme.spacingSM) {
                    Button {
                        viewModel.audioPlayer.playBundledAudioOrTTS(
                            fileName: vocab.audioFileName,
                            text: vocab.dongbeiWord,
                            style: .dongbei
                        )
                        HapticManager.impact(.light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("东北话")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.dahong)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DongbeiColors.dahong.opacity(0.1))
                        .clipShape(Capsule())
                    }

                    Button {
                        viewModel.audioPlayer.playBundledAudioOrTTS(
                            fileName: vocab.standardAudioFileName,
                            text: vocab.standardWord,
                            style: .standard
                        )
                        HapticManager.impact(.light)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("普通话")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.cuilu)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DongbeiColors.cuilu.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Waveform visualization
            if viewModel.isRecording {
                WaveformView(level: viewModel.recorder.audioLevel)
                    .frame(height: 60)
                    .padding(.horizontal, Theme.spacingXL)
            }

            // Score result
            if let score = viewModel.lastScore {
                ScoreResultView(score: score)
                    .transition(.scale.combined(with: .opacity))
            }

            // Record button
            recordButton

            // Navigation
            HStack {
                Button("上一个") {
                    if currentIndex > 0 {
                        currentIndex -= 1
                        viewModel.reset()
                    }
                }
                .disabled(currentIndex == 0)

                Spacer()

                Button("下一个") {
                    if currentIndex < vocabularies.count - 1 {
                        currentIndex += 1
                        viewModel.reset()
                    }
                }
                .disabled(currentIndex >= vocabularies.count - 1)
            }
            .font(.subheadline.bold())
            .foregroundStyle(DongbeiColors.dahong)
            .padding(.horizontal, Theme.spacingXL)
            .padding(.bottom, Theme.spacingMD)
            }
        } else {
            emptyState
        }
    }

    private var recordButton: some View {
        Button {
            if viewModel.isRecording {
                Task {
                    let targetText = currentIndex < vocabularies.count ? vocabularies[currentIndex].exampleSentence : ""
                    await viewModel.stopRecordingAndScore(target: targetText)
                }
            } else {
                Task { await viewModel.startRecording() }
            }
            HapticManager.impact(.medium)
        } label: {
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? DongbeiColors.dahong : DongbeiColors.dahong.opacity(0.15))
                    .frame(width: 80, height: 80)

                if viewModel.isRecording {
                    Circle()
                        .fill(DongbeiColors.dahong)
                        .frame(width: 80, height: 80)
                        .scaleEffect(1.0 + CGFloat(viewModel.recorder.audioLevel) * 0.3)
                        .opacity(0.3)
                }

                Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                    .font(.title)
                    .foregroundStyle(viewModel.isRecording ? .white : DongbeiColors.dahong)
            }
        }
        .padding(.vertical, Theme.spacingMD)
    }

    private func loadData() async {
        do {
            vocabularies = try await vocabRepo.fetchAll()
        } catch {
            // Keep empty
        }
    }
}

struct WaveformView: View {
    let level: Float
    @State private var bars: [CGFloat] = Array(repeating: 0.1, count: 20)

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<bars.count, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(DongbeiColors.dahong)
                    .frame(width: 4, height: max(4, bars[index] * 60))
            }
        }
        .onChange(of: level) { _ in
            withAnimation(.easeOut(duration: 0.05)) {
                bars.removeFirst()
                bars.append(CGFloat(level))
            }
        }
    }
}

struct ScoreResultView: View {
    let score: PronunciationScore

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            Text(score.grade.emoji)
                .font(.system(size: 48))

            Text("\(score.score)分")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(scoreColor)

            Text(score.grade.rawValue)
                .font(.headline.bold())
                .foregroundStyle(scoreColor)

            if !score.recognized.isEmpty {
                Text("识别结果: \(score.recognized)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.spacingLG)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var scoreColor: Color {
        switch score.grade {
        case .excellent: DongbeiColors.cuilu
        case .good: DongbeiColors.jinhuang
        case .fair: DongbeiColors.huabufen
        case .needsPractice: DongbeiColors.dahong
        }
    }
}

@MainActor
final class SpeakingPracticeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastScore: PronunciationScore?
    let recorder = AudioRecorderService()
    let audioPlayer = AudioPlayerService()
    private let speechService = SpeechRecognitionService()

    func startRecording() async {
        let authorized = await speechService.requestAuthorization()
        guard authorized else { return }
        let started = await recorder.startRecording()
        isRecording = started
    }

    func stopRecordingAndScore(target: String) async {
        guard let url = recorder.stopRecording() else { return }
        isRecording = false

        if let recognized = await speechService.recognizeFromFile(url: url) {
            withAnimation(.spring()) {
                lastScore = speechService.scorePronounciation(recognized: recognized, target: target)
            }

            if let score = lastScore {
                if score.grade == .excellent || score.grade == .good {
                    HapticManager.correctAnswer()
                } else {
                    HapticManager.wrongAnswer()
                }
            }
        }
    }

    func reset() {
        lastScore = nil
        isRecording = false
    }
}
