import SwiftUI

struct MemeListView: View {
    @StateObject private var viewModel = MemeListViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingSM) {
                        CategoryChip(
                            title: "全部",
                            icon: "square.grid.2x2",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(MemeCategory.allCases, id: \.self) { cat in
                            CategoryChip(
                                title: cat.displayName,
                                icon: cat.icon,
                                isSelected: viewModel.selectedCategory == cat
                            ) {
                                viewModel.selectedCategory = cat
                            }
                        }
                    }
                    .padding(.horizontal, Theme.spacingMD)
                }
                .padding(.vertical, Theme.spacingSM)

                // Search bar
                HStack(spacing: Theme.spacingSM) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(DongbeiColors.meihei.opacity(0.4))
                    TextField("搜索梗、歇后语、文化知识…", text: $viewModel.searchText)
                        .font(Theme.bodyFont)
                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(DongbeiColors.meihei.opacity(0.3))
                        }
                    }
                }
                .padding(Theme.spacingSM + 4)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.bottom, Theme.spacingSM)

                // Meme list
                if viewModel.filteredMemes.isEmpty {
                    Spacer()
                    VStack(spacing: Theme.spacingMD) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(DongbeiColors.meihei.opacity(0.2))
                        Text("没找到相关内容")
                            .font(Theme.headlineFont)
                            .foregroundStyle(DongbeiColors.meihei.opacity(0.4))
                        Text("换个关键词试试？")
                            .font(Theme.captionFont)
                            .foregroundStyle(DongbeiColors.meihei.opacity(0.3))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.spacingSM + 4) {
                            ForEach(viewModel.filteredMemes) { meme in
                                NavigationLink {
                                    MemeDetailView(meme: meme)
                                } label: {
                                    MemeCardRow(meme: meme)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.bottom, Theme.spacingLG)
                    }
                }
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("梗库")
            .task { await viewModel.loadData() }
        }
    }
}

// MARK: - Card Row

struct MemeCardRow: View {
    let meme: DongbeiMeme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meme.title)
                        .font(.headline.bold())
                        .foregroundStyle(DongbeiColors.meihei)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                MemeCategoryBadge(category: meme.category)
            }

            Text(meme.content)
                .font(Theme.captionFont)
                .foregroundStyle(DongbeiColors.meihei.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(Theme.spacingMD)
        .background(DongbeiColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .shadow(color: Theme.cardShadowColor, radius: Theme.cardShadowRadius, y: Theme.cardShadowY)
    }
}

// MARK: - Category Badge

struct MemeCategoryBadge: View {
    let category: MemeCategory

    private var badgeColor: Color {
        switch category {
        case .classicMeme: DongbeiColors.dahong
        case .cultureTip: DongbeiColors.cuilu
        case .xiehouyu: DongbeiColors.jinhuang
        case .usageGuide: DongbeiColors.huabufen
        }
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.icon)
                .font(.system(size: 9))
            Text(category.displayName)
                .font(Theme.badgeFont)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(badgeColor.opacity(0.12))
        .foregroundStyle(badgeColor)
        .clipShape(Capsule())
    }
}

// MARK: - ViewModel

@MainActor
final class MemeListViewModel: ObservableObject {
    @Published var memes: [DongbeiMeme] = []
    @Published var selectedCategory: MemeCategory?
    @Published var searchText: String = ""

    private let repository = MemeRepository()

    var filteredMemes: [DongbeiMeme] {
        memes.filter { meme in
            let matchesCategory = selectedCategory == nil || meme.category == selectedCategory
            let matchesSearch = searchText.isEmpty || {
                let q = searchText.lowercased()
                return meme.title.lowercased().contains(q)
                    || meme.content.lowercased().contains(q)
                    || meme.usage.lowercased().contains(q)
                    || meme.examples.contains(where: { $0.lowercased().contains(q) })
            }()
            return matchesCategory && matchesSearch
        }
    }

    func loadData() async {
        do {
            memes = try await repository.fetchAll()
        } catch {
            // Keep empty
        }
    }
}
