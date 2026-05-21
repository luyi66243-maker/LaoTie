import SwiftUI

struct MemeDetailView: View {
    let meme: DongbeiMeme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingLG) {
                // Header card
                headerSection

                // Content sections
                contentSection

                if let origin = meme.origin, !origin.isEmpty {
                    originSection(origin)
                }

                usageSection

                examplesSection

                if let funFact = meme.funFact, !funFact.isEmpty {
                    funFactSection(funFact)
                }
            }
            .padding(Theme.spacingMD)
            .padding(.bottom, Theme.spacingXL)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.spacingMD) {
            Text(meme.title)
                .font(Theme.titleFont)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            MemeCategoryBadge(category: meme.category)
        }
        .padding(Theme.spacingLG)
        .frame(maxWidth: .infinity)
        .background(DongbeiColors.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
    }

    // MARK: - Content

    private var contentSection: some View {
        DetailSectionCard(
            icon: "doc.text.fill",
            title: "解读",
            iconColor: DongbeiColors.dahong
        ) {
            Text(meme.content)
                .font(Theme.bodyFont)
                .foregroundStyle(DongbeiColors.meihei)
                .lineSpacing(6)
        }
    }

    // MARK: - Origin

    private func originSection(_ origin: String) -> some View {
        DetailSectionCard(
            icon: "clock.arrow.circlepath",
            title: "来源典故",
            iconColor: DongbeiColors.cuilu
        ) {
            Text(origin)
                .font(Theme.bodyFont)
                .foregroundStyle(DongbeiColors.meihei.opacity(0.8))
                .lineSpacing(4)
        }
    }

    // MARK: - Usage

    private var usageSection: some View {
        DetailSectionCard(
            icon: "bubble.left.and.bubble.right.fill",
            title: "使用场景",
            iconColor: DongbeiColors.huabufen
        ) {
            Text(meme.usage)
                .font(Theme.bodyFont)
                .foregroundStyle(DongbeiColors.meihei.opacity(0.8))
                .lineSpacing(4)
        }
    }

    // MARK: - Examples

    private var examplesSection: some View {
        DetailSectionCard(
            icon: "text.bubble.fill",
            title: "用法示例",
            iconColor: DongbeiColors.jinhuang
        ) {
            VStack(alignment: .leading, spacing: Theme.spacingSM) {
                ForEach(Array(meme.examples.enumerated()), id: \.offset) { _, example in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Image(systemName: "quote.opening")
                            .font(.caption2)
                            .foregroundStyle(DongbeiColors.dahong.opacity(0.5))
                            .padding(.top, 2)
                        Text(example)
                            .font(Theme.bodyFont)
                            .foregroundStyle(DongbeiColors.meihei)
                            .italic()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Fun Fact

    private func funFactSection(_ fact: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingSM + 4) {
            Image(systemName: "lightbulb.fill")
                .font(.title3)
                .foregroundStyle(DongbeiColors.jinhuang)
            VStack(alignment: .leading, spacing: 4) {
                Text("冷知识")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(DongbeiColors.meihei)
                Text(fact)
                    .font(Theme.bodyFont)
                    .foregroundStyle(DongbeiColors.meihei.opacity(0.8))
                    .lineSpacing(4)
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DongbeiColors.jinhuang.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(DongbeiColors.jinhuang.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Section Card

private struct DetailSectionCard<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM + 4) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(DongbeiColors.meihei)
            }

            content
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DongbeiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: Theme.cardShadowColor, radius: Theme.cardShadowRadius, y: Theme.cardShadowY)
    }
}
