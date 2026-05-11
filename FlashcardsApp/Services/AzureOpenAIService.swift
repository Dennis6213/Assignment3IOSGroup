import Foundation

struct AzureOpenAIConfig {
    let endpoint: String
    let apiKey: String
    let deploymentName: String
    let apiVersion: String

    init(endpoint: String, apiKey: String, deploymentName: String, apiVersion: String = "2024-02-01") {
        self.endpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/ "))
        self.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
        self.deploymentName = deploymentName.trimmingCharacters(in: .whitespaces)
        self.apiVersion = apiVersion
    }

    var isValid: Bool {
        !endpoint.isEmpty && !apiKey.isEmpty && !deploymentName.isEmpty
    }

    func save() {
        UserDefaults.standard.set(endpoint, forKey: "azure_endpoint")
        UserDefaults.standard.set(apiKey, forKey: "azure_api_key")
        UserDefaults.standard.set(deploymentName, forKey: "azure_deployment")
    }

    static func load() -> AzureOpenAIConfig? {
        guard let endpoint = UserDefaults.standard.string(forKey: "azure_endpoint"),
              let apiKey = UserDefaults.standard.string(forKey: "azure_api_key"),
              let deployment = UserDefaults.standard.string(forKey: "azure_deployment"),
              !endpoint.isEmpty, !apiKey.isEmpty, !deployment.isEmpty else {
            return nil
        }
        return AzureOpenAIConfig(endpoint: endpoint, apiKey: apiKey, deploymentName: deployment)
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: "azure_endpoint")
        UserDefaults.standard.removeObject(forKey: "azure_api_key")
        UserDefaults.standard.removeObject(forKey: "azure_deployment")
    }
}

enum AIServiceError: LocalizedError {
    case notConfigured
    case invalidURL
    case networkError(String)
    case apiError(statusCode: Int, message: String)
    case invalidResponse
    case parsingFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Azure OpenAI is not configured. Please add your API settings first."
        case .invalidURL:
            return "Invalid Azure endpoint URL."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .invalidResponse:
            return "Received an invalid response from Azure OpenAI."
        case .parsingFailed(let detail):
            return "Failed to parse AI response into flashcards: \(detail)"
        }
    }
}

actor AzureOpenAIService {

    private let config: AzureOpenAIConfig

    init(config: AzureOpenAIConfig) {
        self.config = config
    }

    func generateFlashcards(topic: String, numberOfCards: Int = 10) async throws -> FlashcardImportData {
        let url = try buildURL()
        let request = try buildRequest(url: url, topic: topic, numberOfCards: numberOfCards)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw AIServiceError.apiError(statusCode: httpResponse.statusCode, message: body)
        }

        return try parseResponse(data)
    }

    private func buildURL() throws -> URL {
        let urlString = "\(config.endpoint)/openai/deployments/\(config.deploymentName)/chat/completions?api-version=\(config.apiVersion)"
        guard let url = URL(string: urlString) else {
            throw AIServiceError.invalidURL
        }
        return url
    }

    private func buildRequest(url: URL, topic: String, numberOfCards: Int) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(config.apiKey, forHTTPHeaderField: "api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let systemPrompt = """
        You are a flashcard generator. Generate exactly \(numberOfCards) flashcards about the given topic.

        Return ONLY valid JSON in this exact format (no markdown, no code fences, no explanation):
        {
          "deck_name": "Topic Name",
          "description": "Brief description of this deck",
          "cards": [
            {
              "front": "Question or prompt",
              "back": "Answer or explanation",
              "hint": "Optional hint"
            }
          ]
        }

        Rules:
        - Each card must have non-empty "front" and "back" fields
        - "hint" is optional but encouraged
        - Make questions clear, specific, and educational
        - Vary question types: definitions, comparisons, applications, examples
        - Return ONLY the raw JSON object
        """

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Generate \(numberOfCards) flashcards about: \(topic)"]
            ],
            "temperature": 0.7,
            "max_tokens": 4096
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    private func parseResponse(_ data: Data) throws -> FlashcardImportData {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }

        let cleanedContent = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            return try JSONImporter.parse(cleanedContent)
        } catch {
            throw AIServiceError.parsingFailed(error.localizedDescription)
        }
    }
}
