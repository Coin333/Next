import Foundation

// MARK: - Conversation State
/// Tracks the conversational state between the user and Sage.
/// Manages context, history, and current interaction state.
struct ConversationState: Codable {
    
    /// Current phase of the conversation
    var phase: ConversationPhase
    
    /// Conversation history for context
    var history: [ConversationMessage]
    
    /// Current active goal being worked on
    var activeGoalId: UUID?
    
    /// Whether Sage is currently speaking
    var isSageSpeaking: Bool
    
    /// Whether the user is currently speaking
    var isUserSpeaking: Bool
    
    /// Last interaction timestamp
    var lastInteractionAt: Date?
    
    /// User's current energy level (affects task sizing)
    var energyLevel: EnergyLevel
    
    /// Session start time
    let sessionStartedAt: Date
    
    // MARK: - Initialization
    
    init() {
        self.phase = .idle
        self.history = []
        self.activeGoalId = nil
        self.isSageSpeaking = false
        self.isUserSpeaking = false
        self.lastInteractionAt = nil
        self.energyLevel = .medium
        self.sessionStartedAt = Date()
    }
    
    // MARK: - History Management
    
    /// Adds a message to the conversation history
    mutating func addMessage(_ message: ConversationMessage) {
        history.append(message)
        lastInteractionAt = Date()
        
        // Keep history manageable (last 20 messages for context)
        if history.count > 20 {
            history = Array(history.suffix(20))
        }
    }
    
    /// Adds a user message
    mutating func addUserMessage(_ text: String) {
        let message = ConversationMessage(role: .user, content: text)
        addMessage(message)
    }
    
    /// Adds a Sage response
    mutating func addSageMessage(_ text: String) {
        let message = ConversationMessage(role: .sage, content: text)
        addMessage(message)
    }
    
    /// Gets recent conversation context for API requests
    func getRecentContext(messageCount: Int = 6) -> [ConversationMessage] {
        return Array(history.suffix(messageCount))
    }
    
    /// Clears conversation history
    mutating func clearHistory() {
        history.removeAll()
        lastInteractionAt = nil
    }
    
    /// Resets to initial state
    mutating func reset() {
        phase = .idle
        history.removeAll()
        activeGoalId = nil
        isSageSpeaking = false
        isUserSpeaking = false
        lastInteractionAt = nil
    }
}

// MARK: - Conversation Phase

enum ConversationPhase: String, Codable {
    /// No active conversation
    case idle
    
    /// Listening for user input
    case listening
    
    /// Processing user input / waiting for AI
    case processing
    
    /// Sage is speaking a response
    case responding
    
    /// User is working on a task
    case taskActive
    
    /// Reflecting on completed task
    case reflecting
    
    /// Celebrating goal completion
    case celebrating
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .responding: return "Sage"
        case .taskActive: return "Working"
        case .reflecting: return "Reflecting"
        case .celebrating: return "Celebrating"
        }
    }
}

// MARK: - Conversation Message

struct ConversationMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    init(id: UUID = UUID(), role: MessageRole, content: String) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case sage
    case system
}

// MARK: - Energy Level

enum EnergyLevel: String, Codable, CaseIterable {
    case low
    case medium
    case high
    
    var displayName: String {
        switch self {
        case .low: return "Low Energy"
        case .medium: return "Medium Energy"
        case .high: return "High Energy"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.100"
        }
    }
    
    /// Task time range for this energy level
    var taskTimeRange: ClosedRange<Int> {
        switch self {
        case .low: return 5...15
        case .medium: return 10...25
        case .high: return 15...40
        }
    }
    
    /// Description for Sage to use
    var contextDescription: String {
        switch self {
        case .low: return "very small, manageable steps (5-15 minutes each)"
        case .medium: return "moderate, balanced steps (10-25 minutes each)"
        case .high: return "substantial, focused steps (15-40 minutes each)"
        }
    }
}
