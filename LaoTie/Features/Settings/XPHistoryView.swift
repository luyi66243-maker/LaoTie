import SwiftUI

struct XPHistoryView: View {
    @State private var transactions: [XPTransaction] = []
    @State private var currentXP: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingMD) {
                // MARK: - Balance Card
                balanceCard

                // MARK: - Transaction List
                if transactions.isEmpty {
                    emptyState
                } else {
                    let grouped = groupedTransactions
                    ForEach(grouped.keys.sorted().reversed(), id: \.self) { key in
                        if let items = grouped[key] {
                            transactionSection(title: sectionTitle(for: key), items: items)
                        }
                    }
                }
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("积分明细")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
    }

    // MARK: - Balance

    private var balanceCard: some View {
        VStack(spacing: 4) {
            Text("当前积分")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(currentXP)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(DongbeiColors.jinhuang)
                Text("XP")
                    .font(.headline.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.spacingLG)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingSM) {
            Image(systemName: "star")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("还没有积分记录")
                .font(.headline)
                .foregroundStyle(DongbeiColors.meihei)
            Text("快去学习赚取 XP 吧")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXL)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Transaction Section

    private func transactionSection(title: String, items: [XPTransaction]) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(items) { tx in
                    transactionRow(tx)
                    if tx.id != items.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    private func transactionRow(_ tx: XPTransaction) -> some View {
        HStack(spacing: Theme.spacingSM) {
            // Icon
            ZStack {
                Circle()
                    .fill(sourceColor(tx.sourceType).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: sourceIcon(tx.sourceType))
                    .font(.caption)
                    .foregroundStyle(sourceColor(tx.sourceType))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.source)
                    .font(.subheadline)
                    .foregroundStyle(DongbeiColors.meihei)
                    .lineLimit(1)
                Text(formatTime(tx.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tx.amount > 0 ? "+\(tx.amount)" : "\(tx.amount)")
                    .font(.headline.bold())
                    .foregroundStyle(tx.amount > 0 ? DongbeiColors.cuilu : DongbeiColors.dahong)
                Text("余额 \(tx.balance)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.spacingSM + 4)
    }

    // MARK: - Grouping

    private var groupedTransactions: [String: [XPTransaction]] {
        Dictionary(grouping: transactions) { tx in
            Self.dayFormatter.string(from: tx.timestamp)
        }
    }

    private func sectionTitle(for dateKey: String) -> String {
        let today = Self.dayFormatter.string(from: Date())
        if dateKey == today { return "今天" }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayKey = Self.dayFormatter.string(from: yesterday)
        if dateKey == yesterdayKey { return "昨天" }
        return dateKey
    }

    // MARK: - Helpers

    private func loadData() {
        currentXP = XPService.shared.getCurrentXPSync()
        transactions = XPService.shared.getTransactionHistory()
    }

    private func sourceIcon(_ type: XPTransaction.XPSourceType) -> String {
        switch type {
        case .quizPass: return "gamecontroller.fill"
        case .checkIn: return "flag.fill"
        case .dailyTaskReward: return "checkmark.circle.fill"
        case .achievementUnlock: return "trophy.fill"
        case .streakBonus: return "flame.fill"
        case .ticketExchange: return "ticket.fill"
        case .milestoneReward: return "star.fill"
        }
    }

    private func sourceColor(_ type: XPTransaction.XPSourceType) -> Color {
        switch type {
        case .quizPass: return DongbeiColors.dahong
        case .checkIn: return DongbeiColors.cuilu
        case .dailyTaskReward: return DongbeiColors.jinhuang
        case .achievementUnlock: return DongbeiColors.huabufen
        case .streakBonus: return DongbeiColors.jinhuang
        case .ticketExchange: return DongbeiColors.binglan
        case .milestoneReward: return DongbeiColors.dahong
        }
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = .current
        return f
    }()

    private func formatTime(_ date: Date) -> String {
        Self.timeFormatter.string(from: date)
    }
}
