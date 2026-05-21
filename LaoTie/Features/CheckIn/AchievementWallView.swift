import SwiftUI

struct AchievementWallView: View {
    @State private var achievements: [Achievement] = []
    @State private var checkIns: [ScenicCheckIn] = []
    private let repo = CheckInRepository()

    private var approvedCount: Int {
        checkIns.filter { $0.status == .approved }.count
    }

    private var uniqueScenicCount: Int {
        Set(checkIns.filter { $0.status == .approved }.map(\.scenicId)).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                // Stats header
                statsHeader

                // Achievement grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.spacingMD) {
                    ForEach(achievements) { ach in
                        AchievementCard(achievement: ach)
                    }
                }

                // Recent check-ins
                if !checkIns.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.spacingMD) {
                        Text("我的打卡记录")
                            .font(Theme.headlineFont)
                            .foregroundStyle(DongbeiColors.meihei)

                        ForEach(checkIns.prefix(10)) { checkIn in
                            CheckInRow(checkIn: checkIn)
                        }
                    }
                }
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("成就墙")
        .task { await loadData() }
    }

    private var statsHeader: some View {
        HStack(spacing: 0) {
            statItem(value: "\(approvedCount)", label: "总打卡", color: DongbeiColors.dahong)
            Divider().frame(height: 40)
            statItem(value: "\(uniqueScenicCount)", label: "不同景点", color: DongbeiColors.cuilu)
            Divider().frame(height: 40)
            statItem(
                value: "\(achievements.filter(\.isUnlocked).count)/\(achievements.count)",
                label: "成就解锁",
                color: DongbeiColors.jinhuang
            )
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private func statItem(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadData() async {
        achievements = (try? await repo.fetchAchievements()) ?? Achievement.allAchievements
        checkIns = (try? await repo.fetchCheckIns()) ?? []
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? DongbeiColors.jinhuang.opacity(0.15) : Color.gray.opacity(0.08))
                    .frame(width: 56, height: 56)

                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundStyle(achievement.isUnlocked ? DongbeiColors.jinhuang : .gray.opacity(0.4))
            }

            Text(achievement.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(achievement.isUnlocked ? DongbeiColors.meihei : .secondary)
                .lineLimit(1)

            Text("打卡\(achievement.requirement)次")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            if achievement.isUnlocked {
                Text("+\(achievement.rewardXP)XP")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(DongbeiColors.cuilu)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingSM)
        .background(
            achievement.isUnlocked ? Color.white : Color.white.opacity(0.5),
            in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
        )
        .shadow(color: .black.opacity(achievement.isUnlocked ? 0.05 : 0), radius: 4, y: 2)
    }
}

struct CheckInRow: View {
    let checkIn: ScenicCheckIn

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.title3)
                .foregroundStyle(statusColor)
                .frame(width: 36, height: 36)
                .background(statusColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(checkIn.scenicName)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)

                HStack(spacing: 4) {
                    Text(checkIn.province)
                        .font(.caption2)
                    Text("·")
                    Text(checkIn.submittedAt.formatted(.dateTime.month().day()))
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text("可信度")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(checkIn.authenticity.level.label)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(authenticityColor.opacity(0.9), in: Capsule())
                }
            }

            Spacer()

            Text(statusText)
                .font(.caption2.bold())
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(Theme.spacingSM)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    private var statusIcon: String {
        switch checkIn.status {
        case .approved: "checkmark.circle.fill"
        case .pending: "clock.fill"
        case .rejected: "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch checkIn.status {
        case .approved: DongbeiColors.cuilu
        case .pending: DongbeiColors.jinhuang
        case .rejected: DongbeiColors.dahong
        }
    }

    private var statusText: String {
        switch checkIn.status {
        case .approved: "已通过"
        case .pending: "审核中"
        case .rejected: "未通过"
        }
    }

    private var authenticityColor: Color {
        switch checkIn.authenticity.level {
        case .high: DongbeiColors.cuilu
        case .medium: DongbeiColors.jinhuang
        case .low: DongbeiColors.dahong
        }
    }
}
