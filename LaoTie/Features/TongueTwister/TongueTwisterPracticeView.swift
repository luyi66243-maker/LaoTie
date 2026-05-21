import SwiftUI

struct TongueTwisterPracticeView: View {
    let twister: TongueTwister
    let allTwisters: [TongueTwister]

    @StateObject private var viewModel = TongueTwisterPracticeViewModel()
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DongbeiColors.pageBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    // Progress indicator
                    progressBar

                    // Twister content card
                    twisterContentCard

                    // Tip card
                    tipCard

                    // Waveform
                    if viewModel.isRecording {
                        WaveformView(level: viewModel.recorder.audioLevel)
                            .frame(height: 60)
                            .padding(.horizontal, Theme.spacingXL)
                    }

                    // Score result
                    if let score = viewModel.lastScore {
                        scoreResultCard(score: score)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Recognized text
                    if let recognized = viewModel.recognizedText, !recognized.isEmpty {
                        recognizedTextCard(recognized)
                    }

                    // Record button
                    recordButton

                    // Navigation
                    navigationButtons
                }
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingMD)
            }
        }
        .navigationTitle(currentTwister.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let idx = allTwisters.firstIndex(where: { $0.id == twister.id }) {
                currentIndex = idx
            }
        }
    }

    private var currentTwister: TongueTwister {
        guard currentIndex >= 0, currentIndex < allTwisters.count else { return twister }
        return allTwisters[currentIndex]
    }

    // MARK: - Progress

    private var progressBar: some View {
        HStack {
            Text("\(currentIndex + 1) / \(allTwisters.count)")
                .font(Theme.captionFont.bold())
                .foregroundStyle(.secondary)

            Spacer()

            // Difficulty
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: i < currentTwister.difficulty ? "star.fill" : "star")
                        .font(.caption2)
                        .foregroundStyle(i < currentTwister.difficulty ? DongbeiColors.jinhuang : .gray.opacity(0.3))
                }
            }
        }
    }

    // MARK: - Content Card

    private var twisterContentCard: some View {
        VStack(spacing: Theme.spacingMD) {
            Text(currentTwister.content)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DongbeiColors.meihei)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .dongbeiCard(padding: Theme.spacingLG)
    }

    // MARK: - Tip

    private var tipCard: some View {
        HStack(alignment: .top, spacing: Theme.spacingSM) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(DongbeiColors.jinhuang)
                .font(.body)

            VStack(alignment: .leading, spacing: 4) {
                Text("发音技巧")
                    .font(Theme.labelFont)
                    .foregroundStyle(DongbeiColors.jinhuang)
                Text(currentTwister.tip)
                    .font(Theme.captionFont)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(Theme.spacingMD)
        .background(DongbeiColors.jinhuang.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    // MARK: - Score

    private func scoreResultCard(score: PronunciationScore) -> some View {
        VStack(spacing: Theme.spacingSM) {
            Text(score.grade.emoji)
                .font(.system(size: 48))

            Text("\(score.score)分")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(scoreColor(for: score.grade))

            Text(score.grade.rawValue)
                .font(.headline.bold())
                .foregroundStyle(scoreColor(for: score.grade))
        }
        .frame(maxWidth: .infinity)
        .dongbeiCard(padding: Theme.spacingLG)
    }

    private func scoreColor(for grade: PronunciationScore.Grade) -> Color {
        switch grade {
        case .excellent: DongbeiColors.cuilu
        case .good: DongbeiColors.jinhuang
        case .fair: DongbeiColors.huabufen
        case .needsPractice: DongbeiColors.dahong
        }
    }

    // MARK: - Recognized Text

    private func recognizedTextCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("你读的是:")
                .font(Theme.labelFont)
                .foregroundStyle(.secondary)
            Text(text)
                .font(Theme.bodyFont)
                .foregroundStyle(DongbeiColors.meihei)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dongbeiCard()
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            if viewModel.isRecording {
                Task {
                    await viewModel.stopRecordingAndScore(target: currentTwister.content)
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
        .padding(.vertical, Theme.spacingSM)
    }

    // MARK: - Navigation

    private var navigationButtons: some View {
        HStack {
            Button {
                if currentIndex > 0 {
                    withAnimation { currentIndex -= 1 }
                    viewModel.reset()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("上一个")
                }
            }
            .disabled(currentIndex == 0)

            Spacer()

            Button {
                if currentIndex < allTwisters.count - 1 {
                    withAnimation { currentIndex += 1 }
                    viewModel.reset()
                }
            } label: {
                HStack(spacing: 4) {
                    Text("下一个")
                    Image(systemName: "chevron.right")
                }
            }
            .disabled(currentIndex >= allTwisters.count - 1)
        }
        .font(.subheadline.bold())
        .foregroundStyle(DongbeiColors.dahong)
        .padding(.horizontal, Theme.spacingMD)
        .padding(.bottom, Theme.spacingMD)
    }
}

// MARK: - ViewModel

@MainActor
final class TongueTwisterPracticeViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastScore: PronunciationScore?
    @Published var recognizedText: String?
    let recorder = AudioRecorderService()
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
            recognizedText = recognized
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
        recognizedText = nil
        isRecording = false
    }
}
