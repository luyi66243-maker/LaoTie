import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showAISettings = false

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 角色选择栏
            characterSelector

            Divider()
                .background(DongbeiColors.pageBackground)

            if !viewModel.isConfigured {
                // MARK: - 未配置 API Key 引导
                apiKeyGuideView
            } else {
                // MARK: - 聊天内容
                chatContentView
            }
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("唠嗑搭子")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        viewModel.startNewConversation()
                    } label: {
                        Label("新对话", systemImage: "plus.message")
                    }
                    Button {
                        showAISettings = true
                    } label: {
                        Label("AI 设置", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(DongbeiColors.dahong)
                }
            }
        }
        .sheet(isPresented: $showAISettings) {
            NavigationStack {
                AISettingsView()
            }
        }
        .onAppear {
            if viewModel.messages.isEmpty && viewModel.isConfigured {
                viewModel.startNewConversation()
            }
        }
    }

    // MARK: - 角色选择器

    private var characterSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingSM) {
                ForEach(AICharacter.allCases, id: \.rawValue) { character in
                    characterCard(character)
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
        }
        .background(DongbeiColors.cardBackground)
    }

    private func characterCard(_ character: AICharacter) -> some View {
        let isSelected = viewModel.selectedCharacter == character
        return Button {
            viewModel.switchCharacter(to: character)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: character.avatar)
                    .font(.system(size: 14, weight: .semibold))
                VStack(alignment: .leading, spacing: 1) {
                    Text(character.displayName)
                        .font(Theme.labelFont)
                        .lineLimit(1)
                    Text(character.description)
                        .font(Theme.tinyFont)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, Theme.spacingSM)
            .padding(.vertical, 6)
            .foregroundStyle(isSelected ? .white : DongbeiColors.meihei)
            .background(
                isSelected
                    ? AnyShapeStyle(DongbeiColors.primaryGradient)
                    : AnyShapeStyle(DongbeiColors.pageBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        }
        .buttonStyle(.plain)
    }

    // MARK: - API Key 引导

    private var apiKeyGuideView: some View {
        VStack(spacing: Theme.spacingLG) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(DongbeiColors.jinhuang)

            Text("先整个 API Key")
                .font(Theme.headlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            Text("要跟 AI 搭子唠嗑，得先配置一下 API Key。\n支持 DeepSeek 和 OpenAI。")
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXL)

            Button {
                showAISettings = true
            } label: {
                Text("去配置")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.spacingXL)
                    .padding(.vertical, Theme.spacingSM)
                    .background(DongbeiColors.primaryGradient)
                    .clipShape(Capsule())
            }

            Spacer()
        }
    }

    // MARK: - 聊天内容

    private var chatContentView: some View {
        VStack(spacing: 0) {
            // 消息列表
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Theme.spacingSM) {
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(Theme.spacingMD)
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if viewModel.isLoading {
                            proxy.scrollTo("typing", anchor: .bottom)
                        } else if let lastMsg = viewModel.messages.last {
                            proxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isLoading) { loading in
                    if loading {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }

            // 错误提示
            if let error = viewModel.errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text(error)
                        .font(Theme.captionFont)
                }
                .foregroundStyle(DongbeiColors.dahong)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingXS)
            }

            Divider()

            // 输入区域
            inputArea
        }
    }

    // MARK: - 消息气泡

    private func messageBubble(_ message: ChatMessage) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingSM) {
            if message.role == .assistant {
                // AI 头像
                Image(systemName: viewModel.selectedCharacter.avatar)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(DongbeiColors.primaryGradient)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 48)
            }

            Text(message.content)
                .font(Theme.bodyFont)
                .foregroundStyle(message.role == .user ? .white : DongbeiColors.meihei)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingSM)
                .background(
                    message.role == .user
                        ? AnyShapeStyle(DongbeiColors.primaryGradient)
                        : AnyShapeStyle(Color.white)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            if message.role == .user {
                // 用户头像
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(DongbeiColors.cuilu)
                    .clipShape(Circle())
            } else {
                Spacer(minLength: 48)
            }
        }
    }

    // MARK: - 正在输入指示器

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: Theme.spacingSM) {
            Image(systemName: viewModel.selectedCharacter.avatar)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(DongbeiColors.primaryGradient)
                .clipShape(Circle())

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(DongbeiColors.dahong.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .offset(y: typingDotOffset(index))
                        .animation(
                            .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: viewModel.isLoading
                        )
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

            Spacer(minLength: 48)
        }
    }

    private func typingDotOffset(_ index: Int) -> CGFloat {
        viewModel.isLoading ? -4 : 0
    }

    // MARK: - 输入区域

    private var inputArea: some View {
        HStack(spacing: Theme.spacingSM) {
            TextField("跟搭子唠点啥...", text: $viewModel.inputText, axis: .vertical)
                .font(Theme.bodyFont)
                .lineLimit(1...4)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.vertical, Theme.spacingSM)
                .background(DongbeiColors.pageBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusXL))

            Button {
                Task {
                    await viewModel.sendMessage()
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                            ? Color.gray.opacity(0.4)
                            : DongbeiColors.dahong
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, Theme.spacingSM)
        .background(DongbeiColors.cardBackground)
    }
}
