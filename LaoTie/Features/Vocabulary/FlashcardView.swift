import SwiftUI

struct FlashcardView: View {
    let vocabulary: Vocabulary
    @State private var isFlipped = false
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var dragOffset: CGSize = .zero
    @State private var showSRSButtons = false

    var body: some View {
        ZStack {
            DongbeiColors.pageBackground.ignoresSafeArea()

            VStack(spacing: Theme.spacingLG) {
                Spacer()

                // Card
                ZStack {
                    // Front side
                    cardFront
                        .opacity(isFlipped ? 0 : 1)
                        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                    // Back side
                    cardBack
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .onTapGesture {
                    withAnimation(.spring(duration: 0.5)) {
                        isFlipped.toggle()
                    }
                    if isFlipped {
                        withAnimation(.spring().delay(0.3)) {
                            showSRSButtons = true
                        }
                    } else {
                        showSRSButtons = false
                    }
                }

                // Hint
                if !isFlipped {
                    Text("点击卡片查看答案")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // SRS Buttons
                if showSRSButtons {
                    HStack(spacing: Theme.spacingMD) {
                        SRSButton(title: "不认识", emoji: "😵", color: DongbeiColors.dahong) {
                            HapticManager.wrongAnswer()
                            StreakService().recordLearning()
                            _ = DailyTaskService().addReviewSession()
                        }
                        SRSButton(title: "模糊", emoji: "🤔", color: DongbeiColors.jinhuang) {
                            HapticManager.selection()
                            StreakService().recordLearning()
                            _ = DailyTaskService().addReviewSession()
                        }
                        SRSButton(title: "认识", emoji: "😎", color: DongbeiColors.cuilu) {
                            HapticManager.correctAnswer()
                            StreakService().recordLearning()
                            _ = DailyTaskService().addReviewSession()
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
            .padding(Theme.spacingMD)
        }
        .navigationTitle("翻牌学习")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var cardFront: some View {
        VStack(spacing: Theme.spacingLG) {
            Text(vocabulary.category.rawValue)
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DongbeiColors.huabufen.opacity(0.15))
                .foregroundStyle(DongbeiColors.huabufen)
                .clipShape(Capsule())

            Spacer()

            Text(vocabulary.dongbeiWord)
                .font(Theme.dongbeiWordFont)
                .foregroundStyle(DongbeiColors.meihei)

            Text(vocabulary.dongbeiPinyin)
                .font(Theme.pinyinFont)
                .foregroundStyle(.secondary)

            Button {
                audioPlayer.playBundledAudioOrTTS(
                    fileName: vocabulary.audioFileName,
                    text: vocabulary.dongbeiWord,
                    style: .dongbei
                )
                HapticManager.impact(.light)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentAudioId == vocabulary.audioFileName ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                    Text("东北话")
                        .font(.caption2)
                }
                .foregroundStyle(DongbeiColors.dahong)
                .padding(.horizontal, Theme.spacingMD - 2)
                .padding(.vertical, Theme.spacingSM)
                .background(DongbeiColors.dahong.opacity(0.1))
                .clipShape(Capsule())
            }

            Button {
                audioPlayer.playBundledAudioOrTTS(
                    fileName: vocabulary.standardAudioFileName,
                    text: vocabulary.standardWord,
                    style: .standard
                )
                HapticManager.impact(.light)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: audioPlayer.isPlaying && audioPlayer.currentAudioId == vocabulary.standardAudioFileName ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.title3)
                    Text("普通话")
                        .font(.caption2)
                }
                .foregroundStyle(DongbeiColors.cuilu)
                .padding(.horizontal, Theme.spacingMD - 2)
                .padding(.vertical, Theme.spacingSM)
                .background(DongbeiColors.cuilu.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()

            Text(vocabulary.exampleSentence)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var cardBack: some View {
        VStack(spacing: Theme.spacingMD) {
            Text("普通话")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(DongbeiColors.cuilu.opacity(0.15))
                .foregroundStyle(DongbeiColors.cuilu)
                .clipShape(Capsule())

            Spacer()

            Text(vocabulary.standardWord)
                .font(Theme.largeTitleFont)
                .foregroundStyle(DongbeiColors.meihei)

            Text(vocabulary.pinyin)
                .font(Theme.pinyinFont)
                .foregroundStyle(.secondary)

            Divider().padding(.horizontal, Theme.spacingXL)

            Text(vocabulary.meaning)
                .font(.body)
                .foregroundStyle(DongbeiColors.meihei)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let funFact = vocabulary.funFact {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(DongbeiColors.jinhuang)
                        .font(.caption)
                    Text(funFact)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.spacingSM)
                .background(DongbeiColors.jinhuang.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            }

            Spacer()

            Text(vocabulary.exampleTranslation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingXL)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }
}

struct SRSButton: View {
    let title: String
    let emoji: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.spacingMD - 4)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        }
    }
}
