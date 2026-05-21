import SwiftUI

struct VocabularyListView: View {
    @StateObject private var viewModel = VocabularyListViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.spacingSM) {
                        CategoryChip(
                            title: "全部",
                            icon: "square.grid.2x2",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(VocabularyCategory.allCases, id: \.self) { cat in
                            CategoryChip(
                                title: cat.rawValue,
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

                // Difficulty filter
                Picker("难度", selection: $viewModel.selectedDifficulty) {
                    Text("全部难度").tag(Difficulty?.none)
                    ForEach(Difficulty.allCases, id: \.self) { diff in
                        Text(diff.rawValue).tag(Difficulty?.some(diff))
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, Theme.spacingMD)
                .padding(.bottom, Theme.spacingSM)

                // Vocabulary list
                List {
                    ForEach(viewModel.filteredVocabularies) { vocab in
                        NavigationLink {
                            FlashcardView(vocabulary: vocab)
                        } label: {
                            VocabCardRow(vocabulary: vocab)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("学词儿")
            .task { await viewModel.loadData() }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, Theme.spacingMD - 4)
            .padding(.vertical, Theme.spacingSM)
            .background(isSelected ? DongbeiColors.dahong : .white)
            .foregroundStyle(isSelected ? .white : DongbeiColors.meihei)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

struct VocabCardRow: View {
    let vocabulary: Vocabulary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vocabulary.dongbeiWord)
                    .font(.title3.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Text(vocabulary.standardWord)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(vocabulary.dongbeiPinyin)
                    .font(Theme.pinyinFont)
                    .foregroundStyle(DongbeiColors.dahong)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    ForEach(0..<vocabulary.difficulty.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }
                Text(vocabulary.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DongbeiColors.huabufen.opacity(0.15))
                    .foregroundStyle(DongbeiColors.huabufen)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

@MainActor
final class VocabularyListViewModel: ObservableObject {
    @Published var vocabularies: [Vocabulary] = []
    @Published var selectedCategory: VocabularyCategory?
    @Published var selectedDifficulty: Difficulty?

    private let repository = VocabularyRepository()

    var filteredVocabularies: [Vocabulary] {
        vocabularies.filter { vocab in
            let matchesCategory = selectedCategory == nil || vocab.category == selectedCategory
            let matchesDifficulty = selectedDifficulty == nil || vocab.difficulty == selectedDifficulty
            return matchesCategory && matchesDifficulty
        }
    }

    func loadData() async {
        do {
            vocabularies = try await repository.fetchAll()
        } catch {
            // Keep empty
        }
    }
}
