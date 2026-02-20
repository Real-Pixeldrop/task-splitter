import Foundation

enum AIProviderType: String, Codable, CaseIterable {
    case anthropic = "Anthropic (Claude)"
    case openai = "OpenAI (GPT)"
    case ollama = "Ollama (Local)"

    var needsApiKey: Bool {
        switch self {
        case .anthropic, .openai: return true
        case .ollama: return false
        }
    }

    var placeholder: String {
        switch self {
        case .anthropic: return "sk-ant-..."
        case .openai: return "sk-..."
        case .ollama: return ""
        }
    }

    var icon: String {
        switch self {
        case .anthropic: return "brain.head.profile"
        case .openai: return "sparkles"
        case .ollama: return "desktopcomputer"
        }
    }

    var description: String {
        switch self {
        case .anthropic: return "Claude Sonnet — rapide et intelligent"
        case .openai: return "GPT-4o — polyvalent"
        case .ollama: return "Gratuit, tourne sur ton Mac"
        }
    }
}

struct AIProviderConfig: Codable {
    var selectedProvider: AIProviderType
    var anthropicKey: String
    var openaiKey: String
    var ollamaModel: String
    var ollamaURL: String

    init() {
        self.selectedProvider = .ollama
        self.anthropicKey = ""
        self.openaiKey = ""
        self.ollamaModel = "llama3.2"
        self.ollamaURL = "http://localhost:11434"
    }
}

class AIProvider {
    private var config: AIProviderConfig
    private let configFile: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("TaskSplitter")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        configFile = appDir.appendingPathComponent("provider.json")

        // Load config
        if let data = try? Data(contentsOf: configFile),
           let saved = try? JSONDecoder().decode(AIProviderConfig.self, from: data) {
            config = saved
        } else {
            config = AIProviderConfig()
            // Migrate old api_key file if exists
            let oldKeyFile = appDir.appendingPathComponent("api_key")
            if let oldKey = try? String(contentsOf: oldKeyFile, encoding: .utf8) {
                let key = oldKey.trimmingCharacters(in: .whitespacesAndNewlines)
                if !key.isEmpty {
                    config.anthropicKey = key
                    config.selectedProvider = .anthropic
                    saveConfig()
                }
            }
        }
    }

    var currentConfig: AIProviderConfig {
        get { config }
        set {
            config = newValue
            saveConfig()
        }
    }

    var isConfigured: Bool {
        switch config.selectedProvider {
        case .anthropic: return !config.anthropicKey.isEmpty
        case .openai: return !config.openaiKey.isEmpty
        case .ollama: return true
        }
    }

    var providerName: String {
        config.selectedProvider.rawValue
    }

    func saveConfig() {
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: configFile)
        }
    }

    func splitTask(prompt: String, completion: @escaping (String?) -> Void) {
        switch config.selectedProvider {
        case .anthropic:
            callAnthropic(prompt: prompt, completion: completion)
        case .openai:
            callOpenAI(prompt: prompt, completion: completion)
        case .ollama:
            callOllama(prompt: prompt, completion: completion)
        }
    }

    // MARK: - Anthropic

    private func callAnthropic(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(config.anthropicKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 500,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let first = content.first,
                  let text = first["text"] as? String else {
                completion(nil)
                return
            }
            completion(text.isEmpty ? nil : text)
        }.resume()
    }

    // MARK: - OpenAI

    private func callOpenAI(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(config.openaiKey)", forHTTPHeaderField: "authorization")

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "max_tokens": 500,
            "messages": [["role": "user", "content": prompt]]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                completion(nil)
                return
            }
            completion(text.isEmpty ? nil : text)
        }.resume()
    }

    // MARK: - Ollama

    private func callOllama(prompt: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(config.ollamaURL)/api/generate") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": config.ollamaModel,
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let text = json["response"] as? String else {
                completion(nil)
                return
            }
            completion(text.isEmpty ? nil : text)
        }.resume()
    }
}
