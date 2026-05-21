import SwiftUI

struct TongueTwisterListView: View {
    @State private var twisters: [TongueTwister] = []
    @State private var selectedCategory: String? = nil
    @State private var selectedTwister: TongueTwister? = nil

    private let repo = TongueTwisterRepository()
    private let categories = ["平翘舌", "儿化音", "语速挑战", "东北特色"]

    var body: some View {
        NavigationStack {
            ZStack {
                DongbeiColors.pageBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingMD) {
                        // Category filter
                        categoryFilter

                        // Twister cards
                        if filteredTwisters.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: Theme.spacingMD) {
                                ForEach(filteredTwisters) { twister in
                                    NavigationLink(value: twister.id) {
                                        TwisterCard(twister: twister)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, Theme.spacingMD)
                        }
                    }
                    .padding(.bottom, Theme.spacingXL)
                }
            }
            .navigationTitle("绕口令挑战")
            .navigationDestination(for: String.self) { twisterId in
                if let twister = twisters.first(where: { $0.id == twisterId }) {
                    TongueTwisterPracticeView(
                        twister: twister,
                        allTwisters: filteredTwisters
                    )
                }
            }
            .task { await loadData() }
        }
    }

    private var filteredTwisters: [TongueTwister] {
        guard let category = selectedCategory else { return twisters }
        return twisters.filter { $0.category == category }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingSM) {
                FilterChip(title: "全部", isSelected: selectedCategory == nil) {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedCategory = nil }
                }
                ForEach(categories, id: \.self) { category in
                    FilterChip(title: category, isSelected: selectedCategory == category) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "mouth")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("暂无绕口令")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.spacingXXL)
    }

    private func loadData() async {
        do {
            twisters = try await repo.fetchAll()
        } catch {
            // Keep empty
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.labelFont)
                .foregroundStyle(isSelected ? .white : DongbeiColors.meihei)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    isSelected ? DongbeiColors.dahong : DongbeiColors.cardBackground,
                    in: Capsule()
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Twister Card

private struct TwisterCard: View {
    let twister: TongueTwister

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            // Header
            HStack {
                Text(twister.title)
                    .font(Theme.headlineFont)
                    .foregroundStyle(DongbeiColors.meihei)

                Spacer()

                // Difficulty stars
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < twister.difficulty ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i < twister.difficulty ? DongbeiColors.jinhuang : .gray.opacity(0.3))
                    }
                }
            }

            // Content preview
            Text(twister.content)
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Category tag
            HStack {
                Text(twister.category)
                    .font(Theme.badgeFont)
                    .foregroundStyle(categoryColor(twister.category))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor(twister.category).opacity(0.1), in: Capsule())

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .dongbeiCard()
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "平翘舌": DongbeiColors.dahong
        case "儿化音": DongbeiColors.cuilu
        case "语速挑战": DongbeiColors.jinhuang
        case "东北特色": DongbeiColors.huabufen
        default: DongbeiColors.binglan
        }
    }
}
