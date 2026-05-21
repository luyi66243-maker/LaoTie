import SwiftUI

struct DailyQuoteCard: View {
    @State private var quote: DailyQuote = .preview
    @State private var isLoading = true
    @State private var showTranslation = false
    @State private var refreshCount = 0

    private let repo = DailyQuoteRepository()

    var body: some View {
        VStack(spacing: Theme.spacingMD) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption.bold())
                        .foregroundStyle(DongbeiColors.dahong)
                    Text("每日金句")
                        .font(Theme.labelFont)
                        .foregroundStyle(DongbeiColors.meihei)
                }

                Spacer()

                // Category tag
                HStack(spacing: 4) {
                    Image(systemName: quote.category.icon)
                        .font(.caption2)
                    Text(quote.category.displayName)
                        .font(Theme.badgeFont)
                }
                .foregroundStyle(categoryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(categoryColor.opacity(0.1), in: Capsule())
            }

            // Quote text
            VStack(spacing: Theme.spacingSM) {
                Text(quote.dongbeiText)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(DongbeiColors.meihei)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                if showTranslation {
                    VStack(spacing: 6) {
                        Text(quote.standardText)
                            .font(Theme.captionFont)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Text(quote.explanation)
                            .font(Theme.captionFont)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }

            // Bottom actions
            HStack {
                // Mood tag
                HStack(spacing: 4) {
                    Image(systemName: "face.smiling")
                        .font(.caption2)
                    Text(quote.mood)
                        .font(Theme.badgeFont)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Show/hide translation
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTranslation.toggle()
                    }
                } label: {
                    Image(systemName: showTranslation ? "eye.slash" : "eye")
                        .font(.caption)
                        .foregroundStyle(DongbeiColors.cuilu)
                        .padding(6)
                        .background(DongbeiColors.cuilu.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)

                // Refresh button
                Button {
                    Task { await refreshQuote() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundStyle(DongbeiColors.dahong)
                        .padding(6)
                        .background(DongbeiColors.dahong.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .dongbeiCard()
        .task {
            await loadQuote()
        }
    }

    private var categoryColor: Color {
        switch quote.category {
        case .duJiTang: DongbeiColors.huabufen
        case .tuWeiQingHua: DongbeiColors.dahong
        case .yanYu: DongbeiColors.cuilu
        case .jingDianYuLu: DongbeiColors.jinhuang
        }
    }

    private func loadQuote() async {
        do {
            quote = try await repo.getQuoteOfTheDay()
            isLoading = false
        } catch {
            isLoading = false
        }
    }

    private func refreshQuote() async {
        showTranslation = false
        do {
            if let newQuote = try await repo.getRandomQuote() {
                withAnimation(.easeInOut(duration: 0.3)) {
                    quote = newQuote
                }
                refreshCount += 1
            }
        } catch {
            // Keep current
        }
    }
}
