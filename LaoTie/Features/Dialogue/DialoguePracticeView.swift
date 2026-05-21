import SwiftUI

struct DialoguePracticeView: View {
    let dialogue: Dialogue
    @State private var currentLineIndex = 0
    @State private var revealedLines: [Int] = []
    @State private var showTranslation = false
    @StateObject private var audioPlayer = AudioPlayerService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            dialogueHeader

            // Chat area
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: Theme.spacingMD) {
                        ForEach(Array(revealedLines.enumerated()), id: \.offset) { _, lineIndex in
                            let line = dialogue.lines[lineIndex]
                            ChatBubbleView(
                                line: line,
                                role: dialogue.roles.first { $0.id == line.speakerRoleId },
                                showTranslation: showTranslation
                            )
                            .id(lineIndex)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(Theme.spacingMD)
                }
                .onChange(of: revealedLines.count) { _ in
                    if let last = revealedLines.last {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            // Controls
            controlBar
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle(dialogue.scenarioTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showTranslation.toggle()
                } label: {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                }
            }
        }
        .onAppear {
            revealNextLine()
        }
    }

    private var dialogueHeader: some View {
        VStack(spacing: 4) {
            Text(dialogue.scenarioDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TanghluProgressBar(
                progress: Double(revealedLines.count) / Double(dialogue.lines.count),
                totalBalls: min(dialogue.lines.count, 6)
            )
            .padding(.horizontal, Theme.spacingXL)
        }
        .padding(Theme.spacingSM)
        .background(.ultraThinMaterial)
    }

    private var controlBar: some View {
        HStack(spacing: Theme.spacingMD) {
            // Play current line dongbei audio
            Button {
                if let line = currentLine, let fileName = line.audioFileName {
                    audioPlayer.playBundledAudio(named: fileName, style: .dongbei)
                }
                HapticManager.impact(.light)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                    Text("东北话")
                        .font(.system(size: 9))
                }
                .frame(width: 50, height: 50)
                .background(DongbeiColors.dahong.opacity(0.2))
                .foregroundStyle(DongbeiColors.dahong)
                .clipShape(Circle())
            }

            // Play current line standard audio
            Button {
                if let line = currentLine, let fileName = line.standardAudioFileName {
                    audioPlayer.playBundledAudio(named: fileName, style: .standard)
                }
                HapticManager.impact(.light)
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                    Text("普通话")
                        .font(.system(size: 9))
                }
                .frame(width: 50, height: 50)
                .background(DongbeiColors.cuilu.opacity(0.2))
                .foregroundStyle(DongbeiColors.cuilu)
                .clipShape(Circle())
            }

            // Next line button
            if currentLineIndex < dialogue.lines.count {
                let isUserLine = dialogue.lines[currentLineIndex].isUserLine
                DongbeiButton(
                    title: isUserLine ? "我来说" : "下一句",
                    icon: isUserLine ? "mic.fill" : "arrow.right",
                    style: isUserLine ? .secondary : .primary
                ) {
                    if isUserLine {
                        _ = DailyTaskService().addDialoguePractice()
                    }
                    withAnimation(.spring(duration: 0.4)) {
                        revealNextLine()
                    }
                    HapticManager.selection()
                }
            } else {
                DongbeiButton(title: "完成", icon: "checkmark", style: .primary) {
                    HapticManager.correctAnswer()
                    StreakService().recordLearning()
                    dismiss()
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.ultraThinMaterial)
    }

    private var currentLine: DialogueLine? {
        guard !revealedLines.isEmpty, let lastIndex = revealedLines.last else { return nil }
        guard lastIndex < dialogue.lines.count else { return nil }
        return dialogue.lines[lastIndex]
    }

    private func revealNextLine() {
        guard currentLineIndex < dialogue.lines.count else { return }
        revealedLines.append(currentLineIndex)
        currentLineIndex += 1
    }
}

struct ChatBubbleView: View {
    let line: DialogueLine
    let role: DialogueRole?
    let showTranslation: Bool

    private var isUser: Bool { line.isUserLine }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.spacingSM) {
            if !isUser {
                avatarView
            } else {
                Spacer(minLength: 60)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if let role {
                    Text(role.name)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }

                Text(line.dongbeiText)
                    .font(.body)
                    .foregroundStyle(isUser ? .white : DongbeiColors.meihei)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? DongbeiColors.dahong : .white)
                    .clipShape(BubbleShape(isUser: isUser))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 2)

                if showTranslation {
                    Text(line.standardText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 4)
                }
            }

            if isUser {
                avatarView
            } else {
                Spacer(minLength: 60)
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(isUser ? DongbeiColors.jinhuang : DongbeiColors.binglan)
                .frame(width: 36, height: 36)
            Text(String((role?.name ?? "?").prefix(1)))
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
    }
}

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6

        var path = Path()
        if isUser {
            path.addRoundedRect(in: CGRect(x: 0, y: 0, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
            path.move(to: CGPoint(x: rect.width - tailSize, y: rect.height - 20))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height - 14))
            path.addLine(to: CGPoint(x: rect.width - tailSize, y: rect.height - 8))
        } else {
            path.addRoundedRect(in: CGRect(x: tailSize, y: 0, width: rect.width - tailSize, height: rect.height), cornerSize: CGSize(width: radius, height: radius))
            path.move(to: CGPoint(x: tailSize, y: rect.height - 20))
            path.addLine(to: CGPoint(x: 0, y: rect.height - 14))
            path.addLine(to: CGPoint(x: tailSize, y: rect.height - 8))
        }
        return path
    }
}
