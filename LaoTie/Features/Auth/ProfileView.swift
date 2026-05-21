import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var achievements: [ProfileAchievement] = ProfileAchievement.all
    @State private var newlyUnlocked: [ProfileAchievement] = []
    @State private var showUnlockToast = false
    @State private var selectedAchievement: ProfileAchievement?
    private let achievementService = AchievementService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    userHeader
                    statsGrid
                    achievementSection
                    menuSection
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("我的")
            .task { await refreshAchievements() }
            .sheet(item: $selectedAchievement) { ach in
                AchievementDetailSheet(achievement: ach)
                    .presentationDetents([.medium])
            }
            .overlay(alignment: .top) {
                if showUnlockToast, let first = newlyUnlocked.first {
                    AchievementUnlockToast(achievement: first)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
    }

    private func refreshAchievements() async {
        let result = await achievementService.refreshAchievements()
        withAnimation(.easeInOut(duration: 0.3)) {
            achievements = result.achievements
        }
        if !result.newlyUnlocked.isEmpty {
            newlyUnlocked = result.newlyUnlocked
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showUnlockToast = true
            }
            HapticManager.correctAnswer()
            try? await Task.sleep(for: .seconds(3))
            withAnimation {
                showUnlockToast = false
            }
        }
    }

    // MARK: - User Header

    private var userHeader: some View {
        VStack(spacing: Theme.spacingMD) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DongbeiColors.dahong, DongbeiColors.jinhuang],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text(appState.currentUser?.nickname ?? "南方小土豆")
                .font(Theme.headlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            if let title = appState.currentUser?.titles.last {
                Text(title)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(DongbeiColors.jinhuang.opacity(0.15))
                    .foregroundStyle(DongbeiColors.jinhuang)
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.spacingMD) {
            StatCard(value: "\(appState.currentUser?.totalScore ?? 0)", label: "总积分", icon: "star.fill", color: DongbeiColors.jinhuang)
            StatCard(value: "\(appState.currentUser?.currentStreak ?? 0)", label: "连续天数", icon: "flame.fill", color: DongbeiColors.huabufen)
            StatCard(
                value: "\(achievements.filter(\.isUnlocked).count)/\(achievements.count)",
                label: "已解锁", icon: "trophy.fill", color: DongbeiColors.cuilu
            )
        }
    }

    // MARK: - Achievement Section

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                Text("成就墙")
                    .font(Theme.headlineFont)
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                // Progress bar
                let unlocked = achievements.filter(\.isUnlocked).count
                let total = achievements.count
                HStack(spacing: 6) {
                    ProgressView(value: Double(unlocked), total: Double(total))
                        .tint(DongbeiColors.jinhuang)
                        .frame(width: 60)
                    Text("\(unlocked)/\(total)")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.spacingMD) {
                ForEach(achievements) { ach in
                    Button {
                        selectedAchievement = ach
                    } label: {
                        DynamicAchievementBadge(achievement: ach)
                    }
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Menu Section

    private var menuSection: some View {
        VStack(spacing: 0) {
            MenuRow(icon: "trophy.fill", title: "排行榜", color: DongbeiColors.jinhuang) {
                // Navigate to leaderboard
            }
            Divider().padding(.leading, 52)
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                HStack(spacing: Theme.spacingMD) {
                    Image(systemName: "hand.raised.fill")
                        .font(.body)
                        .foregroundStyle(DongbeiColors.cuilu)
                        .frame(width: 24)
                    Text("隐私政策")
                        .font(.body)
                        .foregroundStyle(DongbeiColors.meihei)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.spacingMD)
            }
            Divider().padding(.leading, 52)
            NavigationLink {
                TermsOfServiceView()
            } label: {
                HStack(spacing: Theme.spacingMD) {
                    Image(systemName: "doc.text.fill")
                        .font(.body)
                        .foregroundStyle(DongbeiColors.binglan)
                        .frame(width: 24)
                    Text("用户协议")
                        .font(.body)
                        .foregroundStyle(DongbeiColors.meihei)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.spacingMD)
            }
            Divider().padding(.leading, 52)
            NavigationLink {
                SettingsView()
            } label: {
                HStack(spacing: Theme.spacingMD) {
                    Image(systemName: "gearshape.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                    Text("设置")
                        .font(.body)
                        .foregroundStyle(DongbeiColors.meihei)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(Theme.spacingMD)
            }
            Divider().padding(.leading, 52)
            MenuRow(icon: "rectangle.portrait.and.arrow.right", title: "退出登录", color: DongbeiColors.dahong) {
                appState.signOut()
            }
        }
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Dynamic Achievement Badge

struct DynamicAchievementBadge: View {
    let achievement: ProfileAchievement

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked
                          ? DongbeiColors.jinhuang.opacity(0.12)
                          : Color.gray.opacity(0.06))
                    .frame(width: 50, height: 50)

                if achievement.isUnlocked {
                    Circle()
                        .strokeBorder(DongbeiColors.jinhuang.opacity(0.3), lineWidth: 2)
                        .frame(width: 50, height: 50)
                }

                Text(achievement.icon)
                    .font(.title2)
                    .grayscale(achievement.isUnlocked ? 0 : 1)
                    .opacity(achievement.isUnlocked ? 1 : 0.25)
            }

            Text(achievement.title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(achievement.isUnlocked ? DongbeiColors.meihei : .secondary)
                .lineLimit(1)

            // Category tag
            Text(achievement.category.rawValue)
                .font(.system(size: 7))
                .foregroundStyle(achievement.isUnlocked ? categoryColor : .secondary.opacity(0.5))
        }
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .milestone: DongbeiColors.dahong
        case .quiz: DongbeiColors.jinhuang
        case .dialogue: DongbeiColors.cuilu
        case .vocabulary: DongbeiColors.binglan
        case .checkin: DongbeiColors.huabufen
        case .streak: DongbeiColors.dahong
        }
    }
}

// MARK: - Achievement Detail Sheet

struct AchievementDetailSheet: View {
    let achievement: ProfileAchievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingLG) {
                // Large icon
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked
                              ? DongbeiColors.jinhuang.opacity(0.15)
                              : Color.gray.opacity(0.08))
                        .frame(width: 100, height: 100)

                    if achievement.isUnlocked {
                        Circle()
                            .strokeBorder(DongbeiColors.jinhuang.opacity(0.4), lineWidth: 3)
                            .frame(width: 100, height: 100)
                    }

                    Text(achievement.icon)
                        .font(.system(size: 48))
                        .grayscale(achievement.isUnlocked ? 0 : 1)
                        .opacity(achievement.isUnlocked ? 1 : 0.3)
                }

                // Title
                Text(achievement.title)
                    .font(.title2.bold())
                    .foregroundStyle(achievement.isUnlocked ? DongbeiColors.meihei : .secondary)

                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: achievement.isUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.caption)
                    Text(achievement.isUnlocked ? "已解锁" : "未解锁")
                        .font(.caption.bold())
                }
                .foregroundStyle(achievement.isUnlocked ? DongbeiColors.cuilu : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    (achievement.isUnlocked ? DongbeiColors.cuilu : Color.gray).opacity(0.1),
                    in: Capsule()
                )

                // Description
                Text(achievement.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.spacingLG)

                // Condition info
                VStack(spacing: Theme.spacingSM) {
                    HStack(spacing: Theme.spacingSM) {
                        Label(achievement.category.rawValue, systemImage: categoryIcon)
                            .font(.caption.bold())
                            .foregroundStyle(categoryColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(categoryColor.opacity(0.1), in: Capsule())

                        Text(conditionText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let date = achievement.unlockedAt {
                        Text("解锁于 \(date.formatted(.dateTime.year().month().day()))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()
            }
            .padding(.top, Theme.spacingLG)
            .background(DongbeiColors.pageBackground)
            .navigationTitle("成就详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(DongbeiColors.dahong)
                }
            }
        }
    }

    private var conditionText: String {
        switch achievement.condition {
        case .always: "注册即获得"
        case .quizLevels(let n): "通过\(n)个闯关关卡"
        case .vocabularyCount(let n): "学习\(n)个词汇"
        case .dialogueCount(let n): "完成\(n)个唠嗑场景"
        case .checkinCount(let n): "打卡\(n)个景点"
        case .streakDays(let n): "连续学习\(n)天"
        case .totalXP(let n): "累计\(n)经验值"
        }
    }

    private var categoryIcon: String {
        switch achievement.category {
        case .milestone: "flag.fill"
        case .quiz: "map.fill"
        case .dialogue: "bubble.left.and.bubble.right.fill"
        case .vocabulary: "character.book.closed.fill"
        case .checkin: "camera.fill"
        case .streak: "flame.fill"
        }
    }

    private var categoryColor: Color {
        switch achievement.category {
        case .milestone: DongbeiColors.dahong
        case .quiz: DongbeiColors.jinhuang
        case .dialogue: DongbeiColors.cuilu
        case .vocabulary: DongbeiColors.binglan
        case .checkin: DongbeiColors.huabufen
        case .streak: DongbeiColors.dahong
        }
    }
}

// MARK: - Unlock Toast

struct AchievementUnlockToast: View {
    let achievement: ProfileAchievement

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            Text(achievement.icon)
                .font(.title)

            VStack(alignment: .leading, spacing: 2) {
                Text("成就解锁！")
                    .font(.caption.bold())
                    .foregroundStyle(DongbeiColors.jinhuang)
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }

            Spacer()

            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundStyle(DongbeiColors.jinhuang)
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: DongbeiColors.jinhuang.opacity(0.3), radius: 12, y: 4)
        .padding(.horizontal, Theme.spacingMD)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(DongbeiColors.meihei)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.spacingMD) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                    .frame(width: 24)
                Text(title)
                    .font(.body)
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(Theme.spacingMD)
        }
    }
}
