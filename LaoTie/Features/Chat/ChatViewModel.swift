import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCharacter: AICharacter = .dongbeiDage

    private nonisolated(unsafe) let aiService = AIService()

    var isConfigured: Bool { aiService.isConfigured }

    // 预设开场白
    private let greetings: [AICharacter: [String]] = [
        .dongbeiDage: [
            "哎，老铁来了！咋的，今天想唠点啥？",
            "哥们儿！整啥呢？来来来，唠唠",
            "老铁，可算来了！我这等你半天了，快坐下唠唠"
        ],
        .dongbeiDajie: [
            "哎呀，来啦！快坐快坐，大姐跟你唠唠",
            "哎，小宝贝儿来了！想你大姐了没？",
            "哎呀妈呀，可算来了！大姐给你说个事儿"
        ],
        .dongbeiLaoshi: [
            "同学好！今天想学点啥东北话？尽管问",
            "来了啊，有啥想了解的东北方言知识？",
            "欢迎来上课！今天咱整点啥方言知识？"
        ]
    ]

    func startNewConversation() {
        messages.removeAll()
        errorMessage = nil
        if let greetingList = greetings[selectedCharacter],
           let greeting = greetingList.randomElement() {
            messages.append(ChatMessage(role: .assistant, content: greeting))
        }
    }

    func switchCharacter(to character: AICharacter) {
        guard character != selectedCharacter else { return }
        selectedCharacter = character
        startNewConversation()
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true
        errorMessage = nil

        do {
            let response = try await aiService.sendMessage(messages: messages, character: selectedCharacter)
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            errorMessage = error.localizedDescription
            // Fallback: 预设回复
            let fallbacks = [
                "哎呀，信号不好，没听清你说啥，再说一遍呗",
                "等会儿啊，我这脑瓜子转不过来了",
                "不好意思老铁，刚走神了，你说啥来着？"
            ]
            messages.append(ChatMessage(role: .assistant, content: fallbacks.randomElement() ?? "啥？"))
        }

        isLoading = false
    }
}
