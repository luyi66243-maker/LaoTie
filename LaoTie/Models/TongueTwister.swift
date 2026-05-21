import Foundation

// MARK: - TongueTwister

struct TongueTwister: Codable, Identifiable, Sendable {
    let id: String
    let title: String           // 绕口令标题
    let content: String         // 绕口令全文
    let difficulty: Int         // 难度 1-5
    let tip: String             // 发音技巧提示
    let category: String        // 分类（平翘舌/儿化音/语速/声调）

    static let preview = TongueTwister(
        id: "tt1",
        title: "四是四",
        content: "四是四，十是十，十四是十四，四十是四十",
        difficulty: 3,
        tip: "注意区分 s 和 sh 的发音，舌尖位置不同",
        category: "平翘舌"
    )
}
