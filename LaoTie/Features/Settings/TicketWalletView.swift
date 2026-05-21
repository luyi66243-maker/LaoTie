import SwiftUI

struct TicketWalletView: View {
    @State private var tickets: [MakeupTicket] = []

    private let streakService = StreakService()

    private var validTickets: [MakeupTicket] {
        tickets.filter { $0.isValid }
    }

    private var usedTickets: [MakeupTicket] {
        tickets.filter { $0.isUsed }
    }

    private var expiredTickets: [MakeupTicket] {
        tickets.filter { !$0.isUsed && $0.isExpired }
    }

    private var expiringCount: Int {
        validTickets.filter { $0.daysUntilExpiry <= 3 }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingMD) {
                // MARK: - Overview Card
                overviewCard

                // MARK: - Ticket Lists
                if tickets.isEmpty {
                    emptyState
                } else {
                    if !validTickets.isEmpty {
                        ticketSection(title: "可用补卡券", tickets: validTickets, style: .valid)
                    }
                    if !usedTickets.isEmpty {
                        ticketSection(title: "已使用", tickets: usedTickets, style: .used)
                    }
                    if !expiredTickets.isEmpty {
                        ticketSection(title: "已过期", tickets: expiredTickets, style: .expired)
                    }
                }

                // MARK: - Rules
                rulesCard
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("补卡券管理")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadTickets() }
    }

    // MARK: - Overview

    private var overviewCard: some View {
        HStack(spacing: Theme.spacingLG) {
            VStack(spacing: 4) {
                Text("\(validTickets.count)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(DongbeiColors.cuilu)
                Text("可用券")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 40)

            VStack(spacing: 4) {
                Text("\(expiringCount)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(expiringCount > 0 ? DongbeiColors.dahong : .secondary)
                Text("即将过期")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.spacingLG)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingSM) {
            Image(systemName: "ticket")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("还没有补卡券？")
                .font(.headline)
                .foregroundStyle(DongbeiColors.meihei)
            Text("去兑换或完成里程碑获取吧")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXL)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Ticket Section

    private enum TicketStyle { case valid, used, expired }

    private func ticketSection(title: String, tickets: [MakeupTicket], style: TicketStyle) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(tickets) { ticket in
                    ticketRow(ticket: ticket, style: style)
                    if ticket.id != tickets.last?.id {
                        Divider().padding(.leading, 40)
                    }
                }
            }
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
    }

    private func ticketRow(ticket: MakeupTicket, style: TicketStyle) -> some View {
        HStack(spacing: Theme.spacingSM) {
            // Source icon
            ZStack {
                Circle()
                    .fill(iconColor(for: style).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: sourceIcon(for: ticket.source))
                    .font(.caption)
                    .foregroundStyle(iconColor(for: style))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sourceLabel(for: ticket.source))
                    .font(.subheadline)
                    .foregroundStyle(style == .expired ? .secondary : DongbeiColors.meihei)

                Text(formatDate(ticket.obtainedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            switch style {
            case .valid:
                let days = ticket.daysUntilExpiry
                if days <= 3 {
                    HStack(spacing: 2) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                        Text("\(days)天后过期")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(DongbeiColors.dahong)
                } else {
                    Text("剩余\(days)天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .used:
                VStack(alignment: .trailing, spacing: 2) {
                    Text("已使用")
                        .font(.caption.bold())
                        .foregroundStyle(DongbeiColors.cuilu)
                    if let usedDate = ticket.usedForDate {
                        Text("补 \(usedDate)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            case .expired:
                Text("已过期")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.spacingSM + 4)
        .opacity(style == .expired ? 0.5 : 1)
    }

    // MARK: - Rules Card

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            Label("补卡券规则", systemImage: "info.circle.fill")
                .font(.subheadline.bold())
                .foregroundStyle(DongbeiColors.meihei)

            VStack(alignment: .leading, spacing: 8) {
                ruleItem(num: "1", text: "打卡标准：完成任意学习活动即为当日打卡")
                ruleItem(num: "2", text: "连续天数：每日 00:00-23:59 为一个自然日")
                ruleItem(num: "3", text: "断档时自动使用补卡券保护连续记录")
                ruleItem(num: "4", text: "获取途径：XP 兑换（100-300 XP）、里程碑奖励")
                ruleItem(num: "5", text: "补卡券有效期 90 天，单月最多补卡 5 天")
                ruleItem(num: "6", text: "断档超过 30 天无法补卡，连续天数重置")
            }
        }
        .padding(Theme.spacingMD)
        .background(DongbeiColors.cuilu.opacity(0.05), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    private func ruleItem(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(DongbeiColors.cuilu, in: Circle())
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func loadTickets() {
        tickets = streakService.loadTickets()
    }

    private func sourceIcon(for source: MakeupTicket.TicketSource) -> String {
        switch source {
        case .xpExchange: return "arrow.triangle.2.circlepath"
        case .milestoneReward: return "trophy.fill"
        case .newUserBonus: return "gift.fill"
        case .dailyTaskReward: return "checkmark.circle.fill"
        }
    }

    private func sourceLabel(for source: MakeupTicket.TicketSource) -> String {
        switch source {
        case .xpExchange: return "XP 兑换"
        case .milestoneReward: return "里程碑奖励"
        case .newUserBonus: return "新用户福利"
        case .dailyTaskReward: return "每日任务奖励"
        }
    }

    private func iconColor(for style: TicketStyle) -> Color {
        switch style {
        case .valid: return DongbeiColors.cuilu
        case .used: return DongbeiColors.binglan
        case .expired: return .gray
        }
    }

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private func formatDate(_ date: Date) -> String {
        Self.displayDateFormatter.string(from: date)
    }
}
