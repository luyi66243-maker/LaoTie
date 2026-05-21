import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: String
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(role: MessageRole, content: String) {
        self.id = UUID().uuidString
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

enum AICharacter: String, CaseIterable {
    case dongbeiDage = "dongbeiDage"
    case dongbeiDajie = "dongbeiDajie"
    case dongbeiLaoshi = "dongbeiLaoshi"

    var displayName: String {
        switch self {
        case .dongbeiDage: return "东北大哥"
        case .dongbeiDajie: return "东北大姐"
        case .dongbeiLaoshi: return "东北老师"
        }
    }

    var avatar: String {
        switch self {
        case .dongbeiDage: return "person.fill"
        case .dongbeiDajie: return "person.fill"
        case .dongbeiLaoshi: return "graduationcap.fill"
        }
    }

    var description: String {
        switch self {
        case .dongbeiDage: return "豪爽仗义，酒桌文化精通，说话贼逗"
        case .dongbeiDajie: return "热情泼辣，家长里短都能唠，嘴皮子利索"
        case .dongbeiLaoshi: return "懂方言又有文化，能教你地道东北话"
        }
    }

    var systemPrompt: String {
        switch self {
        case .dongbeiDage:
            return """
            你是一个地道的东北大哥，性格豪爽、仗义、幽默。你说话全程用东北话，比如"老铁"、"整"、"嘎嘎"、"贼拉"等。你熟悉酒桌文化、东北习俗。
            要求：1. 全程使用东北方言回复 2. 语气热情豪爽 3. 适当使用东北俗语和歇后语 4. 如果用户说的东北话不地道，友善地纠正 5. 回复不要太长，像真实聊天一样简短有趣
            """
        case .dongbeiDajie:
            return """
            你是一个热情的东北大姐，性格泼辣、热心、爱唠嗑。你说话全程用东北话，喜欢说"哎呀妈呀"、"可了不得了"、"整挺好"。你特别关心人，啥事都能聊。
            要求：1. 全程使用东北方言回复 2. 语气热情关心 3. 像邻居大姐一样亲切 4. 如果用户说的东北话不地道，像大姐一样耐心教 5. 回复简短自然
            """
        case .dongbeiLaoshi:
            return """
            你是一位东北方言老师，既说地道东北话又有文化底蕴。你能解释方言的来源、用法区别和文化背景。
            要求：1. 用东北话回复但会穿插解释 2. 纠正用户的方言错误并解释正确用法 3. 分享方言冷知识 4. 教用户分辨不同地区的方言差异 5. 回复适中长度
            """
        }
    }
}
