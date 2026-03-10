import Foundation

// MARK: - Sage API Manager
/// Handles all communication with the Sage AI API.
/// Responsible for sending prompts and receiving responses.
final class SageAPIManager {
    
    // MARK: - Singleton
    
    static let shared = SageAPIManager()
    
    // MARK: - Configuration
    
    /// API endpoint - using OpenAI compatible API
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    
    /// Model to use
    private let model = "gpt-4o-mini"
    
    /// Maximum tokens in response
    private let maxTokens = 500
    
    /// Temperature for responses
    private let temperature = 0.7
    
    // MARK: - Private Properties
    
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// Sends a prompt to the AI and returns the response
    /// - Parameter messages: Array of prompt messages
    /// - Returns: The AI response string
    func sendPrompt(_ messages: [PromptMessage]) async throws -> String {
        // Get API key from Keychain
        guard let apiKey = KeychainManager.shared.getAPIKey() else {
            throw APIError.missingAPIKey
        }
        
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw APIError.noConnection
        }
        
        // Build request
        guard let url = URL(string: apiEndpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = APIRequest(
            model: model,
            messages: messages,
            max_tokens: maxTokens,
            temperature: temperature,
            response_format: ResponseFormat(type: "json_object")
        )
        
        request.httpBody = try encoder.encode(body)
        
        // Log request
        let startTime = Date()
        Logger.shared.logAPIRequest(endpoint: "chat/completions", method: "POST")
        
        // Send request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Calculate latency
            let latency = Date().timeIntervalSince(startTime)
            
            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            Logger.shared.logAPIResponse(
                endpoint: "chat/completions",
                statusCode: httpResponse.statusCode,
                latency: latency
            )
            
            // Handle error status codes
            if httpResponse.statusCode != 200 {
                if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                    throw APIError.apiError(message: errorResponse.error.message)
                }
                throw APIError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Parse response
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            
            guard let content = apiResponse.choices.first?.message.content else {
                throw APIError.emptyResponse
            }
            
            return content
            
        } catch let error as APIError {
            Logger.shared.logAPIError(endpoint: "chat/completions", error: error)
            throw error
        } catch {
            Logger.shared.logAPIError(endpoint: "chat/completions", error: error)
            throw APIError.networkError(underlying: error)
        }
    }
    
    /// Decomposes a goal into tasks
    func decomposeGoal(
        _ goalText: String,
        energyLevel: EnergyLevel,
        context: [ConversationMessage] = []
    ) async throws -> ResponseParser.GoalDecompositionResponse {
        let messages = PromptBuilder.buildGoalDecompositionPrompt(
            goal: goalText,
            energyLevel: energyLevel,
            context: context
        )
        
        let response = try await sendPrompt(messages)
        
        guard let jsonString = ResponseParser.extractJSON(from: response) else {
            throw APIError.invalidResponse
        }
        
        return try ResponseParser.parseGoalDecomposition(from: jsonString)
    }
    
    /// Gets a response for task completion
    func getTaskCompletionResponse(
        completedTask: SageTask,
        nextTask: SageTask?,
        goal: Goal
    ) async throws -> ResponseParser.TaskCompletionResponse {
        let messages = PromptBuilder.buildTaskCompletionPrompt(
            completedTask: completedTask,
            nextTask: nextTask,
            goal: goal
        )
        
        let response = try await sendPrompt(messages)
        
        guard let jsonString = ResponseParser.extractJSON(from: response) else {
            throw APIError.invalidResponse
        }
        
        return try ResponseParser.parseTaskCompletion(from: jsonString)
    }
    
    /// Handles user resistance with a smaller task
    func handleResistance(
        currentTask: SageTask,
        userMessage: String
    ) async throws -> ResponseParser.ResistanceResponse {
        let messages = PromptBuilder.buildResistancePrompt(
            currentTask: currentTask,
            userMessage: userMessage
        )
        
        let response = try await sendPrompt(messages)
        
        guard let jsonString = ResponseParser.extractJSON(from: response) else {
            throw APIError.invalidResponse
        }
        
        return try ResponseParser.parseResistance(from: jsonString)
    }
    
    /// General conversation response
    func getConversationResponse(
        userMessage: String,
        context: [ConversationMessage],
        currentGoal: Goal?
    ) async throws -> ResponseParser.ConversationResponse {
        let messages = PromptBuilder.buildConversationPrompt(
            userMessage: userMessage,
            context: context,
            currentGoal: currentGoal
        )
        
        let response = try await sendPrompt(messages)
        
        guard let jsonString = ResponseParser.extractJSON(from: response) else {
            throw APIError.invalidResponse
        }
        
        return try ResponseParser.parseConversation(from: jsonString)
    }
    
    // MARK: - Error Types
    
    enum APIError: LocalizedError {
        case missingAPIKey
        case noConnection
        case invalidURL
        case invalidResponse
        case emptyResponse
        case httpError(statusCode: Int)
        case apiError(message: String)
        case networkError(underlying: Error)
        case rateLimited
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Please set your API key in Settings"
            case .noConnection:
                return "No internet connection"
            case .invalidURL:
                return "Invalid API URL"
            case .invalidResponse:
                return "Received invalid response from server"
            case .emptyResponse:
                return "Received empty response from server"
            case .httpError(let code):
                return "Server error (code: \(code))"
            case .apiError(let message):
                return message
            case .networkError:
                return "Network request failed"
            case .rateLimited:
                return "Too many requests. Please wait a moment"
            }
        }
        
        /// User-friendly error message for display
        var userMessage: String {
            switch self {
            case .missingAPIKey:
                return "I need an API key to work. Please add one in Settings."
            case .noConnection:
                return "I can't connect right now. Let's try again when you have internet."
            case .rateLimited:
                return "I need a moment to catch my breath. Let's try again shortly."
            default:
                return "Something went wrong on my end. Let's try that again."
            }
        }
    }
}

// MARK: - API Request/Response Models

private struct APIRequest: Encodable {
    let model: String
    let messages: [PromptMessage]
    let max_tokens: Int
    let temperature: Double
    let response_format: ResponseFormat
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct APIResponse: Decodable {
    let choices: [Choice]
}

private struct Choice: Decodable {
    let message: Message
}

private struct Message: Decodable {
    let content: String?
}

private struct APIErrorResponse: Decodable {
    let error: APIErrorDetail
}

private struct APIErrorDetail: Decodable {
    let message: String
}
