import Foundation

// MARK: - Response Parser
/// Parses JSON responses from the Sage AI API.
/// Handles various response types and validates structure.
struct ResponseParser {
    
    // MARK: - Response Types
    
    /// Parsed goal decomposition response
    struct GoalDecompositionResponse {
        let introMessage: String
        let tasks: [ParsedTask]
        let firstTaskMessage: String
    }
    
    /// Parsed task data
    struct ParsedTask {
        let title: String
        let description: String?
        let estimatedMinutes: Int
    }
    
    /// Parsed task completion response
    struct TaskCompletionResponse {
        let completionMessage: String
        let transitionMessage: String?
        let celebrationMessage: String?
    }
    
    /// Parsed resistance response
    struct ResistanceResponse {
        let empathyMessage: String
        let smallerTask: ParsedTask
        let encouragement: String
    }
    
    /// Parsed conversation response
    struct ConversationResponse {
        let message: String
        let action: ConversationAction
    }
    
    /// Possible conversation actions
    enum ConversationAction: String {
        case none
        case newGoal = "new_goal"
        case completeTask = "complete_task"
        case skipTask = "skip_task"
        case makeSmaller = "make_smaller"
    }
    
    // MARK: - Parsing Methods
    
    /// Parses a goal decomposition response
    static func parseGoalDecomposition(from json: String) throws -> GoalDecompositionResponse {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoded = try JSONDecoder().decode(GoalDecompositionJSON.self, from: data)
        
        let tasks = decoded.tasks.map { task in
            ParsedTask(
                title: task.title,
                description: task.description,
                estimatedMinutes: task.estimated_minutes ?? 15
            )
        }
        
        return GoalDecompositionResponse(
            introMessage: decoded.intro_message,
            tasks: tasks,
            firstTaskMessage: decoded.first_task_message
        )
    }
    
    /// Parses a task completion response
    static func parseTaskCompletion(from json: String) throws -> TaskCompletionResponse {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoded = try JSONDecoder().decode(TaskCompletionJSON.self, from: data)
        
        return TaskCompletionResponse(
            completionMessage: decoded.completion_message,
            transitionMessage: decoded.transition_message,
            celebrationMessage: decoded.celebration_message
        )
    }
    
    /// Parses a resistance response
    static func parseResistance(from json: String) throws -> ResistanceResponse {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoded = try JSONDecoder().decode(ResistanceJSON.self, from: data)
        
        let smallerTask = ParsedTask(
            title: decoded.smaller_task.title,
            description: decoded.smaller_task.description,
            estimatedMinutes: decoded.smaller_task.estimated_minutes ?? 5
        )
        
        return ResistanceResponse(
            empathyMessage: decoded.empathy_message,
            smallerTask: smallerTask,
            encouragement: decoded.encouragement
        )
    }
    
    /// Parses a conversation response
    static func parseConversation(from json: String) throws -> ConversationResponse {
        guard let data = json.data(using: .utf8) else {
            throw ParsingError.invalidJSON
        }
        
        let decoded = try JSONDecoder().decode(ConversationJSON.self, from: data)
        
        let action = ConversationAction(rawValue: decoded.action) ?? .none
        
        return ConversationResponse(
            message: decoded.message,
            action: action
        )
    }
    
    /// Extracts JSON from a potentially messy API response
    static func extractJSON(from response: String) -> String? {
        // Try to find JSON object in the response
        guard let startIndex = response.firstIndex(of: "{"),
              let endIndex = response.lastIndex(of: "}") else {
            return nil
        }
        
        let jsonString = String(response[startIndex...endIndex])
        
        // Validate it's parseable
        guard let data = jsonString.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            return nil
        }
        
        return jsonString
    }
    
    // MARK: - Error Types
    
    enum ParsingError: LocalizedError {
        case invalidJSON
        case missingRequiredField(String)
        case unexpectedFormat
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON:
                return "Could not parse response as JSON"
            case .missingRequiredField(let field):
                return "Missing required field: \(field)"
            case .unexpectedFormat:
                return "Response format was unexpected"
            }
        }
    }
}

// MARK: - JSON Decodable Structures

private struct GoalDecompositionJSON: Decodable {
    let intro_message: String
    let tasks: [TaskJSON]
    let first_task_message: String
}

private struct TaskJSON: Decodable {
    let title: String
    let description: String?
    let estimated_minutes: Int?
}

private struct TaskCompletionJSON: Decodable {
    let completion_message: String
    let transition_message: String?
    let celebration_message: String?
}

private struct ResistanceJSON: Decodable {
    let empathy_message: String
    let smaller_task: TaskJSON
    let encouragement: String
}

private struct ConversationJSON: Decodable {
    let message: String
    let action: String
}
