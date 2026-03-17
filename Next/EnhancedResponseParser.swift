import Foundation

// MARK: - Enhanced Response Parser
/// Improved response parsing with detailed error handling and fallback strategies
extension ResponseParser {
    
    /// Safely parses goal decomposition with fallback
    static func safeParseGoalDecomposition(from jsonString: String) -> GoalDecompositionResponse? {
        do {
            let response = try parseGoalDecomposition(from: jsonString)
            
            // Validate response
            guard !response.introMessage.isEmpty,
                  !response.tasks.isEmpty else {
                Logger.shared.error("Invalid goal decomposition: empty content")
                return nil
            }
            
            Logger.shared.info("Successfully parsed goal decomposition with \(response.tasks.count) tasks")
            return response
        } catch {
            Logger.shared.error("Goal decomposition parsing failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Safely parses task completion with fallback
    static func safeParseTaskCompletion(from jsonString: String) -> TaskCompletionResponse? {
        do {
            let response = try parseTaskCompletion(from: jsonString)
            
            // Validate
            guard !response.completionMessage.isEmpty else {
                Logger.shared.error("Invalid task completion: empty message")
                return nil
            }
            
            Logger.shared.info("Successfully parsed task completion")
            return response
        } catch {
            Logger.shared.error("Task completion parsing failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Safely parses resistance with fallback
    static func safeParseResistance(from jsonString: String) -> ResistanceResponse? {
        do {
            let response = try parseResistance(from: jsonString)
            
            // Validate
            guard !response.empathyMessage.isEmpty,
                  !response.smallerTask.title.isEmpty else {
                Logger.shared.error("Invalid resistance response: missing fields")
                return nil
            }
            
            Logger.shared.info("Successfully parsed resistance response")
            return response
        } catch {
            Logger.shared.error("Resistance parsing failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Safely parses conversation with fallback
    static func safeParseConversation(from jsonString: String) -> ConversationResponse? {
        do {
            let response = try parseConversation(from: jsonString)
            
            // Validate
            guard !response.message.isEmpty else {
                Logger.shared.error("Invalid conversation response: empty message")
                return nil
            }
            
            Logger.shared.info("Successfully parsed conversation response")
            return response
        } catch {
            Logger.shared.error("Conversation parsing failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Extracts and validates JSON with detailed error reporting
    static func extractAndValidateJSON(from response: String) -> String? {
        // First, try exact JSON extraction
        guard let jsonString = extractJSON(from: response) else {
            Logger.shared.error("Failed to extract JSON from response")
            return nil
        }
        
        // Verify it's valid JSON
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data),
              json is NSDictionary || json is NSArray else {
            Logger.shared.error("Extracted string is not valid JSON")
            return nil
        }
        
        Logger.shared.info("Successfully extracted and validated JSON")
        return jsonString
    }
    
    /// Parses with automatic error recovery
    static func parseGoalDecompositionWithRecovery(from response: String) -> GoalDecompositionResponse? {
        // Try clean data first
        if let cleanJson = extractAndValidateJSON(from: response),
           let result = safeParseGoalDecomposition(from: cleanJson) {
            return result
        }
        
        // Try extracting from markdown code blocks
        if let codeBlock = extractJSONFromMarkdown(response),
           let result = safeParseGoalDecomposition(from: codeBlock) {
            return result
        }
        
        Logger.shared.error("Failed to parse goal decomposition with recovery")
        return nil
    }
    
    /// Parses response from markdown code blocks
    static func extractJSONFromMarkdown(_ text: String) -> String? {
        // Look for ```json ... ``` blocks
        let pattern = "```(?:json)?\\s*([\\s\\S]*?)```"
        
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let nsRange = NSRange(text.startIndex..., in: text)
        
        if let match = regex.firstMatch(in: text, range: nsRange),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    /// Validates response against expected structure
    static func validateResponseStructure(_ jsonString: String, expectedType: String) -> Bool {
        guard let data = jsonString.data(using: .utf8) else {
            return false
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            switch expectedType {
            case "goalDecomposition":
                return json?["intro_message"] != nil &&
                       json?["tasks"] != nil &&
                       json?["first_task_message"] != nil
            case "taskCompletion":
                return json?["completion_message"] != nil
            case "resistance":
                return json?["empathy_message"] != nil &&
                       json?["smaller_task"] != nil &&
                       json?["encouragement"] != nil
            case "conversation":
                return json?["message"] != nil &&
                       json?["action"] != nil
            default:
                return false
            }
        } catch {
            return false
        }
    }
}

// MARK: - Response Health Check
/// Monitors API response health and logs issues
struct ResponseHealthMonitor {
    static let shared = ResponseHealthMonitor()
    
    private var successCount = 0
    private var failureCount = 0
    private var lastErrorTime: Date?
    
    mutating func recordSuccess() {
        successCount += 1
        Logger.shared.info("API success rate: \(getSuccessRate())%")
    }
    
    mutating func recordFailure(_ error: Error) {
        failureCount += 1
        lastErrorTime = Date()
        Logger.shared.error("API failure: \(error.localizedDescription) (failure rate: \(getFailureRate())%)")
    }
    
    func getSuccessRate() -> Int {
        let total = successCount + failureCount
        guard total > 0 else { return 100 }
        return Int(Double(successCount) / Double(total) * 100)
    }
    
    func getFailureRate() -> Int {
        100 - getSuccessRate()
    }
    
    mutating func reset() {
        successCount = 0
        failureCount = 0
        lastErrorTime = nil
    }
}
