import Foundation

class AIService {
    // 支持的 API 提供商
    enum Provider: String, CaseIterable {
        case deepseek = "deepseek"
        case openai = "openai"

        var displayName: String {
            switch self {
            case .deepseek: return "DeepSeek"
            case .openai: return "OpenAI"
            }
        }

        var baseURL: String {
            switch self {
            case .deepseek: return "https://api.deepseek.com/v1/chat/completions"
            case .openai: return "https://api.openai.com/v1/chat/completions"
            }
        }

        var defaultModel: String {
            switch self {
            case .deepseek: return "deepseek-chat"
            case .openai: return "gpt-4o-mini"
            }
        }
    }

    // UserDefaults keys
    static let apiKeyKey = "laotie_ai_api_key"
    static let providerKey = "laotie_ai_provider"

    var apiKey: String? {
        get { UserDefaults.standard.string(forKey: Self.apiKeyKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.apiKeyKey) }
    }

    var provider: Provider {
        get {
            if let raw = UserDefaults.standard.string(forKey: Self.providerKey),
               let p = Provider(rawValue: raw) { return p }
            return .deepseek
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: Self.providerKey) }
    }

    var isConfigured: Bool { apiKey != nil && !apiKey!.isEmpty }

    func sendMessage(messages: [ChatMessage], character: AICharacter) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIError.noAPIKey
        }

        guard let url = URL(string: provider.baseURL) else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // 构建消息数组
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": character.systemPrompt]
        ]
        for msg in messages.suffix(20) {
            if msg.role != .system {
                apiMessages.append([
                    "role": msg.role == .user ? "user" : "assistant",
                    "content": msg.content
                ])
            }
        }

        let body: [String: Any] = [
            "model": provider.defaultModel,
            "messages": apiMessages,
            "max_tokens": 500,
            "temperature": 0.8
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        if httpResponse.statusCode != 200 {
            throw AIError.apiError(httpResponse.statusCode)
        }

        // 解析响应
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let message = first["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
        }

        throw AIError.parseError
    }

    enum AIError: LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError
        case apiError(Int)
        case parseError

        var errorDescription: String? {
            switch self {
            case .noAPIKey: return "还没配置 AI API Key 呢，去设置里整一个"
            case .invalidURL: return "API 地址不对，检查一下"
            case .networkError: return "网络不给力，等会儿再试试"
            case .apiError(let code): return "AI 服务出错了（\(code)），稍后再试"
            case .parseError: return "AI 说的话没听懂，再试一次"
            }
        }
    }
}
