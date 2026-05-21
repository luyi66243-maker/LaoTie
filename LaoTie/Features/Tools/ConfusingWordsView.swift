import SwiftUI

struct ConfusingWordsView: View {
    @State private var confusingWords: [ConfusingWord] = []
    @State private var selectedType: WordComparisonType? = nil
    @State private var searchText = ""
    @State private var dueWordIDs: Set<String> = []
    
    private let audioPlayer = AudioPlayerService()
    private let repository = ConfusingWordsRepository()
    private let reviewScheduleService = ReviewScheduleService()
    
    var filteredWords: [ConfusingWord] {
        var result = confusingWords
        
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.dongbeiWord.contains(searchText) ||
                $0.standardWord.contains(searchText) ||
                $0.meaning.contains(searchText)
            }
        }
        
        return result.sorted {
            let lhsDue = dueWordIDs.contains($0.id)
            let rhsDue = dueWordIDs.contains($1.id)
            if lhsDue != rhsDue { return lhsDue }
            return $0.id < $1.id
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                typePicker
                
                if filteredWords.isEmpty {
                    emptyState
                } else {
                    wordList
                }
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("易混淆词")
            .task { loadData() }
            .onAppear { loadData() }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索词语...", text: $searchText)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(Color.white)
    }
    
    private var typePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingSM) {
                CategoryChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedType == nil
                ) {
                    selectedType = nil
                }
                
                ForEach(WordComparisonType.allCases, id: \.self) { type in
                    CategoryChip(
                        title: type.displayName,
                        icon: type.icon,
                        isSelected: selectedType == type
                    ) {
                        selectedType = type
                    }
                }
            }
            .padding(.horizontal, Theme.spacingMD)
            .padding(.vertical, Theme.spacingSM)
        }
        .background(DongbeiColors.cardBackground)
    }
    
    private var emptyState: some View {
        VStack(spacing: Theme.spacingLG) {
            Spacer()
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("暂无易混淆词")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var wordList: some View {
        List {
            ForEach(filteredWords) { word in
                NavigationLink {
                    ConfusingWordDetailView(word: word) {
                        refreshDueWords()
                    }
                } label: {
                    ConfusingWordRow(word: word, isDueReview: dueWordIDs.contains(word.id))
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func loadData() {
        let builtinWords: [ConfusingWord] = [
            .preview,
            ConfusingWord(
                id: "cw002",
                type: .confusing,
                dongbeiWord: "整",
                dongbeiPinyin: "zhěng",
                standardWord: "做、做",
                standardPinyin: "zuò",
                meaning: "东北话中\"整\"是万能动词，可以表示做、吃、喝、玩、收拾等多种含义，具体意思要看语境。",
                usageNote: "在东北，'整'几乎可以代替任何动词，是最典型的万能动词！",
                examples: [
                    "整饭=做饭",
                    "整个酒=喝酒",
                    "整事儿=惹事/处理事情",
                    "这事儿咋整=这事儿怎么办"
                ],
                isTaboo: false,
                tabooLevel: nil,
                dongbeiAudioFileName: "zheng_dongbei",
                standardAudioFileName: "zuo_standard"
            ),
            ConfusingWord(
                id: "cw003",
                type: .taboo,
                dongbeiWord: "滚犊子",
                dongbeiPinyin: "gǔn dú zi",
                standardWord: "走开、滚开",
                standardPinyin: "zǒu kāi",
                meaning: "比较粗鲁的让别人走开的说法，虽然有时候朋友之间开玩笑也会用，但在正式场合或对陌生人说会很不礼貌。",
                usageNote: "这个词有一定的冒犯性，使用时要注意场合和关系亲疏！",
                examples: [
                    "滚犊子，一边儿去！（朋友间开玩笑）"
                ],
                isTaboo: true,
                tabooLevel: 3,
                dongbeiAudioFileName: "gunduzi_dongbei",
                standardAudioFileName: "zoukai_standard"
            )
        ]
        confusingWords = builtinWords + repository.loadWrongAnswerWords()
        refreshDueWords()
    }

    private func refreshDueWords() {
        dueWordIDs = reviewScheduleService.dueWordIDsToday()
    }
}

struct ConfusingWordRow: View {
    let word: ConfusingWord
    var isDueReview: Bool = false
    
    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: Theme.spacingSM) {
                    Text(word.dongbeiWord)
                        .font(.title3.bold())
                        .foregroundStyle(word.isTaboo ? DongbeiColors.dahong : DongbeiColors.meihei)
                    
                    if word.isTaboo {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.dahong)
                    }
                }
                
                Text("→ \(word.standardWord)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 4) {
                    Text(word.type.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            word.type == .taboo 
                                ? DongbeiColors.dahong.opacity(0.15) 
                                : DongbeiColors.huabufen.opacity(0.15)
                        )
                        .foregroundStyle(
                            word.type == .taboo 
                                ? DongbeiColors.dahong 
                                : DongbeiColors.huabufen
                        )
                        .clipShape(Capsule())

                    if isDueReview {
                        Text("待复习")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DongbeiColors.jinhuang.opacity(0.15))
                            .foregroundStyle(DongbeiColors.jinhuang)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ConfusingWordDetailView: View {
    let word: ConfusingWord
    var onReviewed: (() -> Void)? = nil
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var isDueReview = false
    @State private var showReviewedToast = false
    private let reviewScheduleService = ReviewScheduleService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                wordHeader
                
                meaningSection
                
                examplesSection
                
                noteSection

                if isDueReview {
                    Button {
                        markReviewed()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("完成本次复习")
                                .font(.headline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle(word.dongbeiWord)
        .onAppear {
            isDueReview = reviewScheduleService.dueWordIDsToday().contains(word.id)
        }
        .overlay(alignment: .top) {
            if showReviewedToast {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("已完成复习，已排入下一轮")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DongbeiColors.cuilu, in: Capsule())
                .padding(.top, Theme.spacingLG)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private var wordHeader: some View {
        VStack(spacing: Theme.spacingLG) {
            if word.isTaboo {
                warningBanner
            }
            
            VStack(spacing: Theme.spacingMD) {
                Text(word.dongbeiWord)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(DongbeiColors.meihei)
                
                Text(word.dongbeiPinyin)
                    .font(Theme.pinyinFont)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: Theme.spacingMD) {
                    Button {
                        if let fileName = word.dongbeiAudioFileName {
                            audioPlayer.playBundledAudio(named: fileName, style: .dongbei)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("东北话")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.dahong)
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM)
                        .background(DongbeiColors.dahong.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    
                    Button {
                        if let fileName = word.standardAudioFileName {
                            audioPlayer.playBundledAudio(named: fileName, style: .standard)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("普通话")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.cuilu)
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM)
                        .background(DongbeiColors.cuilu.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(Theme.spacingLG)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            
            VStack(spacing: Theme.spacingSM) {
                Text("→")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                
                Text(word.standardWord)
                    .font(.title2.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                
                Text(word.standardPinyin)
                    .font(Theme.pinyinFont)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var warningBanner: some View {
        HStack(spacing: Theme.spacingSM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("注意使用")
                    .font(.headline.bold())
                Text("这个词有禁忌等级 \(word.tabooLevel ?? 0)")
                    .font(.caption)
            }
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacingMD)
        .background(DongbeiColors.dahong, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
    
    private var meaningSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(DongbeiColors.dahong)
                Text("含义解释")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            Text(word.meaning)
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
    
    private var examplesSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "quote.bubble.fill")
                    .foregroundStyle(DongbeiColors.dahong)
                Text("用法示例")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            VStack(spacing: Theme.spacingSM) {
                ForEach(word.examples, id: \.self) { example in
                    HStack(spacing: Theme.spacingSM) {
                        Text("•")
                            .foregroundStyle(DongbeiColors.dahong)
                            .font(.headline.bold())
                        Text(example)
                            .font(Theme.bodyFont)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
    
    private var noteSection: some View {
        Group {
            if let note = word.usageNote {
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(DongbeiColors.jinhuang)
                        Text("使用提示")
                            .font(.headline.bold())
                            .foregroundStyle(DongbeiColors.meihei)
                    }
                    
                    Text(note)
                        .font(Theme.bodyFont)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Theme.spacingMD)
                .background(DongbeiColors.jinhuang.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }
        }
    }

    private func markReviewed() {
        guard reviewScheduleService.markReviewed(wordId: word.id) else { return }
        _ = DailyTaskService().addReviewSession()
        isDueReview = false
        onReviewed?()
        withAnimation(.spring(duration: 0.4)) {
            showReviewedToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation(.easeInOut(duration: 0.2)) {
                showReviewedToast = false
            }
        }
    }
}

struct ReviewQueueView: View {
    @State private var dueItems: [ReviewScheduleItem] = []
    @State private var wordsByID: [String: ConfusingWord] = [:]
    @State private var showDoneToast = false
    @State private var focusMode = true

    private let repository = ConfusingWordsRepository()
    private let reviewScheduleService = ReviewScheduleService()

    var body: some View {
        VStack(spacing: 0) {
            if dueItems.isEmpty {
                VStack(spacing: Theme.spacingLG) {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(DongbeiColors.cuilu)
                    Text("今天没有待复习错题")
                        .font(.headline.bold())
                        .foregroundStyle(DongbeiColors.meihei)
                    Text("明天再来巩固，稳稳拿捏")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(DongbeiColors.pageBackground)
            } else {
                VStack(spacing: 0) {
                    queueHeader

                    if focusMode, let first = dueItems.first {
                        focusModeCard(first)
                            .padding(Theme.spacingMD)
                    } else {
                        List {
                            ForEach(dueItems) { item in
                                reviewRow(item)
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("今日待复习")
        .background(DongbeiColors.pageBackground)
        .task { loadQueue() }
        .onReceive(NotificationCenter.default.publisher(for: .reviewScheduleDidChange)) { _ in
            loadQueue()
        }
        .overlay(alignment: .top) {
            if showDoneToast {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("已完成，进入下一轮复习")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DongbeiColors.cuilu, in: Capsule())
                .padding(.top, Theme.spacingLG)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func loadQueue() {
        dueItems = reviewScheduleService.dueItemsToday()
        let words = repository.loadWrongAnswerWords()
        wordsByID = Dictionary(uniqueKeysWithValues: words.map { ($0.id, $0) })
    }

    private func completeReview(for wordId: String) {
        guard reviewScheduleService.markReviewed(wordId: wordId) else { return }
        _ = DailyTaskService().addReviewSession()
        loadQueue()
        withAnimation(.spring(duration: 0.4)) {
            showDoneToast = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.2)) {
                showDoneToast = false
            }
        }
    }

    private var queueHeader: some View {
        VStack(spacing: Theme.spacingSM) {
            HStack {
                Label("今日待复习 \(dueItems.count) 题", systemImage: "arrow.clockwise.circle.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                Spacer()
                Toggle("连刷模式", isOn: $focusMode)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Text(focusMode ? "连刷模式已开启：完成后自动切下一题" : "列表模式：可自由选择条目复习")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.spacingMD)
        .background(.white)
    }

    @ViewBuilder
    private func reviewRow(_ item: ReviewScheduleItem) -> some View {
        let word = wordsByID[item.wordId]
        NavigationLink {
            if let word {
                ConfusingWordDetailView(word: word) {
                    loadQueue()
                }
            } else {
                Text(item.questionPrompt)
                    .padding()
            }
        } label: {
            HStack(alignment: .top, spacing: Theme.spacingSM) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(word?.dongbeiWord ?? "错题复习")
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.meihei)

                    Text(word?.standardWord ?? item.questionPrompt)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text("第 \(item.stage + 1) 轮")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DongbeiColors.jinhuang.opacity(0.15))
                            .foregroundStyle(DongbeiColors.jinhuang)
                            .clipShape(Capsule())
                        Text("到期：\(item.dueDate)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("完成") {
                    completeReview(for: item.wordId)
                }
                .font(.caption.bold())
                .buttonStyle(.borderedProminent)
                .tint(DongbeiColors.cuilu)
            }
            .padding(.vertical, 2)
        }
    }

    private func focusModeCard(_ item: ReviewScheduleItem) -> some View {
        let word = wordsByID[item.wordId]
        return VStack(alignment: .leading, spacing: Theme.spacingMD) {
            Text("当前复习")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            Text(word?.dongbeiWord ?? "错题复习")
                .font(.title2.bold())
                .foregroundStyle(DongbeiColors.meihei)

            Text(word?.standardWord ?? item.questionPrompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Text("第 \(item.stage + 1) 轮")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DongbeiColors.jinhuang.opacity(0.15))
                    .foregroundStyle(DongbeiColors.jinhuang)
                    .clipShape(Capsule())
                Text("到期：\(item.dueDate)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Theme.spacingSM) {
                NavigationLink {
                    if let word {
                        ConfusingWordDetailView(word: word) {
                            loadQueue()
                        }
                    } else {
                        Text(item.questionPrompt)
                            .padding()
                    }
                } label: {
                    Text("查看详情")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                                .stroke(DongbeiColors.meihei.opacity(0.15), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Button {
                    completeReview(for: item.wordId)
                } label: {
                    Text("完成并下一条")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DongbeiColors.cuilu, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
    }
}

final class ConfusingWordsRepository {
    private let storageKey = "laotie_quiz_wrong_words_v1"

    func loadWrongAnswerWords() -> [ConfusingWord] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let words = try? JSONDecoder().decode([ConfusingWord].self, from: data) else {
            return []
        }
        return words
    }

    func recordWrongAnswer(
        question: QuizQuestion,
        selectedAnswer: String,
        level: QuizLevel
    ) {
        let normalizedSelected = selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCorrect = question.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedSelected.isEmpty,
              !normalizedCorrect.isEmpty,
              normalizedSelected != normalizedCorrect else {
            return
        }

        var words = loadWrongAnswerWords()
        let id = "quiz_wrong_\(level.id)_\(question.id)_\(normalizedSelected)"
        if words.contains(where: { $0.id == id }) {
            return
        }

        let wrongWord = ConfusingWord(
            id: id,
            type: .confusing,
            dongbeiWord: normalizedSelected,
            dongbeiPinyin: "待补充",
            standardWord: normalizedCorrect,
            standardPinyin: "待补充",
            meaning: "闯关答题中该题答错，正确答案为「\(normalizedCorrect)」。",
            usageNote: "来源：\(level.province) · \(level.city) · \(level.title)",
            examples: [question.prompt],
            isTaboo: false,
            tabooLevel: nil,
            dongbeiAudioFileName: nil,
            standardAudioFileName: nil
        )

        words.insert(wrongWord, at: 0)
        if words.count > 300 {
            words = Array(words.prefix(300))
        }
        if let data = try? JSONEncoder().encode(words) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }

        ReviewScheduleService().scheduleWrongAnswer(
            wordId: id,
            questionPrompt: question.prompt
        )
    }
}


