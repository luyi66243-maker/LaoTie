import SwiftUI

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var selectedProvider: AIService.Provider = .deepseek
    @State private var showKey: Bool = false
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    @State private var testSuccess: Bool = false

    private let aiService = AIService()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingMD) {
                // MARK: - 提供商选择
                providerSection

                // MARK: - API Key 输入
                apiKeySection

                // MARK: - 操作按钮
                actionButtons

                // MARK: - 测试结果
                if let result = testResult {
                    testResultView(result)
                }

                // MARK: - 使用说明
                instructionSection
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("AI 设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") { dismiss() }
                    .foregroundStyle(DongbeiColors.dahong)
            }
        }
        .onAppear {
            apiKey = aiService.apiKey ?? ""
            selectedProvider = aiService.provider
        }
    }

    // MARK: - 提供商选择

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("AI 提供商")
                .font(Theme.subheadlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            HStack(spacing: Theme.spacingSM) {
                ForEach(AIService.Provider.allCases, id: \.rawValue) { provider in
                    providerButton(provider)
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func providerButton(_ provider: AIService.Provider) -> some View {
        let isSelected = selectedProvider == provider
        return Button {
            selectedProvider = provider
        } label: {
            Text(provider.displayName)
                .font(Theme.labelFont)
                .foregroundStyle(isSelected ? .white : DongbeiColors.meihei)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingSM)
                .background(
                    isSelected
                        ? AnyShapeStyle(DongbeiColors.primaryGradient)
                        : AnyShapeStyle(DongbeiColors.pageBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        }
        .buttonStyle(.plain)
    }

    // MARK: - API Key 输入

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("API Key")
                .font(Theme.subheadlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            HStack(spacing: Theme.spacingSM) {
                Group {
                    if showKey {
                        TextField("输入你的 API Key", text: $apiKey)
                    } else {
                        SecureField("输入你的 API Key", text: $apiKey)
                    }
                }
                .font(Theme.bodyFont)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(DongbeiColors.binglan)
                }
            }
            .padding(Theme.spacingSM)
            .background(DongbeiColors.pageBackground)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - 操作按钮

    private var actionButtons: some View {
        VStack(spacing: Theme.spacingSM) {
            // 保存按钮
            Button {
                saveSettings()
            } label: {
                Text("保存设置")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.spacingSM)
                    .background(DongbeiColors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }

            // 测试连接按钮
            Button {
                Task { await testConnection() }
            } label: {
                HStack(spacing: 6) {
                    if isTesting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(DongbeiColors.cuilu)
                    }
                    Text(isTesting ? "测试中..." : "测试连接")
                        .font(Theme.subheadlineFont)
                }
                .foregroundStyle(DongbeiColors.cuilu)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.spacingSM)
                .background(DongbeiColors.cuilu.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }
            .disabled(apiKey.isEmpty || isTesting)
            .opacity(apiKey.isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - 测试结果

    private func testResultView(_ result: String) -> some View {
        HStack(spacing: Theme.spacingSM) {
            Image(systemName: testSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(testSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong)
            Text(result)
                .font(Theme.captionFont)
                .foregroundStyle(testSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong)
            Spacer()
        }
        .padding(Theme.spacingSM)
        .background(
            (testSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong).opacity(0.08),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
        )
    }

    // MARK: - 使用说明

    private var instructionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label("使用说明", systemImage: "info.circle.fill")
                .font(Theme.subheadlineFont)
                .foregroundStyle(DongbeiColors.binglan)

            VStack(alignment: .leading, spacing: 6) {
                instructionRow("1", "选择 AI 提供商（推荐 DeepSeek，便宜好用）")
                instructionRow("2", "去官网申请 API Key")
                instructionRow("3", "把 Key 粘贴到上面的输入框")
                instructionRow("4", "点保存，就能跟 AI 搭子唠嗑了！")
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("官网地址")
                    .font(Theme.labelFont)
                    .foregroundStyle(.secondary)
                Text("DeepSeek: platform.deepseek.com")
                    .font(Theme.captionFont)
                    .foregroundStyle(DongbeiColors.meihei)
                Text("OpenAI: platform.openai.com")
                    .font(Theme.captionFont)
                    .foregroundStyle(DongbeiColors.meihei)
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func instructionRow(_ num: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(Theme.badgeFont)
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(DongbeiColors.jinhuang)
                .clipShape(Circle())
            Text(text)
                .font(Theme.captionFont)
                .foregroundStyle(DongbeiColors.meihei)
        }
    }

    // MARK: - Actions

    private func saveSettings() {
        var service = AIService()
        service.apiKey = apiKey.isEmpty ? nil : apiKey
        service.provider = selectedProvider
        testResult = "设置保存成功！老铁，可以去唠嗑了"
        testSuccess = true
    }

    private func testConnection() async {
        saveSettings()
        isTesting = true
        testResult = nil

        let service = AIService()
        let testMessages = [ChatMessage(role: .user, content: "你好")]
        do {
            let _ = try await service.sendMessage(messages: testMessages, character: .dongbeiDage)
            testResult = "连接成功！AI 搭子准备就绪，可以唠了"
            testSuccess = true
        } catch {
            testResult = error.localizedDescription
            testSuccess = false
        }
        isTesting = false
    }
}
