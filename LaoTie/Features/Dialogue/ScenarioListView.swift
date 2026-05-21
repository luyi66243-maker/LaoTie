import SwiftUI

struct ScenarioListView: View {
    @State private var dialogues: [Dialogue] = []
    private let repository = DialogueRepository()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.spacingMD) {
                    ForEach(dialogues) { dialogue in
                        NavigationLink {
                            DialoguePracticeView(dialogue: dialogue)
                        } label: {
                            ScenarioCard(dialogue: dialogue)
                        }
                    }
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("唠嗑")
            .task { await loadData() }
        }
    }

    private func loadData() async {
        do {
            dialogues = try await repository.fetchAll()
        } catch {
            // Keep empty state
        }
    }
}

struct ScenarioCard: View {
    let dialogue: Dialogue

    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            // Scenario icon
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .fill(scenarioGradient)
                    .frame(height: 100)

                Image(systemName: scenarioIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(dialogue.scenarioTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    ForEach(0..<dialogue.difficulty.stars, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }

                Text("\(dialogue.lines.count) 句对话")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, Theme.spacingSM)
        }
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    private var scenarioIcon: String {
        let title = dialogue.scenarioTitle
        if title.contains("烧烤") { return "flame.fill" }
        if title.contains("铁锅") || title.contains("饭店") || title.contains("点菜") { return "fork.knife" }
        if title.contains("早市") || title.contains("买菜") { return "basket.fill" }
        if title.contains("砍价") { return "tag.fill" }
        if title.contains("酒桌") || title.contains("劝酒") { return "wineglass.fill" }
        if title.contains("酒后") { return "person.wave.2.fill" }
        if title.contains("拌嘴") { return "exclamationmark.bubble.fill" }
        if title.contains("失恋") { return "heart.slash.fill" }
        if title.contains("夸人") { return "hand.thumbsup.fill" }
        if title.contains("打车") || title.contains("出租车") { return "car.fill" }
        if title.contains("澡堂") || title.contains("搓澡") { return "shower.fill" }
        if title.contains("理发") || title.contains("造型") { return "scissors" }
        if title.contains("过年") || title.contains("串门") || title.contains("走亲戚") { return "gift.fill" }
        if title.contains("婚礼") || title.contains("婚宴") { return "heart.circle.fill" }
        if title.contains("广场舞") { return "music.note" }
        if title.contains("冰雪") { return "snowflake" }
        if title.contains("饺子") { return "takeoutbag.and.cup.and.straw.fill" }
        if title.contains("唠嗑") { return "bubble.left.and.bubble.right.fill" }
        return "message.fill"
    }

    private var scenarioGradient: LinearGradient {
        let title = dialogue.scenarioTitle
        let colors: [Color]
        if title.contains("冰雪") {
            colors = [DongbeiColors.binglan, Color(red: 0.7, green: 0.85, blue: 1.0)]
        } else if title.contains("澡堂") || title.contains("搓澡") {
            colors = [DongbeiColors.binglan, DongbeiColors.cuilu]
        } else if title.contains("打车") || title.contains("出租车") {
            colors = [DongbeiColors.meihei, DongbeiColors.binglan]
        } else if title.contains("过年") || title.contains("婚礼") || title.contains("婚宴") {
            colors = [DongbeiColors.dahong, DongbeiColors.jinhuang]
        } else if title.contains("酒") {
            colors = [DongbeiColors.huabufen, DongbeiColors.dahong]
        } else if title.contains("砍价") || title.contains("早市") || title.contains("买菜") {
            colors = [DongbeiColors.cuilu, DongbeiColors.jinhuang]
        } else {
            colors = [DongbeiColors.dahong, DongbeiColors.huabufen]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
