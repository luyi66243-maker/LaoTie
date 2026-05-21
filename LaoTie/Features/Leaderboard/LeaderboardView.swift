import SwiftUI

struct LeaderboardView: View {
    @State private var entries: [LeaderboardEntry] = []
    @State private var isLoading = true
    private let repository = LeaderboardRepository()

    var body: some View {
        List {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(spacing: Theme.spacingMD) {
                    // Rank
                    ZStack {
                        Circle()
                            .fill(rankColor(index))
                            .frame(width: 32, height: 32)
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                    }

                    // Avatar
                    ZStack {
                        Circle()
                            .fill(DongbeiColors.binglan)
                            .frame(width: 40, height: 40)
                        Text(String(entry.nickname.prefix(1)))
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.nickname)
                            .font(.subheadline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                        Text(entry.currentTitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Score
                    Text("\(entry.totalScore)")
                        .font(.headline.bold())
                        .foregroundColor(DongbeiColors.jinhuang)
                    + Text(" XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(.plain)
        .navigationTitle("排行榜")
        .overlay {
            if isLoading {
                ProgressView()
            }
            if !isLoading && entries.isEmpty {
                VStack(spacing: Theme.spacingMD) {
                    Image(systemName: "trophy")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("暂无排行数据")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .task { await loadData() }
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: DongbeiColors.jinhuang
        case 1: Color.gray
        case 2: DongbeiColors.huabufen
        default: DongbeiColors.binglan
        }
    }

    private func loadData() async {
        do {
            entries = try await repository.fetchTopEntries()
        } catch {
            // Keep empty
        }
        isLoading = false
    }
}
