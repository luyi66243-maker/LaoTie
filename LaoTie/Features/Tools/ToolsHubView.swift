import SwiftUI
import UIKit

struct ToolsHubView: View {
    @StateObject private var quickStore = ToolQuickActionsStore()

    private var detailTools: [ToolResource] {
        [
            .init(
                id: "drinking_etiquette",
                title: "酒桌礼仪",
                subtitle: "东北酒局规矩",
                icon: "wineglass.fill",
                color: DongbeiColors.dahong,
                intro: "东北酒桌讲究热情和分寸，掌握基本礼节会更受欢迎。",
                bulletPoints: [
                    "敬酒时先敬长辈和主宾，注意顺序",
                    "不会喝可以提前说明，态度诚恳最重要",
                    "劝酒要适度，别让对方为难",
                    "离席前可简单致谢，礼貌收尾",
                ]
            ),
            .init(
                id: "bathhouse_culture",
                title: "澡堂文化",
                subtitle: "东北洗浴指南",
                icon: "shower.fill",
                color: DongbeiColors.binglan,
                intro: "东北洗浴更像社交场景，懂点规矩体验更舒服。",
                bulletPoints: [
                    "进入湿区前先冲洗身体",
                    "公共区域注意音量和礼貌",
                    "搓澡服务前可先沟通力度",
                    "个人物品放好，避免占位",
                ]
            ),
            .init(
                id: "bbq_culture",
                title: "烧烤文化",
                subtitle: "东北烧烤术语",
                icon: "fork.knife",
                color: DongbeiColors.huabufen,
                intro: "东北烧烤偏重分享和氛围，常见术语先熟悉。",
                bulletPoints: [
                    "“来串”通常默认一把上桌",
                    "点单先荤后素，按人数均衡搭配",
                    "重口味可提前备注辣度和孜然",
                    "AA 或请客最好提前说清",
                ]
            ),
            .init(
                id: "snow_culture",
                title: "冰雪文化",
                subtitle: "东北冬天特色",
                icon: "snowflake",
                color: DongbeiColors.qianlan,
                intro: "东北冬天户外活动多，保暖与安全同样重要。",
                bulletPoints: [
                    "分层穿衣，重点保护耳手脚",
                    "雪地步行小步慢走，防滑优先",
                    "电子设备注意低温续航衰减",
                    "长时间户外建议随身热饮",
                ]
            ),
            .init(
                id: "seven_day_bootcamp",
                title: "7天速成",
                subtitle: "旅游应急包",
                icon: "calendar",
                color: DongbeiColors.dahong,
                intro: "给来东北旅行或出差的你，快速上手高频表达。",
                bulletPoints: [
                    "第1-2天：打招呼与基础问路",
                    "第3-4天：点餐、购物与价格沟通",
                    "第5-6天：社交寒暄和礼貌表达",
                    "第7天：高频场景复盘与纠错",
                ]
            ),
            .init(
                id: "universal_scripts",
                title: "万能话术",
                subtitle: "各种场景应对",
                icon: "quote.bubble.fill",
                color: DongbeiColors.jinhuang,
                intro: "先掌握这些场景句式，沟通更自然。",
                bulletPoints: [
                    "寒暄：先夸天气和当地美食",
                    "求助：开头先说“麻烦问一下”",
                    "致谢：多用“谢谢老铁，太帮忙了”",
                    "告别：简短热情，留有余地",
                ]
            ),
        ]
    }

    private var detailToolsByID: [String: ToolResource] {
        Dictionary(uniqueKeysWithValues: detailTools.map { ($0.id, $0) })
    }

    private var favoriteTools: [ToolResource] {
        detailTools.filter { quickStore.favorites.contains($0.id) }
    }

    private var recentTools: [ToolResource] {
        quickStore.recentToolIDs.compactMap { detailToolsByID[$0] }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.spacingLG) {
                    quickActionsSection

                    emergencySection
                    
                    cultureSection
                    
                    practicalSection
                }
                .padding(Theme.spacingMD)
            }
            .background(DongbeiColors.pageBackground)
            .navigationTitle("实用工具")
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(DongbeiColors.jinhuang)
                Text("快捷入口")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }

            quickRow(
                title: "最近使用",
                emptyText: "还没有使用记录，去点开一个工具试试",
                tools: recentTools
            )

            quickRow(
                title: "我的收藏",
                emptyText: "在工具详情点星标即可收藏",
                tools: favoriteTools
            )
        }
    }

    @ViewBuilder
    private func quickRow(title: String, emptyText: String, tools: [ToolResource]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if tools.isEmpty {
                Text(emptyText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tools) { tool in
                            NavigationLink {
                                ToolDetailView(resource: tool, quickStore: quickStore)
                            } label: {
                                Label(tool.title, systemImage: tool.icon)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(tool.color.opacity(0.15), in: Capsule())
                                    .foregroundStyle(tool.color)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.title3)
                    .foregroundStyle(DongbeiColors.dahong)
                Text("应急工具")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.spacingSM),
                GridItem(.flexible(), spacing: Theme.spacingSM)
            ], spacing: Theme.spacingSM) {
                NavigationLink {
                    ConfusingWordsView()
                } label: {
                    ToolCard(
                        icon: "questionmark.circle.fill",
                        title: "易混淆词",
                        subtitle: "防社死指南",
                        color: DongbeiColors.dahong
                    )
                }
                
                NavigationLink {
                    SubtextGuideView()
                } label: {
                    ToolCard(
                        icon: "lightbulb.fill",
                        title: "潜台词指南",
                        subtitle: "读懂东北人",
                        color: DongbeiColors.jinhuang
                    )
                }
            }
        }
    }
    
    private var cultureSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "book.closed.fill")
                    .font(.title3)
                    .foregroundStyle(DongbeiColors.cuilu)
                Text("文化指南")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.spacingSM),
                GridItem(.flexible(), spacing: Theme.spacingSM)
            ], spacing: Theme.spacingSM) {
                NavigationLink {
                    ToolDetailView(resource: detailTools[0], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[0].icon,
                        title: detailTools[0].title,
                        subtitle: detailTools[0].subtitle,
                        color: detailTools[0].color,
                        isFavorite: quickStore.favorites.contains(detailTools[0].id)
                    )
                }

                NavigationLink {
                    ToolDetailView(resource: detailTools[1], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[1].icon,
                        title: detailTools[1].title,
                        subtitle: detailTools[1].subtitle,
                        color: detailTools[1].color,
                        isFavorite: quickStore.favorites.contains(detailTools[1].id)
                    )
                }

                NavigationLink {
                    ToolDetailView(resource: detailTools[2], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[2].icon,
                        title: detailTools[2].title,
                        subtitle: detailTools[2].subtitle,
                        color: detailTools[2].color,
                        isFavorite: quickStore.favorites.contains(detailTools[2].id)
                    )
                }

                NavigationLink {
                    ToolDetailView(resource: detailTools[3], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[3].icon,
                        title: detailTools[3].title,
                        subtitle: detailTools[3].subtitle,
                        color: detailTools[3].color,
                        isFavorite: quickStore.favorites.contains(detailTools[3].id)
                    )
                }
            }
        }
    }
    
    private var practicalSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title3)
                    .foregroundStyle(DongbeiColors.huabufen)
                Text("实用工具")
                    .font(.headline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: Theme.spacingSM),
                GridItem(.flexible(), spacing: Theme.spacingSM)
            ], spacing: Theme.spacingSM) {
                NavigationLink {
                    VocabularyListView()
                } label: {
                    ToolCard(
                        icon: "character.book.closed.fill",
                        title: "离线词典",
                        subtitle: "快速查词",
                        color: DongbeiColors.cuilu
                    )
                }

                NavigationLink {
                    DialectSearchView()
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.top, Theme.spacingMD)
                        .navigationTitle("翻译器")
                        .navigationBarTitleDisplayMode(.inline)
                        .background(DongbeiColors.pageBackground)
                } label: {
                    ToolCard(
                        icon: "globe",
                        title: "翻译器",
                        subtitle: "东北话↔普通话",
                        color: DongbeiColors.meihei
                    )
                }

                NavigationLink {
                    ToolDetailView(resource: detailTools[4], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[4].icon,
                        title: detailTools[4].title,
                        subtitle: detailTools[4].subtitle,
                        color: detailTools[4].color,
                        isFavorite: quickStore.favorites.contains(detailTools[4].id)
                    )
                }

                NavigationLink {
                    ToolDetailView(resource: detailTools[5], quickStore: quickStore)
                } label: {
                    ToolCard(
                        icon: detailTools[5].icon,
                        title: detailTools[5].title,
                        subtitle: detailTools[5].subtitle,
                        color: detailTools[5].color,
                        isFavorite: quickStore.favorites.contains(detailTools[5].id)
                    )
                }
            }
        }
    }
}

struct ToolDetailView: View {
    let resource: ToolResource
    @ObservedObject var quickStore: ToolQuickActionsStore

    @State private var showCopiedToast = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingMD) {
                HStack(spacing: 10) {
                    Button {
                        quickStore.toggleFavorite(resource.id)
                    } label: {
                        Label(
                            quickStore.favorites.contains(resource.id) ? "已收藏" : "收藏",
                            systemImage: quickStore.favorites.contains(resource.id) ? "star.fill" : "star"
                        )
                        .font(.caption.bold())
                        .foregroundStyle(quickStore.favorites.contains(resource.id) ? DongbeiColors.jinhuang : .secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        copyAllContent()
                    } label: {
                        Label("复制要点", systemImage: "doc.on.doc.fill")
                            .font(.caption.bold())
                            .foregroundStyle(DongbeiColors.cuilu)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }

                Text(resource.intro)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(resource.bulletPoints, id: \.self) { item in
                    HStack(alignment: .top, spacing: Theme.spacingSM) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DongbeiColors.cuilu)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(item)
                            .font(.body)
                            .foregroundStyle(DongbeiColors.meihei)
                    }
                }
            }
            .padding(Theme.spacingMD)
        }
        .background(DongbeiColors.pageBackground)
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                Text("要点已复制")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(DongbeiColors.meihei.opacity(0.85), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, 20)
                    .transition(.opacity)
            }
        }
        .onAppear {
            quickStore.markUsed(resource.id)
        }
    }

    private func copyAllContent() {
        let lines = resource.bulletPoints.enumerated().map { idx, item in
            "\(idx + 1). \(item)"
        }.joined(separator: "\n")
        UIPasteboard.general.string = "\(resource.title)\n\(resource.intro)\n\n\(lines)"
        withAnimation(.easeOut(duration: 0.2)) {
            showCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeIn(duration: 0.2)) {
                showCopiedToast = false
            }
        }
    }
}

struct ToolCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    var isFavorite: Bool = false
    
    var body: some View {
        VStack(spacing: Theme.spacingSM) {
            ZStack {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .fill(color.opacity(0.1))
                    .frame(height: 60)

                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(DongbeiColors.jinhuang)
                    }
                }
            }
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(DongbeiColors.meihei)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(Theme.spacingMD)
        .background(.white, in: RoundedRectangle(cornerRadius: Theme.cornerRadiusLG))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct ToolResource: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let intro: String
    let bulletPoints: [String]
}

@MainActor
final class ToolQuickActionsStore: ObservableObject {
    private static let favoritesKey = "tool_quick_favorites"
    private static let recentKey = "tool_quick_recent_ids"
    private static let maxRecentCount = 8

    @Published private(set) var favorites: Set<String>
    @Published private(set) var recentToolIDs: [String]

    init() {
        let storedFavorites = UserDefaults.standard.stringArray(forKey: Self.favoritesKey) ?? []
        favorites = Set(storedFavorites)
        recentToolIDs = UserDefaults.standard.stringArray(forKey: Self.recentKey) ?? []
    }

    func toggleFavorite(_ toolID: String) {
        if favorites.contains(toolID) {
            favorites.remove(toolID)
        } else {
            favorites.insert(toolID)
        }
        UserDefaults.standard.set(Array(favorites), forKey: Self.favoritesKey)
    }

    func markUsed(_ toolID: String) {
        recentToolIDs.removeAll { $0 == toolID }
        recentToolIDs.insert(toolID, at: 0)
        if recentToolIDs.count > Self.maxRecentCount {
            recentToolIDs = Array(recentToolIDs.prefix(Self.maxRecentCount))
        }
        UserDefaults.standard.set(recentToolIDs, forKey: Self.recentKey)
    }
}
