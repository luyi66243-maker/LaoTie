import SwiftUI

struct SubtextGuideView: View {
    @State private var subtextGuides: [SubtextGuide] = []
    @State private var selectedScenario: SubtextScenario? = nil
    @State private var searchText = ""
    
    private let audioPlayer = AudioPlayerService()
    
    var filteredGuides: [SubtextGuide] {
        var result = subtextGuides
        
        if let scenario = selectedScenario {
            result = result.filter { $0.scenario == scenario }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.literalMeaning.contains(searchText) ||
                $0.actualMeaning.contains(searchText) ||
                $0.usageContext.contains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                scenarioPicker
                
                if filteredGuides.isEmpty {
                    emptyState
                } else {
                    guideList
                }
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("潜台词指南")
            .task { loadSampleData() }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索潜台词...", text: $searchText)
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
    
    private var scenarioPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingSM) {
                CategoryChip(
                    title: "全部",
                    icon: "square.grid.2x2",
                    isSelected: selectedScenario == nil
                ) {
                    selectedScenario = nil
                }
                
                ForEach(SubtextScenario.allCases, id: \.self) { scenario in
                    CategoryChip(
                        title: scenario.displayName,
                        icon: scenario.icon,
                        isSelected: selectedScenario == scenario
                    ) {
                        selectedScenario = scenario
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
            Image(systemName: "lightbulb.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("暂无潜台词指南")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
    
    private var guideList: some View {
        List {
            ForEach(filteredGuides) { guide in
                NavigationLink {
                    SubtextGuideDetailView(guide: guide)
                } label: {
                    SubtextGuideRow(guide: guide)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func loadSampleData() {
        subtextGuides = [
            .preview,
            SubtextGuide(
                id: "st002",
                scenario: .dinner,
                literalMeaning: "我再喝最后一杯",
                actualMeaning: "绝对不是最后一杯，还能接着喝！",
                properResponse: [
                    "好，陪你再整一个！",
                    "来来来，满上满上！",
                    "最后一杯？我信你个鬼！"
                ],
                usageContext: "东北酒桌上常用的话术，表示喝得尽兴，还想继续喝。千万别当真觉得是最后一杯！",
                examples: [
                    SubtextExample(
                        dialogue: "甲：我再喝最后一杯！乙：好，陪你再整一个！",
                        explanation: "甲说的\"最后一杯\"通常只是说辞，其实还想接着喝；乙的回应表示理解并配合"
                    )
                ],
                difficulty: 3,
                audioFileName: "st002_audio"
            ),
            SubtextGuide(
                id: "st003",
                scenario: .warning,
                literalMeaning: "你等着",
                actualMeaning: "不是让你原地等待，大概率要起冲突了！",
                properResponse: [
                    "咋的？想整事儿啊？",
                    "等啥等，有话直说！",
                    "（如果不想冲突）别别别，有事儿好商量"
                ],
                usageContext: "在东北，\"你等着\"通常是冲突的前兆，不是真的让你等。要根据情况判断是玩笑还是真生气。",
                examples: [
                    SubtextExample(
                        dialogue: "甲：你给我等着！乙：咋的？想整事儿啊？",
                        explanation: "甲的意思是要找麻烦，乙在确认是否真的要起冲突"
                    )
                ],
                difficulty: 4,
                audioFileName: "st003_audio"
            )
        ]
    }
}

struct SubtextGuideRow: View {
    let guide: SubtextGuide
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Text("\"")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DongbeiColors.dahong)
                
                Text(guide.literalMeaning)
                    .font(.headline)
                    .foregroundStyle(DongbeiColors.meihei)
                    .lineLimit(2)
                
                Text("\"")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DongbeiColors.dahong)
            }
            
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                Text(guide.actualMeaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: Theme.spacingSM) {
                Text(guide.scenario.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(DongbeiColors.dahong.opacity(0.15))
                    .foregroundStyle(DongbeiColors.dahong)
                    .clipShape(Capsule())
                
                HStack(spacing: 2) {
                    ForEach(0..<guide.difficulty, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }
            }
        }
        .padding(.vertical, Theme.spacingSM)
    }
}

struct SubtextGuideDetailView: View {
    let guide: SubtextGuide
    @StateObject private var audioPlayer = AudioPlayerService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                guideHeader
                
                literalMeaningSection
                
                actualMeaningSection
                
                responseSection
                
                contextSection
                
                examplesSection
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle("潜台词解析")
    }
    
    private var guideHeader: some View {
        VStack(spacing: Theme.spacingLG) {
            HStack(spacing: Theme.spacingSM) {
                Text(guide.scenario.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.dahong)
                
                Spacer()
                
                HStack(spacing: 2) {
                    Text("难度:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ForEach(0..<guide.difficulty, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }
            }
            
            VStack(spacing: Theme.spacingMD) {
                Text("\"")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DongbeiColors.dahong)
                
                Text(guide.literalMeaning)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(DongbeiColors.meihei)
                    .multilineTextAlignment(.center)
                
                Text("\"")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(DongbeiColors.dahong)
                
                if let audioFileName = guide.audioFileName {
                    Button {
                        audioPlayer.playBundledAudio(named: audioFileName, style: .dongbei)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("听一听")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(DongbeiColors.dahong)
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingSM)
                        .background(DongbeiColors.dahong.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(Theme.spacingLG)
            .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        }
    }
    
    private var literalMeaningSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "text.quote")
                    .foregroundStyle(DongbeiColors.dahong)
                Text("字面意思")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            Text(guide.literalMeaning)
                .font(Theme.bodyFont)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
    
    private var actualMeaningSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(DongbeiColors.jinhuang)
                Text("实际意思")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            Text(guide.actualMeaning)
                .font(Theme.bodyFont)
                .foregroundStyle(DongbeiColors.dahong)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.spacingMD)
        .background(DongbeiColors.jinhuang.opacity(0.1), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "hand.raised.fill")
                    .foregroundStyle(DongbeiColors.cuilu)
                Text("正确回应方式")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            VStack(spacing: Theme.spacingSM) {
                ForEach(guide.properResponse, id: \.self) { response in
                    HStack(spacing: Theme.spacingSM) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DongbeiColors.cuilu)
                            .font(.headline)
                        Text(response)
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
    
    private var contextSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(DongbeiColors.dahong)
                Text("使用场景")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            Text(guide.usageContext)
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
                Text("对话示例")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            VStack(spacing: Theme.spacingLG) {
                ForEach(guide.examples, id: \.dialogue) { example in
                    VStack(alignment: .leading, spacing: Theme.spacingSM) {
                        Text(example.dialogue)
                            .font(Theme.bodyFont)
                            .foregroundStyle(DongbeiColors.meihei)
                            .padding(Theme.spacingMD)
                            .background(DongbeiColors.dahong.opacity(0.05), in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                        
                        HStack(spacing: Theme.spacingSM) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.secondary)
                            Text(example.explanation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }
}
