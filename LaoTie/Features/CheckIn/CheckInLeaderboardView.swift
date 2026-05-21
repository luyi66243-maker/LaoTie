import SwiftUI

struct CheckInLeaderboardView: View {
    @State private var entries: [CheckInLeaderboardEntry] = []
    private let repo = CheckInRepository()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingMD) {
                // Podium top 3
                if entries.count >= 3 {
                    podiumView
                }

                // Full list
                VStack(spacing: Theme.spacingSM) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        leaderboardRow(rank: index + 1, entry: entry)
                    }
                }
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("打卡排行榜")
        .task { await loadData() }
    }

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: Theme.spacingSM) {
            // 2nd place
            if entries.count > 1 {
                podiumItem(rank: 2, entry: entries[1], height: 90, color: Color.gray)
            }

            // 1st place
            if entries.count > 0 {
                podiumItem(rank: 1, entry: entries[0], height: 120, color: DongbeiColors.jinhuang)
            }

            // 3rd place
            if entries.count > 2 {
                podiumItem(rank: 3, entry: entries[2], height: 70, color: DongbeiColors.huabufen)
            }
        }
        .padding(.top, Theme.spacingLG)
        .padding(.bottom, Theme.spacingMD)
    }

    private func podiumItem(rank: Int, entry: CheckInLeaderboardEntry, height: CGFloat, color: Color) -> some View {
        VStack(spacing: 6) {
            // Avatar
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(String(entry.nickname.prefix(1)))
                    .font(.title3.bold())
                    .foregroundStyle(color)
            }

            Text(entry.nickname)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DongbeiColors.meihei)
                .lineLimit(1)

            Text("\(entry.checkInCount)个景点")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

            // Podium block
            VStack {
                Text("\(rank)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(color, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private func leaderboardRow(rank: Int, entry: CheckInLeaderboardEntry) -> some View {
        let isMe = entry.id == "lb_me"
        return HStack(spacing: Theme.spacingMD) {
            // Rank
            Text("\(rank)")
                .font(.headline.bold().monospacedDigit())
                .foregroundStyle(rank <= 3 ? DongbeiColors.jinhuang : .secondary)
                .frame(width: 30)

            // Avatar
            ZStack {
                Circle()
                    .fill(isMe ? DongbeiColors.dahong.opacity(0.15) : DongbeiColors.meihei.opacity(0.08))
                    .frame(width: 40, height: 40)
                Text(String(entry.nickname.prefix(1)))
                    .font(.subheadline.bold())
                    .foregroundStyle(isMe ? DongbeiColors.dahong : DongbeiColors.meihei)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.nickname)
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.meihei)
                    if isMe {
                        Text("我")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(DongbeiColors.dahong, in: Capsule())
                    }
                }

                if !entry.latestScenic.isEmpty {
                    Text("最近: \(entry.latestScenic)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("可信度: \(entry.authenticityLevel.label)")
                    .font(.caption2.bold())
                    .foregroundStyle(authenticityColor(entry.authenticityLevel))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.checkInCount)")
                    .font(.headline.bold().monospacedDigit())
                    .foregroundStyle(DongbeiColors.cuilu)
                Text("景点")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.spacingMD)
        .background(
            isMe ? DongbeiColors.dahong.opacity(0.05) : .white,
            in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(isMe ? DongbeiColors.dahong.opacity(0.3) : .clear, lineWidth: 1)
        )
    }

    private func loadData() async {
        entries = (try? await repo.fetchLeaderboard()) ?? []
    }

    private func authenticityColor(_ level: ScenicCheckIn.Authenticity.Level) -> Color {
        switch level {
        case .high: DongbeiColors.cuilu
        case .medium: DongbeiColors.jinhuang
        case .low: DongbeiColors.dahong
        }
    }
}
