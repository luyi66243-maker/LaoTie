import SwiftUI

// MARK: - Search Result Type

enum SearchResultItem: Identifiable {
    case vocabulary(Vocabulary)
    case place(DongbeiPlace)

    var id: String {
        switch self {
        case .vocabulary(let v): "vocab_\(v.id)"
        case .place(let p): "place_\(p.id)"
        }
    }
}

// MARK: - Main Search View

struct DialectSearchView: View {
    @Environment(\.openURL) var openURL
    @State private var searchText = ""
    @State private var vocabResults: [Vocabulary] = []
    @State private var placeResults: [DongbeiPlace] = []
    @State private var allVocabularies: [Vocabulary] = []
    @State private var allPlaces: [DongbeiPlace] = []
    @State private var isLoaded = false
    @State private var selectedPlace: DongbeiPlace?
    @FocusState private var isSearchFocused: Bool

    private let vocabRepo = VocabularyRepository()
    private let placeRepo = PlaceRepository()

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var hasResults: Bool {
        !vocabResults.isEmpty || !placeResults.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                TextField("搜东北话、地名、景点、美食...", text: $searchText)
                    .font(.subheadline)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: searchText) { _ in
                        performSearch()
                    }

                if isSearching {
                    Button {
                        searchText = ""
                        isSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .shadow(color: .black.opacity(0.05), radius: 6, y: 2)

            // Search results
            if isSearching {
                if !hasResults {
                    emptyResultView
                } else {
                    resultsSection
                }
            }
        }
        .task {
            guard !isLoaded else { return }
            allVocabularies = (try? await vocabRepo.fetchAll()) ?? []
            allPlaces = await placeRepo.fetchAll()
            isLoaded = true
        }
        .sheet(item: $selectedPlace) { place in
            PlaceDetailView(place: place)
        }
    }

    // MARK: - Search Logic

    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else {
            vocabResults = []
            placeResults = []
            return
        }

        vocabResults = allVocabularies.filter { vocab in
            vocab.dongbeiWord.lowercased().contains(query)
            || vocab.dongbeiPinyin.lowercased().contains(query)
            || vocab.standardWord.lowercased().contains(query)
            || vocab.meaning.lowercased().contains(query)
            || vocab.pinyin.lowercased().contains(query)
        }

        placeResults = allPlaces.filter { place in
            place.name.lowercased().contains(query)
            || place.province.lowercased().contains(query)
            || place.culture.lowercased().contains(query)
            || place.signatureDishes.contains { $0.lowercased().contains(query) }
            || place.famousSpots.contains { $0.lowercased().contains(query) }
        }
    }

    // MARK: - Sub Views

    private func openWebSearch() {
        let query = "东北话 \(searchText)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://www.baidu.com/s?wd=\(query)") {
            openURL(url)
        }
    }

    private var emptyResultView: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "questionmark.bubble")
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.4))
            
            VStack(spacing: Theme.spacingXS) {
                Text("没找到「\(searchText)」")
                    .font(Theme.subheadlineFont)
                    .foregroundStyle(.secondary)
                Text("APP 里暂时没收录这个词")
                    .font(Theme.captionFont)
                    .foregroundStyle(.tertiary)
            }
            
            Button(action: openWebSearch) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.subheadline)
                    Text("去网上搜搜")
                        .font(Theme.labelFont)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.spacingLG)
                .padding(.vertical, Theme.spacingSM + 2)
                .background(DongbeiColors.dahong, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXL)
        .dongbeiCard(padding: Theme.spacingLG)
        .padding(.top, Theme.spacingSM)
    }

    private var resultsSection: some View {
        VStack(spacing: Theme.spacingSM) {
            // Place results
            if !placeResults.isEmpty {
                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.cuilu)
                        Text("地名")
                            .font(.caption.bold())
                            .foregroundStyle(DongbeiColors.cuilu)
                        Spacer()
                        Text("\(placeResults.count)个结果")
                            .font(Theme.badgeFont)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DongbeiColors.cuilu.opacity(0.05))

                    ForEach(Array(placeResults.prefix(5).enumerated()), id: \.element.id) { index, place in
                        if index > 0 {
                            Divider().padding(.horizontal, 12)
                        }
                        PlaceResultRow(place: place) {
                            selectedPlace = place
                        }
                    }

                    if placeResults.count > 5 {
                        Text("还有 \(placeResults.count - 5) 个地名...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    }
                }
                .dongbeiCard(padding: 0)
            }

            // Vocabulary results
            if !vocabResults.isEmpty {
                VStack(spacing: 0) {
                    // Section header
                    HStack {
                        Image(systemName: "character.bubble.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.dahong)
                        Text("方言")
                            .font(.caption.bold())
                            .foregroundStyle(DongbeiColors.dahong)
                        Spacer()
                        Text("\(vocabResults.count)个结果")
                            .font(Theme.badgeFont)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(DongbeiColors.dahong.opacity(0.05))

                    ForEach(Array(vocabResults.prefix(8).enumerated()), id: \.element.id) { index, vocab in
                        if index > 0 {
                            Divider().padding(.horizontal, 12)
                        }
                        DialectResultRow(vocabulary: vocab)
                    }

                    if vocabResults.count > 8 {
                        Text("还有 \(vocabResults.count - 8) 个方言...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    }
                }
                .dongbeiCard(padding: 0)
            }
        }
        .padding(.top, Theme.spacingSM)
    }
}

// MARK: - Place Result Row

struct PlaceResultRow: View {
    let place: DongbeiPlace
    let onTap: () -> Void

    private var provinceColor: Color {
        switch place.province {
        case "吉林": DongbeiColors.cuilu
        case "辽宁": DongbeiColors.jinhuang
        default: DongbeiColors.dahong
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Province icon
                Text(String(place.province.prefix(1)))
                    .font(Theme.labelFont.bold())
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(provinceColor, in: RoundedRectangle(cornerRadius: 6))

                // Name and province
                VStack(alignment: .leading, spacing: 1) {
                    Text(place.name)
                        .font(Theme.subheadlineFont)
                        .foregroundStyle(DongbeiColors.meihei)
                    Text("\(place.province) · \(place.signatureDishes.prefix(2).joined(separator: " · "))")
                        .font(Theme.badgeFont)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(Theme.badgeFont)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dialect Result Row

struct DialectResultRow: View {
    let vocabulary: Vocabulary
    @State private var isExpanded = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Main row
                HStack(spacing: 10) {
                    // Dongbei word
                    VStack(alignment: .leading, spacing: 1) {
                        Text(vocabulary.dongbeiWord)
                            .font(.body.bold())
                            .foregroundStyle(DongbeiColors.dahong)
                        Text(vocabulary.dongbeiPinyin)
                            .font(Theme.badgeFont)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .font(Theme.badgeFont)
                        .foregroundStyle(.tertiary)

                    // Standard word
                    VStack(alignment: .leading, spacing: 1) {
                        Text(vocabulary.standardWord)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(DongbeiColors.meihei)
                        Text(vocabulary.pinyin)
                            .font(Theme.badgeFont)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Category badge
                    Text(vocabulary.category.rawValue)
                        .font(Theme.tinyFont)
                        .foregroundStyle(DongbeiColors.cuilu)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DongbeiColors.cuilu.opacity(0.1), in: Capsule())

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(Theme.badgeFont)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                // Expanded detail
                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        // Meaning
                        HStack(alignment: .top, spacing: 6) {
                            Text("释义")
                                .font(Theme.badgeFont)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(DongbeiColors.dahong, in: RoundedRectangle(cornerRadius: 3))
                            Text(vocabulary.meaning)
                                .font(Theme.labelFont)
                                .foregroundStyle(.secondary)
                        }

                        // Example
                        HStack(alignment: .top, spacing: 6) {
                            Text("例句")
                                .font(Theme.badgeFont)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: 3))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(vocabulary.exampleSentence)
                                    .font(Theme.labelFont)
                                    .foregroundStyle(DongbeiColors.meihei)
                                Text(vocabulary.exampleTranslation)
                                    .font(Theme.smallLabelFont)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Fun fact
                        if let funFact = vocabulary.funFact {
                            HStack(alignment: .top, spacing: 6) {
                                Text("冷知识")
                                    .font(Theme.badgeFont)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(DongbeiColors.jinhuang, in: RoundedRectangle(cornerRadius: 3))
                                Text(funFact)
                                    .font(Theme.smallLabelFont)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
