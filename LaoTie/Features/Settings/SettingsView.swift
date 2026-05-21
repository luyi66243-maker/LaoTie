import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isAutoMakeupEnabled: Bool = StreakService().isAutoMakeupEnabled
    @State private var reminderEnabled: Bool = NotificationService.shared.isReminderEnabled
    @State private var reminderTime: Date = NotificationService.shared.reminderTime

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingMD) {
                // MARK: - 学习相关
                VStack(spacing: 0) {
                    NavigationLink {
                        TicketWalletView()
                    } label: {
                        innerSettingsRow(
                            icon: "ticket.fill",
                            title: "补卡券管理",
                            subtitle: "查看、管理你的补卡券",
                            color: DongbeiColors.cuilu
                        )
                    }

                    Divider().padding(.leading, 48)

                    NavigationLink {
                        XPHistoryView()
                    } label: {
                        innerSettingsRow(
                            icon: "star.circle.fill",
                            title: "积分明细",
                            subtitle: "查看 XP 收支记录",
                            color: DongbeiColors.jinhuang
                        )
                    }

                    Divider().padding(.leading, 48)

                    // 打卡提醒
                    HStack(spacing: Theme.spacingMD) {
                        Image(systemName: "bell.fill")
                            .font(.body)
                            .foregroundStyle(DongbeiColors.dahong)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("打卡提醒")
                                .font(.body)
                                .foregroundStyle(DongbeiColors.meihei)
                            Text("每天定时提醒你学东北话")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $reminderEnabled)
                            .labelsHidden()
                            .tint(DongbeiColors.cuilu)
                            .onChange(of: reminderEnabled) { newValue in
                                if newValue {
                                    Task {
                                        let granted = await NotificationService.shared.requestAuthorization()
                                        if granted {
                                            NotificationService.shared.isReminderEnabled = true
                                        } else {
                                            await MainActor.run {
                                                reminderEnabled = false
                                            }
                                            NotificationService.shared.isReminderEnabled = false
                                        }
                                    }
                                } else {
                                    NotificationService.shared.isReminderEnabled = false
                                }
                            }
                    }
                    .padding(Theme.spacingMD)

                    if reminderEnabled {
                        Divider().padding(.leading, 48)

                        HStack(spacing: Theme.spacingMD) {
                            Image(systemName: "clock.fill")
                                .font(.body)
                                .foregroundStyle(DongbeiColors.jinhuang)
                                .frame(width: 24)
                            Text("提醒时间")
                                .font(.body)
                                .foregroundStyle(DongbeiColors.meihei)
                            Spacer()
                            DatePicker("", selection: $reminderTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .onChange(of: reminderTime) { newValue in
                                    NotificationService.shared.reminderTime = newValue
                                }
                        }
                        .padding(Theme.spacingMD)
                    }

                    Divider().padding(.leading, 48)

                    // Auto makeup toggle
                    HStack(spacing: Theme.spacingMD) {
                        Image(systemName: "wand.and.stars")
                            .font(.body)
                            .foregroundStyle(DongbeiColors.huabufen)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("自动补卡")
                                .font(.body)
                                .foregroundStyle(DongbeiColors.meihei)
                            Text("断档时自动使用补卡券")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $isAutoMakeupEnabled)
                            .labelsHidden()
                            .tint(DongbeiColors.cuilu)
                            .onChange(of: isAutoMakeupEnabled) { newValue in
                                StreakService().isAutoMakeupEnabled = newValue
                            }
                    }
                    .padding(Theme.spacingMD)
                }
                .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                // MARK: - 系统设置
                // TTS Settings
                NavigationLink {
                    TTSSettingsView()
                } label: {
                    settingsRow(
                        icon: "waveform.circle.fill",
                        title: "语音设置",
                        subtitle: VolcanoTTSService.isEnabled ? "云端东北方言音色" : "系统本地语音",
                        color: DongbeiColors.dahong
                    )
                }

                // AI Settings
                NavigationLink {
                    AISettingsView()
                } label: {
                    settingsRow(
                        icon: "bubble.left.and.text.bubble.right",
                        title: "AI 搭子设置",
                        subtitle: "API Key、模型配置",
                        color: DongbeiColors.cuilu
                    )
                }

                // About section
                VStack(spacing: 0) {
                    HStack(spacing: Theme.spacingMD) {
                        Image(systemName: "info.circle.fill")
                            .font(.body)
                            .foregroundStyle(DongbeiColors.binglan)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("关于唠嗑小馆")
                                .font(.body)
                                .foregroundStyle(DongbeiColors.meihei)
                            Text("版本 1.0.0")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(Theme.spacingMD)
                }
                .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func innerSettingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: Theme.spacingMD) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(DongbeiColors.meihei)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.spacingMD)
    }

    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: Theme.spacingMD) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(DongbeiColors.meihei)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
