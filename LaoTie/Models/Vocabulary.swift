import Foundation

// MARK: - Vocabulary

enum VocabularyCategory: String, Codable, CaseIterable, Sendable {
    case dailyGreeting = "日常寒暄"
    case foodie = "美食江湖"
    case socialLife = "人情世故"
    case coldWeather = "天寒地冻"
    case funStuff = "整活儿"
    case artOfScolding = "骂人不带脏字"
    case dailyLife = "生活起居"
    case entertainment = "娱乐休闲"
    case transport = "交通出行"
    case shopping = "购物消费"
    case workStudy = "工作学习"
    case jiuzhuo = "酒桌文化"
    case wangluomeme = "网络东北梗"
    case xiehouyu = "东北歇后语"
    case difangchayi = "地方差异词"

    var displayName: String { rawValue }

    var icon: String {
        switch self {
        case .dailyGreeting: "hand.wave.fill"
        case .foodie: "fork.knife"
        case .socialLife: "person.2.fill"
        case .coldWeather: "snowflake"
        case .funStuff: "party.popper.fill"
        case .artOfScolding: "exclamationmark.bubble.fill"
        case .dailyLife: "house.fill"
        case .entertainment: "gamecontroller.fill"
        case .transport: "car.fill"
        case .shopping: "bag.fill"
        case .workStudy: "book.fill"
        case .jiuzhuo: "wineglass.fill"
        case .wangluomeme: "network"
        case .xiehouyu: "text.quote"
        case .difangchayi: "map.fill"
        }
    }

    var color: String {
        switch self {
        case .dailyGreeting: "cuilu"
        case .foodie: "dahong"
        case .socialLife: "jinhuang"
        case .coldWeather: "qianlan"
        case .funStuff: "huabufen"
        case .artOfScolding: "meihei"
        case .dailyLife: "cuilu"
        case .entertainment: "jinhuang"
        case .transport: "qianlan"
        case .shopping: "dahong"
        case .workStudy: "meihei"
        case .jiuzhuo: "dahong"
        case .wangluomeme: "huabufen"
        case .xiehouyu: "jinhuang"
        case .difangchayi: "cuilu"
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Sendable {
    case beginner = "初来乍到"
    case intermediate = "略知一二"
    case advanced = "地道老铁"
    case fangyanTuhua = "方言土话"

    var displayName: String { rawValue }

    var color: String {
        switch self {
        case .beginner: "cuilu"
        case .intermediate: "jinhuang"
        case .advanced: "dahong"
        case .fangyanTuhua: "meihei"
        }
    }

    var stars: Int {
        switch self {
        case .beginner: 1
        case .intermediate: 2
        case .advanced: 3
        case .fangyanTuhua: 4
        }
    }
}

struct Vocabulary: Codable, Identifiable, Sendable {
    var id: String
    var dongbeiWord: String
    var standardWord: String
    var pinyin: String
    var dongbeiPinyin: String
    var meaning: String
    var exampleSentence: String
    var exampleTranslation: String
    var audioFileName: String?
    var standardAudioFileName: String?
    var category: VocabularyCategory
    var difficulty: Difficulty
    var usageNote: String?
    var funFact: String?

    static let preview = Vocabulary(
        id: "1",
        dongbeiWord: "嘎哈",
        standardWord: "干什么",
        pinyin: "gàn shén me",
        dongbeiPinyin: "gá há",
        meaning: "做什么、干什么的意思，是东北话最常用的口语表达之一",
        exampleSentence: "你嘎哈去啊？",
        exampleTranslation: "你要去干什么？",
        audioFileName: "gaha",
        standardAudioFileName: "ganshenme",
        category: .dailyGreeting,
        difficulty: .beginner,
        usageNote: "朋友之间打招呼时非常常用",
        funFact: "这个词在东北几乎人人都说，是东北话的标志性词汇"
    )
}
