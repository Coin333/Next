import Foundation

// MARK: - Resistance Model
/// Tracks and predicts user resistance patterns.
/// Detects when users are avoiding tasks and identifies resistance triggers.
final class ResistanceModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var taskResistanceScores: [UUID: Float] = [:]
    @Published private(set) var overallResistanceLevel: ResistanceLevel = .none
    
    // MARK: - Private Properties
    
    private var resistanceHistory: [ResistanceEvent] = []
    private let maxHistorySize = 100
    
    // MARK: - Initialization
    
    init() {
        // Loads from storage if available
    }
    
    // MARK: - Core Methods
    
    /// Records a task skip or delay
    func recordSkip(for taskId: UUID, delaySeconds: TimeInterval) {
        let event = ResistanceEvent(
            taskId: taskId,
            type: .skip,
            timestamp: Date(),
            delaySeconds: delaySeconds
        )
        
        addResistanceEvent(event)
        updateTaskResistanceScore(for: taskId, increase: 0.3)
    }
    
    /// Records user declining a task
    func recordDecline(for taskId: UUID, reason: String = "") {
        let event = ResistanceEvent(
            taskId: taskId,
            type: .decline,
            timestamp: Date(),
            reason: reason
        )
        
        addResistanceEvent(event)
        updateTaskResistanceScore(for: taskId, increase: 0.25)
    }
    
    /// Records user starting a task (reduces resistance)
    func recordStart(for taskId: UUID) {
        let event = ResistanceEvent(
            taskId: taskId,
            type: .started,
            timestamp: Date()
        )
        
        addResistanceEvent(event)
        updateTaskResistanceScore(for: taskId, increase: -0.4) // Reduce resistance
    }
    
    /// Records task completion (significantly reduces resistance)
    func recordCompletion(for taskId: UUID) {
        let event = ResistanceEvent(
            taskId: taskId,
            type: .completed,
            timestamp: Date()
        )
        
        addResistanceEvent(event)
        updateTaskResistanceScore(for: taskId, increase: -0.5) // Strong reduction
    }
    
    /// Detects anti-avoidance patterns (repeated delays, app switching, etc.)
    func detectAntiAvoidancePatterns(for taskId: UUID) -> AntiAvoidancePattern? {
        let recentEvents = resistanceHistory
            .filter { $0.taskId == taskId }
            .suffix(10)
        
        let skipCount = recentEvents.filter { $0.type == .skip }.count
        let declineCount = recentEvents.filter { $0.type == .decline }.count
        let totalResistances = skipCount + declineCount
        
        if totalResistances >= 3 {
            return .repeatedAvoidance(count: totalResistances)
        }
        
        if skipCount == 2 {
            return .taskSpecificResistance
        }
        
        return nil
    }
    
    /// Gets resistance level for a specific task
    func getResistanceLevel(for task: SageTask) -> ResistanceLevel {
        let score = taskResistanceScores[task.id] ?? 0
        
        if score >= 0.6 {
            return .high
        } else if score >= 0.3 {
            return .low
        } else {
            return .none
        }
    }
    
    /// Predicts if user will resist the next task
    func predictResistance(for tasks: [SageTask]) -> SageTask? {
        return tasks.first { task in
            getResistanceLevel(for: task) == .high
        }
    }
    
    /// Resets resistance scores gradually (natural fade-out)
    func decayResistanceScores() {
        for (taskId, score) in taskResistanceScores {
            let decayedScore = max(0, score - 0.05) // Reduce by 5% each period
            taskResistanceScores[taskId] = decayedScore
        }
    }
    
    // MARK: - Private Methods
    
    private func addResistanceEvent(_ event: ResistanceEvent) {
        resistanceHistory.append(event)
        
        // Maintain max history size
        if resistanceHistory.count > maxHistorySize {
            resistanceHistory.removeFirst(resistanceHistory.count - maxHistorySize)
        }
        
        updateOverallResistanceLevel()
    }
    
    private func updateTaskResistanceScore(for taskId: UUID, increase: Float) {
        let currentScore = taskResistanceScores[taskId] ?? 0
        let newScore = max(0, min(1, currentScore + increase)) // Clamp 0-1
        taskResistanceScores[taskId] = newScore
    }
    
    private func updateOverallResistanceLevel() {
        let averageScore = taskResistanceScores.values.isEmpty ? 0 :
            taskResistanceScores.values.reduce(0, +) / Float(taskResistanceScores.count)
        
        if averageScore >= 0.6 {
            overallResistanceLevel = .high
        } else if averageScore >= 0.3 {
            overallResistanceLevel = .low
        } else {
            overallResistanceLevel = .none
        }
    }
}

// MARK: - Resistance Event

private struct ResistanceEvent {
    enum EventType {
        case skip
        case decline
        case started
        case completed
    }
    
    let taskId: UUID
    let type: EventType
    let timestamp: Date
    let delaySeconds: TimeInterval?
    let reason: String?
    
    init(
        taskId: UUID,
        type: EventType,
        timestamp: Date,
        delaySeconds: TimeInterval? = nil,
        reason: String? = nil
    ) {
        self.taskId = taskId
        self.type = type
        self.timestamp = timestamp
        self.delaySeconds = delaySeconds
        self.reason = reason
    }
}

// MARK: - Anti-Avoidance Pattern

enum AntiAvoidancePattern {
    case repeatedAvoidance(count: Int)
    case taskSpecificResistance
    case highFrequencySkipping
    
    var requiresIntervention: Bool {
        switch self {
        case .repeatedAvoidance(let count):
            return count >= 3
        case .taskSpecificResistance:
            return true
        case .highFrequencySkipping:
            return true
        }
    }
    
    var suggestedAction: String {
        switch self {
        case .repeatedAvoidance(let count):
            return "Consider breaking this task into smaller steps or taking a break"
        case .taskSpecificResistance:
            return "This task is giving you trouble. Let's try a different approach"
        case .highFrequencySkipping:
            return "You're skipping tasks frequently. Let's adjust what we're offering"
        }
    }
}
