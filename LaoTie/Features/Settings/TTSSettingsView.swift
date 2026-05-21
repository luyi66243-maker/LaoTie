import SwiftUI
import os

private let logger = Logger(subsystem: "com.laotie.app", category: "TTSSettings")

struct TTSSettingsView: View {
    @State private var isEnabled = VolcanoTTSService.isEnabled
    @State private var isFallbackToastEnabled = AudioPlayerService.isFallbackToastEnabled
    @State private var appId = VolcanoTTSService.appId
    @State private var token = VolcanoTTSService.token
    @State private var isTesting = false
    @State private var testResult: TestResult?
    @State private var showClearCacheAlert = false
    @State private var cacheCleared = false
    @State private var preflightReport: AudioPreflightReport?
    @State private var cacheDiagnostics = VolcanoTTSService.cacheDiagnostics()
    @State private var failureDiagnostics = AudioPlayerService.latestFailureDiagnostics()
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case appId, token
    }

    private enum TestResult {
        case success
        case failure(String)

        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }

        var message: String {
            switch self {
            case .success: "连接成功！东北老铁音色可用"
            case .failure(let msg): msg
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                // Header
                headerSection

                // Toggle
                toggleSection

                // Credential fields
                if isEnabled {
                    credentialSection
                    testSection
                    preflightSection
                    cacheSection
                }

                fallbackToastSection

                // Info
                infoSection
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("语音设置")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveSettings()
        }
        .onAppear {
            refreshDiagnostics()
        }
        .alert("清除缓存", isPresented: $showClearCacheAlert) {
            Button("取消", role: .cancel) {}
            Button("清除", role: .destructive) {
                let service = VolcanoTTSService()
                service.clearCache()
                cacheCleared = true
                refreshDiagnostics()
            }
        } message: {
            Text("将删除所有已缓存的语音文件，下次播放时会重新从云端获取。")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: Theme.spacingSM) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(DongbeiColors.dahong)

            Text("东北方言云语音")
                .font(Theme.headlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            Text("使用火山引擎「东北老铁」音色，让语音反馈更地道")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var toggleSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("启用云端语音")
                    .font(.body.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text(isEnabled ? "使用火山引擎东北方言音色" : "使用系统本地语音合成")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isEnabled)
                .tint(DongbeiColors.dahong)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    VolcanoTTSService.isEnabled = newValue
                }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var credentialSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("API 凭证")
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)

            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("App ID")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextField("输入火山引擎 App ID", text: $appId)
                    .textFieldStyle(.plain)
                    .font(.body.monospaced())
                    .padding(12)
                    .background(DongbeiColors.pageBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                    .focused($focusedField, equals: .appId)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                Text("Access Token")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                SecureField("输入火山引擎 Access Token", text: $token)
                    .textFieldStyle(.plain)
                    .font(.body.monospaced())
                    .padding(12)
                    .background(DongbeiColors.pageBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                    .focused($focusedField, equals: .token)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(isConfigured ? DongbeiColors.cuilu : DongbeiColors.dahong)
                    .frame(width: 8, height: 8)
                Text(isConfigured ? "凭证已配置" : "请填写 App ID 和 Token")
                    .font(.caption)
                    .foregroundStyle(isConfigured ? DongbeiColors.cuilu : .secondary)
            }

            Button("保存凭证") {
                saveSettings()
                focusedField = nil
            }
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(DongbeiColors.dahong, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var testSection: some View {
        VStack(spacing: Theme.spacingSM) {
            Button {
                testConnection()
            } label: {
                HStack(spacing: Theme.spacingSM) {
                    if isTesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    Text(isTesting ? "测试中..." : "测试语音连接")
                        .font(.body.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(isConfigured ? .white : .white.opacity(0.5))
                .background(
                    isConfigured ? DongbeiColors.cuilu : DongbeiColors.cuilu.opacity(0.5),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                )
            }
            .disabled(!isConfigured || isTesting)

            if let result = testResult {
                HStack(spacing: 6) {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(result.isSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong)
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(result.isSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong)
                }
                .padding(Theme.spacingSM)
                .frame(maxWidth: .infinity)
                .background(
                    (result.isSuccess ? DongbeiColors.cuilu : DongbeiColors.dahong).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                )
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var preflightSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Text("音频健康检查")
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Button("运行检测") {
                    preflightReport = AudioPlayerService.runPreflight()
                    refreshDiagnostics()
                }
                .font(.caption.bold())
                .foregroundStyle(DongbeiColors.dahong)
            }

            if let report = preflightReport {
                VStack(alignment: .leading, spacing: 6) {
                    preflightRow(
                        title: "本地音频资源",
                        value: "\(report.bundledAudioCount) 个",
                        ok: report.bundledAudioCount > 0
                    )
                    preflightRow(
                        title: "本地语音引擎",
                        value: report.localTTSAvailable ? "可用" : "不可用",
                        ok: report.localTTSAvailable
                    )
                    preflightRow(
                        title: "云端语音开关",
                        value: report.cloudTTSEnabled ? "已启用" : "未启用",
                        ok: report.cloudTTSEnabled
                    )
                    preflightRow(
                        title: "云端凭证状态",
                        value: report.cloudTTSConfigured ? "已配置" : "未配置",
                        ok: report.cloudTTSConfigured || !report.cloudTTSEnabled
                    )

                    Divider().padding(.vertical, 4)

                    Text("建议")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(report.suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(Theme.spacingSM)
                .background(DongbeiColors.pageBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var cacheSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("语音缓存")
                        .font(.body.bold())
                        .foregroundStyle(DongbeiColors.meihei)
                    Text(cacheCleared ? "缓存已清除" : "已缓存的语音会加速后续播放")
                        .font(.caption)
                        .foregroundStyle(cacheCleared ? DongbeiColors.cuilu : .secondary)
                }
                Spacer()
                Button("清除") {
                    showClearCacheAlert = true
                }
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.dahong)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("命中次数：\(cacheDiagnostics.hitCount)  次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("回源次数：\(cacheDiagnostics.missCount)  次")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("缓存命中率：\(Int(cacheDiagnostics.hitRate * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(DongbeiColors.cuilu)
                if let cleared = cacheDiagnostics.lastClearedAt {
                    Text("最近清理：\(cleared.formatted(.dateTime.month().day().hour().minute()))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var fallbackToastSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("显示音频降级提示")
                    .font(.body.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text("音频文件缺失并切换到语音播报时显示提示")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: $isFallbackToastEnabled)
                .tint(DongbeiColors.cuilu)
                .labelsHidden()
                .onChange(of: isFallbackToastEnabled) { newValue in
                    AudioPlayerService.isFallbackToastEnabled = newValue
                }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label("使用说明", systemImage: "info.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)

            if let reason = failureDiagnostics.reason {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DongbeiColors.dahong)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最近一次失败原因")
                            .font(.caption.bold())
                            .foregroundStyle(DongbeiColors.dahong)
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let at = failureDiagnostics.happenedAt {
                            Text(at.formatted(.dateTime.month().day().hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(Theme.spacingSM)
                .background(DongbeiColors.dahong.opacity(0.08), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            }

            VStack(alignment: .leading, spacing: 6) {
                infoRow(num: "1", text: "前往火山引擎控制台注册账号")
                infoRow(num: "2", text: "开通语音合成服务，获取 App ID")
                infoRow(num: "3", text: "生成 Access Token 并填入上方")
                infoRow(num: "4", text: "点击「测试语音连接」验证配置")
            }

            Text("未配置云端语音时，APP 会使用系统本地语音作为备选方案。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Helpers

    private var isConfigured: Bool {
        !appId.trimmingCharacters(in: .whitespaces).isEmpty &&
        !token.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func infoRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(DongbeiColors.dahong, in: Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func preflightRow(title: String, value: String, ok: Bool) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(ok ? DongbeiColors.cuilu : DongbeiColors.dahong)
                    .frame(width: 6, height: 6)
                Text(value)
                    .font(.caption.bold())
                    .foregroundStyle(ok ? DongbeiColors.cuilu : DongbeiColors.dahong)
            }
        }
    }

    private func saveSettings() {
        VolcanoTTSService.appId = appId.trimmingCharacters(in: .whitespaces)
        VolcanoTTSService.token = token.trimmingCharacters(in: .whitespaces)
        VolcanoTTSService.isEnabled = isEnabled
        AudioPlayerService.isFallbackToastEnabled = isFallbackToastEnabled
        logger.info("TTS settings saved, configured: \(isConfigured)")
    }

    private func refreshDiagnostics() {
        cacheDiagnostics = VolcanoTTSService.cacheDiagnostics()
        let localFailure = AudioPlayerService.latestFailureDiagnostics()
        let cloudFailure = VolcanoTTSService.latestFailureDiagnostics()

        if let cloudReason = cloudFailure.reason, !cloudReason.isEmpty {
            let localDate = localFailure.happenedAt ?? .distantPast
            let cloudDate = cloudFailure.happenedAt ?? .distantPast
            if cloudDate >= localDate {
                failureDiagnostics = .init(reason: cloudReason, happenedAt: cloudFailure.happenedAt)
                return
            }
        }
        failureDiagnostics = localFailure
    }

    private func testConnection() {
        saveSettings()
        isTesting = true
        testResult = nil

        Task { @MainActor in
            let tts = VolcanoTTSService()
            let started = await tts.speak("老铁，连接成功了！嘎嘎好使！")
            if started {
                testResult = .success
            } else {
                // Check if credentials were valid
                if !isConfigured {
                    testResult = .failure("请先填写 App ID 和 Token")
                } else {
                    testResult = .failure("连接失败，请检查凭证是否正确")
                }
            }
            refreshDiagnostics()
            isTesting = false
        }
    }
}
