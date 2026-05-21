import SwiftUI

struct QuizPlayView: View {
    let level: QuizLevel
    var onLevelPassed: ((String) -> Void)?
    @EnvironmentObject private var appState: AppState
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var isAnswered = false
    @State private var correctCount = 0
    @State private var showResult = false
    @State private var resultSaved = false
    @StateObject private var audioPlayer = AudioPlayerService()
    @StateObject private var tts = DongbeiTTSService()
    @State private var dongbeiFeedback: String?
    @State private var dongbeiResultPhrase: String?
    @Environment(\.dismiss) private var dismiss
    private let progressRepo = ProgressRepository()
    private let confusingWordsRepo = ConfusingWordsRepository()

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < level.questions.count else { return nil }
        return level.questions[currentIndex]
    }

    var body: some View {
        ZStack {
            DongbeiColors.pageBackground.ignoresSafeArea()

            if showResult {
                quizResultView
            } else if let question = currentQuestion {
                questionView(question)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("退出") { dismiss() }
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(spacing: Theme.spacingLG) {
            // Progress header
            VStack(spacing: Theme.spacingSM) {
                HStack {
                    Text("第 \(currentIndex + 1) / \(level.questions.count) 题")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(correctCount) 对")
                        .font(.caption.bold())
                        .foregroundStyle(DongbeiColors.cuilu)
                }

                ProgressView(value: Double(currentIndex), total: Double(level.questions.count))
                    .tint(DongbeiColors.dahong)
            }
            .padding(.horizontal, Theme.spacingMD)

            Spacer()

            // Question prompt
            VStack(spacing: Theme.spacingMD) {
                if question.type == .listening, let fileName = question.audioFileName {
                    Button {
                        audioPlayer.playBundledAudio(named: fileName, style: .dongbei)
                        HapticManager.impact(.light)
                    } label: {
                        VStack(spacing: Theme.spacingSM) {
                            Image(systemName: "speaker.wave.2.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(DongbeiColors.dahong)
                            Text("点击播放")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Text(question.prompt)
                    .font(.title3.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingMD)
            }

            Spacer()

            // Options
            if let options = question.options {
                VStack(spacing: Theme.spacingSM) {
                    ForEach(options, id: \.self) { option in
                        OptionButton(
                            text: option,
                            isSelected: selectedAnswer == option,
                            isCorrect: option == question.correctAnswer,
                            isRevealed: isAnswered
                        ) {
                            guard !isAnswered else { return }
                            selectedAnswer = option
                            isAnswered = true
                            _ = DailyTaskService().addQuizAnswered()

                            if option == question.correctAnswer {
                                correctCount += 1
                                HapticManager.correctAnswer()
                                tts.speakCorrectAnswer()
                                dongbeiFeedback = [
                                    "嗯哪！对了！", "杠杠的！", "整对了！", "贼棒！",
                                    "没毛病！", "稀罕你！", "可以啊铁子！", "厉害了！",
                                ].randomElement()
                            } else {
                                HapticManager.wrongAnswer()
                                confusingWordsRepo.recordWrongAnswer(
                                    question: question,
                                    selectedAnswer: option,
                                    level: level
                                )
                                let phrase = DongbeiTTSService.encourageOnWrong.randomElement() ?? "继续加油!"
                                dongbeiFeedback = phrase
                                tts.speakWrongAnswer()
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.spacingMD)
            }

            // Explanation + dongbei feedback
            if isAnswered {
                VStack(spacing: Theme.spacingSM) {
                    // Dongbei feedback bubble
                    if let feedback = dongbeiFeedback {
                        HStack(spacing: 6) {
                            Image(systemName: tts.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundStyle(selectedAnswer == currentQuestion?.correctAnswer ? DongbeiColors.cuilu : DongbeiColors.dahong)
                                .symbolEffectCompat(isActive: tts.isSpeaking)
                            Text(feedback)
                                .font(.subheadline.bold())
                                .foregroundStyle(selectedAnswer == currentQuestion?.correctAnswer ? DongbeiColors.cuilu : DongbeiColors.dahong)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            (selectedAnswer == currentQuestion?.correctAnswer ? DongbeiColors.cuilu : DongbeiColors.dahong).opacity(0.1)
                        )
                        .clipShape(Capsule())
                    }

                    Text(question.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.spacingMD)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Next button
            if isAnswered {
                DongbeiButton(
                    title: currentIndex < level.questions.count - 1 ? "下一题" : "查看结果",
                    icon: currentIndex < level.questions.count - 1 ? "arrow.right" : "trophy.fill"
                ) {
                    if currentIndex < level.questions.count - 1 {
                        tts.stop()
                        currentIndex += 1
                        selectedAnswer = nil
                        isAnswered = false
                        dongbeiFeedback = nil
                    } else {
                        withAnimation(.spring()) {
                            showResult = true
                        }
                    }
                    HapticManager.selection()
                }
                .padding(.horizontal, Theme.spacingMD)
                .transition(.move(edge: .bottom))
            }

            Spacer(minLength: Theme.spacingMD)
        }
    }

    private var quizResultView: some View {
        let score = Int(Double(correctCount) / Double(level.questions.count) * 100)
        let stars = score >= 90 ? 3 : score >= 70 ? 2 : score >= 60 ? 1 : 0
        let passed = score >= level.passingScore

        return VStack(spacing: Theme.spacingLG) {
            Spacer()

            // Stars
            HStack(spacing: Theme.spacingSM) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < stars ? "star.fill" : "star")
                        .font(.system(size: 40))
                        .foregroundStyle(index < stars ? DongbeiColors.jinhuang : .gray.opacity(0.3))
                }
            }

            // Score
            Text("\(score)分")
                .font(.system(size: 64, weight: .black, design: .rounded))
                .foregroundStyle(passed ? DongbeiColors.cuilu : DongbeiColors.dahong)

            Text(passed ? "闯关成功！" : "还差一点点~")
                .font(Theme.headlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            // Dongbei result phrase
            if let phrase = dongbeiResultPhrase {
                HStack(spacing: 6) {
                    Image(systemName: tts.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)
                        .symbolEffectCompat(isActive: tts.isSpeaking)
                    Text(phrase)
                        .font(.subheadline.bold())
                }
                .foregroundStyle(passed ? DongbeiColors.cuilu : DongbeiColors.dahong)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background((passed ? DongbeiColors.cuilu : DongbeiColors.dahong).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }

            Text("\(correctCount) / \(level.questions.count) 题正确")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if passed {
                HStack(spacing: Theme.spacingSM) {
                    Label("+\(level.rewardXP) XP", systemImage: "star.fill")
                        .foregroundStyle(DongbeiColors.jinhuang)
                    if let title = level.rewardTitle {
                        Label("解锁: \(title)", systemImage: "trophy.fill")
                            .foregroundStyle(DongbeiColors.huabufen)
                    }
                }
                .font(.subheadline.bold())
            }

            Spacer()

            VStack(spacing: Theme.spacingSM) {
                DongbeiButton(title: "再来一次", icon: "arrow.counterclockwise", style: .outline) {
                    tts.stop()
                    currentIndex = 0
                    correctCount = 0
                    selectedAnswer = nil
                    isAnswered = false
                    showResult = false
                    resultSaved = false
                    dongbeiFeedback = nil
                    dongbeiResultPhrase = nil
                }

                DongbeiButton(title: "返回", icon: "house.fill") {
                    tts.stop()
                    dismiss()
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.bottom, Theme.spacingLG)
        }
        .task(id: showResult) {
            guard showResult, !resultSaved else { return }
            let score = Int(Double(correctCount) / Double(level.questions.count) * 100)
            let stars = score >= 90 ? 3 : score >= 70 ? 2 : score >= 60 ? 1 : 0
            let passed = score >= level.passingScore
            let result = QuizResult(
                levelId: level.id,
                score: score,
                totalQuestions: level.questions.count,
                correctCount: correctCount,
                stars: stars,
                completedAt: Date()
            )
            if passed {
                do {
                    var progress = try await progressRepo.fetchProgress()
                    progress.quizResults[level.id] = result
                    if let title = level.rewardTitle, !progress.unlockedTitles.contains(title) {
                        progress.unlockedTitles.append(title)
                    }
                    try await progressRepo.updateProgress(progress)

                    // 通过 XPService 统一增加 XP
                    let newXP = await XPService.shared.addXP(
                        amount: level.rewardXP,
                        sourceType: .quizPass,
                        description: "通过闯关「\(level.title)」"
                    )
                    await MainActor.run {
                        appState.currentUser?.totalScore = newXP
                    }

                    onLevelPassed?(level.id)

                    // Record learning for streak
                    StreakService().recordLearning()
                } catch {
                    // Save failed silently
                }
            }
            resultSaved = true

            // Speak dongbei result phrase
            tts.speakPraise(passed: passed, score: score)
            if !passed {
                dongbeiResultPhrase = DongbeiTTSService.encourageOnFail.randomElement()
            } else if score >= 90 {
                dongbeiResultPhrase = DongbeiTTSService.praiseOnPass.randomElement()
            } else {
                dongbeiResultPhrase = DongbeiTTSService.praiseOnGoodScore.randomElement()
            }
        }
    }
}

struct OptionButton: View {
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isRevealed: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body.bold())
                Spacer()
                if isRevealed {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : (isSelected ? "xmark.circle.fill" : ""))
                        .foregroundStyle(isCorrect ? DongbeiColors.cuilu : DongbeiColors.dahong)
                }
            }
            .padding(Theme.spacingMD)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .disabled(isRevealed)
    }

    private var backgroundColor: Color {
        if !isRevealed { return isSelected ? DongbeiColors.dahong.opacity(0.1) : .white }
        if isCorrect { return DongbeiColors.cuilu.opacity(0.15) }
        if isSelected { return DongbeiColors.dahong.opacity(0.15) }
        return .white
    }

    private var foregroundColor: Color {
        if isRevealed && isCorrect { return DongbeiColors.cuilu }
        if isRevealed && isSelected { return DongbeiColors.dahong }
        return DongbeiColors.meihei
    }

    private var borderColor: Color {
        if !isRevealed && isSelected { return DongbeiColors.dahong }
        if isRevealed && isCorrect { return DongbeiColors.cuilu }
        if isRevealed && isSelected { return DongbeiColors.dahong }
        return .clear
    }
}
