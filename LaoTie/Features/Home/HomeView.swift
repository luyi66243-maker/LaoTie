import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var vocabularies: [Vocabulary] = []
    @State private var dailyWord: Vocabulary?
    @State private var dueReviewCount = 0
    @State private var scenics: [Scenic] = []
    @State private var streakData = StreakData.empty
    @State private var showTicketSheet = false
    @State private var showStreakBrokenAlert = false
    @State private var previousStreak = 0
    @State private var dailyTaskProgress = DailyTaskProgress.empty(for: "")
    @State private var showTaskRewardToast = false
    @State private var showMilestone = false
    @State private var milestoneTitle = ""
    @State private var milestoneTickets = 0
    @State private var milestoneXP = 0
    @State private var showStreakToast = false
    @State private var streakToastText = ""

    private let vocabRepo = VocabularyRepository()
    private let scenicRepo = ScenicRepository()
    private let streakService = StreakService()
    private let dailyTaskService = DailyTaskService()
    private let reviewScheduleService = ReviewScheduleService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    // Streak banner
                    streakBanner

                    // Go study button (4a)
                    if !streakData.todayLearned {
                        goStudyButton
                    }

                    // Daily task card
                    dailyTaskCard

                    // Dialect search
                    DialectSearchView()

                    // Daily word card
                    if let word = dailyWord {
                        DailyWordCard(vocabulary: word) {
                            refreshDailyTaskProgress()
                        }
                    }

                    // Daily quote card
                    DailyQuoteCard()

                    // Quick entry grid
                    quickEntryGrid

                    // Review reminder
                    if dueReviewCount > 0 {
                        reviewReminder
                    }

                    // Scenic carousel
                    if !scenics.isEmpty {
                        ScenicCarouselView(scenics: scenics)
                    }

                    // Dongbei food carousel
                    DongbeiFoodCarouselView()
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("唠嗑小馆")
            .task { await loadData() }
            .onAppear {
                refreshDailyTaskProgress()
                refreshDueReviewCount()
                checkStreakChange()
            }
            .onReceive(NotificationCenter.default.publisher(for: .dailyTaskProgressDidChange)) { _ in
                refreshDailyTaskProgress()
            }
            .onReceive(NotificationCenter.default.publisher(for: .reviewScheduleDidChange)) { _ in
                refreshDueReviewCount()
            }
            .onReceive(NotificationCenter.default.publisher(for: .streakDidRecord)) { notification in
                // 4d: Play sound and show toast on streak record
                let newStreak = notification.userInfo?["streak"] as? Int ?? streakData.currentStreak
                SoundEffectService.shared.play(.correct)
                streakToastText = "连续学习 \(newStreak) 天 🔥"
                withAnimation(.spring(duration: 0.4)) { showStreakToast = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { showStreakToast = false }
                }
                // Refresh streak data
                streakData = streakService.loadStreak()
                appState.currentUser?.currentStreak = streakData.currentStreak

                // 4e: Check milestone
                if let milestone = streakService.checkMilestoneReward(streak: newStreak) {
                    milestoneTitle = milestone.title
                    milestoneTickets = milestone.tickets
                    milestoneXP = milestone.xp
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        showMilestone = true
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: XPService.xpDidChangeNotification)) { _ in
                // Sync XP display
                appState.currentUser?.totalScore = XPService.shared.getCurrentXPSync()
            }
            .sheet(isPresented: $showTicketSheet) {
                TicketExchangeSheet(
                    streakData: $streakData,
                    appState: appState
                )
            }
            .fullScreenCover(isPresented: $showMilestone) {
                MilestoneView(
                    title: milestoneTitle,
                    tickets: milestoneTickets,
                    xp: milestoneXP
                ) {
                    showMilestone = false
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 8) {
                    if showTaskRewardToast {
                        HStack(spacing: 6) {
                            Image(systemName: "gift.fill")
                            Text("今日任务奖励 +\(DailyTaskService.dailyRewardXP) XP")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DongbeiColors.cuilu, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if showStreakToast {
                        HStack(spacing: 6) {
                            Image(systemName: "flame.fill")
                            Text(streakToastText)
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(DongbeiColors.jinhuang, in: Capsule())
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.top, Theme.spacingLG)
            }
            .alert("连续学习中断", isPresented: $showStreakBrokenAlert) {
                if streakData.makeupTickets > 0 {
                    Button("使用补卡券恢复") {
                        let restored = streakService.useTicketToRestore(brokenStreak: previousStreak)
                        streakData = restored
                        appState.currentUser?.currentStreak = restored.currentStreak
                        UserDefaults.standard.set(restored.currentStreak, forKey: "laotie_streak")
                    }
                }
                Button("从头开始", role: .cancel) {}
            } message: {
                if streakData.makeupTickets > 0 {
                    Text("你的\(previousStreak)天连续学习记录已中断。你有\(streakData.makeupTickets)张补卡券，是否使用？")
                } else {
                    Text("你的\(previousStreak)天连续学习记录已中断。可以在下方兑换补卡券来防止下次断档。")
                }
            }
        }
    }

    private var streakBanner: some View {
        VStack(spacing: 0) {
            // Main streak row
            HStack {
                // Flame icon with animation
                ZStack {
                    Circle()
                        .fill(streakData.todayLearned ? DongbeiColors.jinhuang.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 44, height: 44)
                    Image(systemName: streakData.todayLearned ? "flame.fill" : "flame")
                        .font(.title2)
                        .foregroundStyle(streakData.todayLearned ? DongbeiColors.jinhuang : .gray)
                        .symbolBounceCompat(value: streakData.todayLearned)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("连续学习 \(streakData.currentStreak) 天")
                        .font(.headline.bold())
                        .foregroundStyle(DongbeiColors.meihei)
                    Text(streakStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(appState.currentUser?.totalScore ?? 0)")
                    .font(.title2.bold())
                    .foregroundColor(DongbeiColors.jinhuang)
                + Text(" XP")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }

            // 4g: Expiring ticket warning
            let expiringTickets = streakService.expiringTickets()
            if !expiringTickets.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("\(expiringTickets.count)张补卡券即将过期")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .padding(.top, Theme.spacingSM)
            }

            // 4c: Ticket bar - clickable
            HStack(spacing: Theme.spacingSM) {
                NavigationLink(destination: TicketWalletView()) {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "ticket.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.cuilu)
                        Text("补卡券: \(streakData.makeupTickets)张")
                            .font(Theme.smallLabelFont)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                }

                Spacer()

                Button {
                    showTicketSheet = true
                } label: {
                    Text("兑换")
                        .font(Theme.smallLabelFont.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(DongbeiColors.cuilu, in: Capsule())
                }
            }
            .padding(.top, Theme.spacingSM + 2)
        }
        .dongbeiCard()
    }

    private var streakStatusText: String {
        if streakData.todayLearned {
            return "今日已打卡，继续保持！"
        } else if streakData.currentStreak > 0 {
            return "今天还没学习，别断档了老铁！"
        } else {
            return "开始学习，点亮连续天数！"
        }
    }

    // 4a: Go study button
    private var goStudyButton: some View {
        Button {
            NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
        } label: {
            HStack {
                Image(systemName: "book.fill")
                Text("开始学习，点亮今天")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(DongbeiColors.dahong)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var reviewReminder: some View {
        HStack {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.title3)
                .foregroundStyle(DongbeiColors.dahong)
            Text("今天还有 \(dueReviewCount) 个词等你复习")
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)
            Spacer()
            NavigationLink("去复习") {
                ReviewQueueView()
            }
            .font(.subheadline.bold())
            .foregroundStyle(DongbeiColors.dahong)
        }
        .padding(Theme.spacingMD)
        .background(DongbeiColors.dahong.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    private var dailyTaskCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack {
                Label("今日任务", systemImage: "checklist")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Text("\(dailyTaskProgress.completedTaskCount)/4")
                    .font(.caption.bold())
                    .foregroundStyle(DongbeiColors.dahong)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DongbeiColors.dahong.opacity(0.1), in: Capsule())
            }

            ProgressView(value: dailyTaskProgress.completionRate, total: 1)
                .tint(DongbeiColors.dahong)

            completionMiniChart

            Text(dailyTaskSummaryText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if dailyTaskProgress.canClaimReward {
                Button {
                    claimDailyTaskReward()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "gift.fill")
                        Text("领取今日奖励 +\(DailyTaskService.dailyRewardXP) XP")
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(.white)
                    .padding(.vertical, 10)
                    .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
                .buttonStyle(.plain)
            } else if dailyTaskProgress.rewardClaimed {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("今日奖励已领取")
                        .font(.caption.bold())
                }
                .foregroundStyle(DongbeiColors.cuilu)
            }

            taskRow(
                title: "每日一词",
                detail: "播放或翻转一次每日词卡",
                isDone: dailyTaskProgress.dailyWordCompleted
            )

            NavigationLink {
                QuizHomeView()
            } label: {
                taskRow(
                    title: "闯关练习",
                    detail: "完成 \(dailyTaskProgress.quizAnsweredCount)/\(DailyTaskProgress.quizTarget) 题",
                    isDone: dailyTaskProgress.quizCompleted,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ScenarioListView()
            } label: {
                taskRow(
                    title: "跟读一句",
                    detail: "完成 \(dailyTaskProgress.dialoguePracticeCount)/\(DailyTaskProgress.dialogueTarget) 次",
                    isDone: dailyTaskProgress.dialogueCompleted,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                ReviewQueueView()
            } label: {
                taskRow(
                    title: "复习一次",
                    detail: "完成 \(dailyTaskProgress.reviewCount)/\(DailyTaskProgress.reviewTarget) 次",
                    isDone: dailyTaskProgress.reviewCompleted,
                    showChevron: true
                )
            }
            .buttonStyle(.plain)
        }
        .dongbeiCard()
    }

    private var dailyTaskSummaryText: String {
        if dailyTaskProgress.rewardClaimed {
            return "今日任务与奖励都已完成，歇会儿也行"
        }
        if dailyTaskProgress.completedTaskCount == 4 {
            return "今日任务已全部完成，真中！"
        }
        if dueReviewCount > 0 && !dailyTaskProgress.reviewCompleted {
            return "还差 \(4 - dailyTaskProgress.completedTaskCount) 项，优先把复习清掉"
        }
        return "还差 \(4 - dailyTaskProgress.completedTaskCount) 项，继续冲一把"
    }

    private func taskRow(title: String, detail: String, isDone: Bool, showChevron: Bool = false) -> some View {
        HStack(spacing: Theme.spacingSM) {
            Image(systemName: isDone ? "checkmark.seal.fill" : "circle")
                .foregroundStyle(isDone ? DongbeiColors.cuilu : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var completionMiniChart: some View {
        let values = [
            dailyTaskProgress.dailyWordCompleted ? 1.0 : 0.0,
            min(Double(dailyTaskProgress.quizAnsweredCount) / Double(DailyTaskProgress.quizTarget), 1.0),
            min(Double(dailyTaskProgress.dialoguePracticeCount) / Double(DailyTaskProgress.dialogueTarget), 1.0),
            min(Double(dailyTaskProgress.reviewCount) / Double(DailyTaskProgress.reviewTarget), 1.0)
        ]

        return VStack(alignment: .leading, spacing: 6) {
            Text("今日完成率")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.18))
                                .frame(width: 16, height: 30)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(DongbeiColors.dahong.opacity(0.85))
                                .frame(width: 16, height: max(4, 30 * value))
                        }
                        Text(["词", "闯", "练", "复"][index])
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(Int(dailyTaskProgress.completionRate * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(DongbeiColors.dahong)
            }
        }
    }

    private var quickEntryGrid: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text("探索更多")
                .font(Theme.headlineFont)
                .foregroundStyle(DongbeiColors.meihei)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.spacingSM),
                GridItem(.flexible(), spacing: Theme.spacingSM),
                GridItem(.flexible(), spacing: Theme.spacingSM)
            ], spacing: Theme.spacingSM) {
                NavigationLink {
                    MemeListView()
                } label: {
                    QuickEntryCard(
                        icon: "face.smiling.inverse",
                        title: "梗库",
                        subtitle: "东北文化",
                        color: DongbeiColors.huabufen
                    )
                }

                NavigationLink {
                    TongueTwisterListView()
                } label: {
                    QuickEntryCard(
                        icon: "mouth",
                        title: "绕口令",
                        subtitle: "练发音",
                        color: DongbeiColors.cuilu
                    )
                }

                NavigationLink {
                    CheckInHubView()
                } label: {
                    QuickEntryCard(
                        icon: "camera.viewfinder",
                        title: "打卡",
                        subtitle: "景点打卡",
                        color: DongbeiColors.binglan
                    )
                }
            }
        }
    }

    private func loadData() async {
        refreshDailyTaskProgress()
        refreshDueReviewCount()

        // Load streak data and detect breaks
        let oldStreak = UserDefaults.standard.integer(forKey: "laotie_streak")
        streakData = streakService.loadStreak()

        // Update AppState with current streak
        appState.currentUser?.currentStreak = streakData.currentStreak
        UserDefaults.standard.set(streakData.currentStreak, forKey: "laotie_streak")

        // Detect if streak was broken
        if oldStreak > 0 && streakData.currentStreak == 0 {
            previousStreak = oldStreak
            showStreakBrokenAlert = true
        }

        do {
            vocabularies = try await vocabRepo.fetchAll()
            dailyWord = vocabularies.randomElement()
            scenics = try await scenicRepo.fetchAll()
        } catch {
            // Use empty state
        }
    }

    private func refreshDailyTaskProgress() {
        dailyTaskProgress = dailyTaskService.loadTodayProgress()
    }

    private func refreshDueReviewCount() {
        dueReviewCount = reviewScheduleService.todayDueCount()
    }

    /// 4d: Check if streak changed since last check (e.g., user completed learning in another tab)
    private func checkStreakChange() {
        let freshData = streakService.loadStreak()
        let oldLearned = streakData.todayLearned
        let newLearned = freshData.todayLearned

        if !oldLearned && newLearned {
            // Just completed today's learning
            SoundEffectService.shared.play(.correct)
            streakToastText = "连续学习 \(freshData.currentStreak) 天 🔥"
            withAnimation(.spring(duration: 0.4)) { showStreakToast = true }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2))
                withAnimation { showStreakToast = false }
            }

            // 4e: Check milestone
            if let milestone = streakService.checkMilestoneReward(streak: freshData.currentStreak) {
                milestoneTitle = milestone.title
                milestoneTickets = milestone.tickets
                milestoneXP = milestone.xp
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showMilestone = true
                }
            }
        }

        streakData = freshData
        appState.currentUser?.currentStreak = freshData.currentStreak
    }

    private func claimDailyTaskReward() {
        guard dailyTaskService.claimRewardIfEligible() else { return }
        let reward = DailyTaskService.dailyRewardXP

        Task {
            let newXP = await XPService.shared.addXP(
                amount: reward,
                sourceType: .dailyTaskReward,
                description: "每日任务全完成奖励"
            )
            appState.currentUser?.totalScore = newXP
        }

        refreshDailyTaskProgress()
        withAnimation(.spring(duration: 0.4)) {
            showTaskRewardToast = true
        }
        HapticManager.notification(.success)
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeInOut(duration: 0.2)) {
                showTaskRewardToast = false
            }
        }
    }
}

// MARK: - Ticket Exchange Sheet

struct TicketExchangeSheet: View {
    @Binding var streakData: StreakData
    let appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showConfirmAlert = false
    @State private var exchangeSuccess = false
    @State private var isExchanging = false
    @State private var exchangeMessage = ""

    private let streakService = StreakService()

    private var currentXP: Int {
        appState.currentUser?.totalScore ?? 0
    }

    private var price: Int {
        streakService.currentExchangePrice()
    }

    private var monthKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        f.timeZone = .current
        return f.string(from: Date())
    }

    private var exchangedCount: Int {
        streakService.getMonthlyExchangeCount(monthKey)
    }

    private var canAfford: Bool {
        currentXP >= price
    }

    private var reachedLimit: Bool {
        exchangedCount >= StreakService.monthlyExchangeLimit
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.spacingLG) {
                // Header illustration
                VStack(spacing: Theme.spacingSM) {
                    ZStack {
                        Circle()
                            .fill(DongbeiColors.cuilu.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(DongbeiColors.cuilu)
                    }

                    Text("连续打卡券")
                        .font(.title2.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    Text("断档时自动使用，保护你的连续记录")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.spacingLG)

                // Current status
                VStack(spacing: Theme.spacingMD) {
                    HStack {
                        Label("当前积分", systemImage: "star.fill")
                            .foregroundStyle(DongbeiColors.jinhuang)
                        Spacer()
                        Text("\(currentXP) XP")
                            .font(.headline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                    }

                    Divider()

                    HStack {
                        Label("已有补卡券", systemImage: "ticket.fill")
                            .foregroundStyle(DongbeiColors.cuilu)
                        Spacer()
                        Text("\(streakData.makeupTickets) 张")
                            .font(.headline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                    }

                    Divider()

                    HStack {
                        Label("当前价格", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(price) XP / 张")
                            .font(.headline.bold())
                            .foregroundStyle(DongbeiColors.dahong)
                    }

                    Divider()

                    HStack {
                        Label("本月已兑换", systemImage: "calendar")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(exchangedCount)/\(StreakService.monthlyExchangeLimit) 张")
                            .font(.headline.bold())
                            .foregroundStyle(reachedLimit ? DongbeiColors.dahong : DongbeiColors.meihei)
                    }
                }
                .font(.subheadline)
                .padding(Theme.spacingMD)
                .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)

                // How it works
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    Text("补卡券说明")
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    VStack(alignment: .leading, spacing: 6) {
                        ruleRow(icon: "1.circle.fill", text: "打卡标准：完成任意学习活动即为当日打卡")
                        ruleRow(icon: "2.circle.fill", text: "连续天数：每日 00:00-23:59 为一个自然日")
                        ruleRow(icon: "3.circle.fill", text: "断档时自动使用补卡券保护记录（可在设置中关闭）")
                        ruleRow(icon: "4.circle.fill", text: "获取途径：XP 兑换（梯度定价 100-300 XP）、里程碑奖励")
                        ruleRow(icon: "5.circle.fill", text: "补卡券有效期 90 天，单月最多补卡 5 天")
                        ruleRow(icon: "6.circle.fill", text: "断档超过 30 天无法补卡，连续天数重置")
                    }
                }
                .padding(Theme.spacingMD)
                .background(DongbeiColors.cuilu.opacity(0.05), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))

                Spacer()

                // Exchange button
                Group {
                    if reachedLimit {
                        Text("本月兑换已达上限")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.spacingMD - 2)
                            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    } else {
                        VStack(spacing: 4) {
                            Button {
                                showConfirmAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "ticket.fill")
                                    Text("兑换补卡券 (\(price) XP)")
                                        .font(.headline.bold())
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.spacingMD - 2)
                                .background(
                                    canAfford ? DongbeiColors.cuilu : Color.gray.opacity(0.3),
                                    in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                                )
                            }
                            .disabled(!canAfford)

                            if !canAfford {
                                Button {
                                    dismiss()
                                    NotificationCenter.default.post(name: .switchToTab, object: nil, userInfo: ["tab": 1])
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.caption)
                                        Text("去赚 XP")
                                            .font(.subheadline.bold())
                                    }
                                    .foregroundStyle(DongbeiColors.dahong)
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }.padding(.bottom, Theme.spacingMD)
            }
            .padding(.horizontal, Theme.spacingMD)
            .background(DongbeiColors.pageBackground)
            .navigationTitle("补卡券兑换")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("确认兑换", isPresented: $showConfirmAlert) {
                Button("确认") {
                    performExchange()
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("消耗 \(price) XP 兑换1张补卡券？")
            }
            .overlay {
                if exchangeSuccess {
                    exchangeSuccessToast
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func ruleRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(Theme.labelFont)
                .foregroundStyle(DongbeiColors.cuilu)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func performExchange() {
        guard !isExchanging else { return }
        isExchanging = true

        Task {
            let result = await streakService.exchangeTicket()
            await MainActor.run {
                isExchanging = false
                if result.success {
                    streakData.makeupTickets = streakService.validTicketCount()
                    appState.currentUser?.totalScore = XPService.shared.getCurrentXPSync()

                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        exchangeSuccess = true
                    }
                    HapticManager.notification(.success)
                    SoundEffectService.shared.play(.correct)

                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        withAnimation { exchangeSuccess = false }
                    }
                } else {
                    exchangeMessage = result.message
                }
            }
        }
    }

    private var exchangeSuccessToast: some View {
        VStack {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                Text("兑换成功！补卡券 +1")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
            .background(DongbeiColors.cuilu, in: Capsule())
            .shadow(color: DongbeiColors.cuilu.opacity(0.3), radius: 8, y: 4)

            Spacer()
        }
        .padding(.top, Theme.spacingLG)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Sub-components

struct DailyWordCard: View {
    let vocabulary: Vocabulary
    var onTaskProgress: (() -> Void)? = nil
    @State private var isFlipped = false
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var showAudioFallbackToast = false
    @State private var audioFallbackToastText = "音频缺失，已切换语音播报"
    @State private var hasReportedDailyTask = false
    @State private var lastRetryAction: (() -> Void)?
    
    private var dongbeiPlaybackId: String { "dailyword_dongbei_\(vocabulary.id)" }
    private var standardPlaybackId: String { "dailyword_standard_\(vocabulary.id)" }
    private var isDongbeiPlaying: Bool { audioPlayer.isPlaying && audioPlayer.currentAudioId == dongbeiPlaybackId }
    private var isStandardPlaying: Bool { audioPlayer.isPlaying && audioPlayer.currentAudioId == standardPlaybackId }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("每日一词", systemImage: "sparkles")
                    .font(.caption.bold())
                    .foregroundStyle(DongbeiColors.jinhuang)
                Spacer()
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.top, Theme.spacingMD)

            VStack(spacing: Theme.spacingSM) {
                Text(isFlipped ? vocabulary.standardWord : vocabulary.dongbeiWord)
                    .font(Theme.dongbeiWordFont)
                    .foregroundStyle(DongbeiColors.meihei)

                Text(isFlipped ? vocabulary.pinyin : vocabulary.dongbeiPinyin)
                    .font(Theme.pinyinFont)
                    .foregroundStyle(.secondary)

                if isFlipped {
                    Text(vocabulary.meaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: Theme.spacingMD) {
                    Button {
                        reportDailyTaskIfNeeded()
                        lastRetryAction = {
                            audioPlayer.playBundledAudioOrTTS(
                                fileName: vocabulary.audioFileName,
                                text: vocabulary.dongbeiWord,
                                style: .dongbei,
                                playbackId: dongbeiPlaybackId,
                                onFallbackToTTS: {
                                    showFallbackToast("东北话音频缺失，已切换语音播报")
                                },
                                onPlaybackFailed: {
                                    showFallbackToast("当前语音不可用，请稍后重试")
                                }
                            )
                        }
                        audioPlayer.playBundledAudioOrTTS(
                            fileName: vocabulary.audioFileName,
                            text: vocabulary.dongbeiWord,
                            style: .dongbei,
                            playbackId: dongbeiPlaybackId,
                            onFallbackToTTS: {
                                showFallbackToast("东北话音频缺失，已切换语音播报")
                            },
                            onPlaybackFailed: {
                                showFallbackToast("当前语音不可用，请稍后重试")
                            }
                        )
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: isDongbeiPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.title3)
                                .symbolEffectCompat(isActive: isDongbeiPlaying)
                            Text("东北话")
                                .font(Theme.tinyFont)
                            if isDongbeiPlaying {
                                Text("播放中")
                                    .font(.system(size: 9, weight: .medium))
                            }
                        }
                        .foregroundStyle(DongbeiColors.dahong)
                    }
                    .disabled(audioPlayer.isPlaying && !isDongbeiPlaying)
                    .opacity(audioPlayer.isPlaying && !isDongbeiPlaying ? 0.45 : 1)

                    Button {
                        reportDailyTaskIfNeeded()
                        lastRetryAction = {
                            audioPlayer.playBundledAudioOrTTS(
                                fileName: vocabulary.standardAudioFileName,
                                text: vocabulary.standardWord,
                                style: .standard,
                                playbackId: standardPlaybackId,
                                onFallbackToTTS: {
                                    showFallbackToast("普通话音频缺失，已切换语音播报")
                                },
                                onPlaybackFailed: {
                                    showFallbackToast("当前语音不可用，请稍后重试")
                                }
                            )
                        }
                        audioPlayer.playBundledAudioOrTTS(
                            fileName: vocabulary.standardAudioFileName,
                            text: vocabulary.standardWord,
                            style: .standard,
                            playbackId: standardPlaybackId,
                            onFallbackToTTS: {
                                showFallbackToast("普通话音频缺失，已切换语音播报")
                            },
                            onPlaybackFailed: {
                                showFallbackToast("当前语音不可用，请稍后重试")
                            }
                        )
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: isStandardPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.title3)
                                .symbolEffectCompat(isActive: isStandardPlaying)
                            Text("普通话")
                                .font(Theme.tinyFont)
                            if isStandardPlaying {
                                Text("播放中")
                                    .font(.system(size: 9, weight: .medium))
                            }
                        }
                        .foregroundStyle(DongbeiColors.cuilu)
                    }
                    .disabled(audioPlayer.isPlaying && !isStandardPlaying)
                    .opacity(audioPlayer.isPlaying && !isStandardPlaying ? 0.45 : 1)

                    Button {
                        reportDailyTaskIfNeeded()
                        withAnimation(.spring(duration: 0.4)) {
                            isFlipped.toggle()
                        }
                    } label: {
                        Text(isFlipped ? "看东北话" : "看普通话")
                            .font(.caption.bold())
                            .foregroundStyle(DongbeiColors.dahong)
                    }
                }
                .padding(.top, Theme.spacingSM)

                if showAudioFallbackToast {
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .font(.caption)
                            Text(audioFallbackToastText)
                                .font(.caption2.bold())
                                .lineLimit(1)
                        }
                        if let retry = lastRetryAction {
                            Button("重试") {
                                retry()
                            }
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.2), in: Capsule())
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DongbeiColors.huabufen, in: Capsule())
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(Theme.spacingLG)
        }
        .dongbeiCard(padding: 0)
    }

    private func showFallbackToast(_ text: String) {
        guard AudioPlayerService.isFallbackToastEnabled else { return }
        audioFallbackToastText = text
        withAnimation(.easeInOut(duration: 0.2)) {
            showAudioFallbackToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.2)) {
                showAudioFallbackToast = false
            }
        }
    }

    private func reportDailyTaskIfNeeded() {
        guard !hasReportedDailyTask else { return }
        hasReportedDailyTask = true
        _ = DailyTaskService().markDailyWordCompleted()
        onTaskProgress?()
    }
}

// MARK: - Quick Entry Card

struct QuickEntryCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
            }
            Text(title)
                .font(Theme.labelFont)
                .foregroundStyle(DongbeiColors.meihei)
            Text(subtitle)
                .font(Theme.tinyFont)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Milestone View (4e)

struct MilestoneView: View {
    let title: String
    let tickets: Int
    let xp: Int
    let onDismiss: () -> Void

    private let encouragements = [
        "老铁，贼拉！",
        "就这么干，别停！",
        "太了不起了，给你点赞！",
        "真中！继续加油！",
        "谁说今天不能再牵头，你就是牛的！"
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [DongbeiColors.dahong, DongbeiColors.jinhuang, Color(hex: 0xF9C74F)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: Theme.spacingLG) {
                Spacer()

                // Trophy
                Image(systemName: "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                // Title
                Text("🎉 里程碑达成")
                    .font(.title3.bold())
                    .foregroundStyle(.white.opacity(0.9))

                Text(title)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                // Rewards
                VStack(spacing: Theme.spacingSM) {
                    HStack(spacing: Theme.spacingMD) {
                        VStack(spacing: 4) {
                            Image(systemName: "ticket.fill")
                                .font(.title2)
                            Text("+\(tickets) 张")
                                .font(.headline.bold())
                            Text("补卡券")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)

                        Rectangle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 1, height: 50)

                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.title2)
                            Text("+\(xp)")
                                .font(.headline.bold())
                            Text("XP")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(.white)
                }
                .padding(Theme.spacingLG)
                .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
                .padding(.horizontal, Theme.spacingLG)

                // Encouragement
                Text(encouragements.randomElement() ?? "继续加油！")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, Theme.spacingSM)

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Text("继续加油")
                        .font(.headline.bold())
                        .foregroundStyle(DongbeiColors.dahong)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.spacingMD)
                        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
                .padding(.horizontal, Theme.spacingLG)
                .padding(.bottom, Theme.spacingXL)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToTab = Notification.Name("laotie_switch_to_tab")
    static let streakDidRecord = Notification.Name("laotie_streak_did_record")
}

