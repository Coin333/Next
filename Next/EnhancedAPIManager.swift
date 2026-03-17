import Foundation

// MARK: - Enhanced API Manager with Retry Logic
/// Wraps SageAPIManager with automatic retry logic and exponential backoff.
/// Improves reliability and handles transient errors gracefully.
final class EnhancedAPIManager {
    
    // MARK: - Singleton
    
    static let shared = EnhancedAPIManager()
    
    // MARK: - Configuration
    
    private let apiManager = SageAPIManager.shared
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 1.0
    
    // MARK: - Private Properties
    
    private var retryCount: [String: Int] = [:]
    
    // MARK: - Public Methods
    
    /// Decomposes a goal with automatic retry
    func decomposeGoal(
        _ goalText: String,
        energyLevel: EnergyLevel,
        context: [ConversationMessage] = []
    ) async throws -> ResponseParser.GoalDecompositionResponse {
        return try await retryWithExponentialBackoff { [weak self] in
            try await self?.apiManager.decomposeGoal(goalText, energyLevel: energyLevel, context: context) ?? { throw SageAPIManager.APIError.invalidResponse }()
        }
    }
    
    /// Gets task completion response with automatic retry
    func getTaskCompletionResponse(
        completedTask: SageTask,
        nextTask: SageTask?,
        goal: Goal
    ) async throws -> ResponseParser.TaskCompletionResponse {
        return try await retryWithExponentialBackoff { [weak self] in
            try await self?.apiManager.getTaskCompletionResponse(
                completedTask: completedTask,
                nextTask: nextTask,
                goal: goal
            ) ?? { throw SageAPIManager.APIError.invalidResponse }()
        }
    }
    
    /// Handles resistance with automatic retry
    func handleResistance(
        currentTask: SageTask,
        userMessage: String
    ) async throws -> ResponseParser.ResistanceResponse {
        return try await retryWithExponentialBackoff { [weak self] in
            try await self?.apiManager.handleResistance(
                currentTask: currentTask,
                userMessage: userMessage
            ) ?? { throw SageAPIManager.APIError.invalidResponse }()
        }
    }
    
    /// Gets conversation response with automatic retry
    func getConversationResponse(
        userMessage: String,
        context: [ConversationMessage],
        currentGoal: Goal?
    ) async throws -> ResponseParser.ConversationResponse {
        return try await retryWithExponentialBackoff { [weak self] in
            try await self?.apiManager.getConversationResponse(
                userMessage: userMessage,
                context: context,
                currentGoal: currentGoal
            ) ?? { throw SageAPIManager.APIError.invalidResponse }()
        }
    }
    
    // MARK: - Private Methods
    
    /// Retries with exponential backoff
    private func retryWithExponentialBackoff<T>(
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch let error as SageAPIManager.APIError {
                lastError = error
                
                // Don't retry for these errors
                switch error {
                case .missingAPIKey, .invalidURL:
                    throw error
                case .rateLimited, .noConnection, .networkError:
                    // Retry these
                    break
                default:
                    // Retry on other errors
                    break
                }
                
                // If this is the last attempt, throw
                if attempt == maxRetries - 1 {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = baseRetryDelay * pow(2, Double(attempt))
                
                Logger.shared.info("API request failed (attempt \(attempt + 1)/\(maxRetries)). Retrying in \(delay)s...")
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                lastError = error
                
                // Non-API errors - try once more
                if attempt == maxRetries - 1 {
                    throw error
                }
                
                let delay = baseRetryDelay * pow(2, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? SageAPIManager.APIError.networkError(underlying: NSError(domain: "UnknownError", code: -1))
    }
}

// MARK: -Response Validation
/// Validates API responses for correctness
struct ResponseValidator {
    
    /// Validates a goal decomposition response
    static func validateGoalDecomposition(_ response: ResponseParser.GoalDecompositionResponse) -> Bool {
        // Must have intro and at least one task
        guard !response.introMessage.isEmpty,
              !response.tasks.isEmpty else {
            return false
        }
        
        // Tasks must have title and reasonable duration
        return response.tasks.allSatisfy { task in
            !task.title.isEmpty && task.estimatedMinutes > 0
        }
    }
    
    /// Validates a task completion response
    static func validateTaskCompletion(_ response: ResponseParser.TaskCompletionResponse) -> Bool {
        return !response.completionMessage.isEmpty
    }
    
    /// Validates a resistance response
    static func validateResistance(_ response: ResponseParser.ResistanceResponse) -> Bool {
        return !response.empathyMessage.isEmpty &&
               !response.smallerTask.title.isEmpty &&
               response.smallerTask.estimatedMinutes > 0 &&
               !response.encouragement.isEmpty
    }
    
    /// Validates a conversation response
    static func validateConversation(_ response: ResponseParser.ConversationResponse) -> Bool {
        return !response.message.isEmpty
    }
}
