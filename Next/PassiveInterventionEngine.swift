import Foundation

// MARK: - Passive Intervention Engine
/// Triggers gentle interventions when user is inactive or drifting.
/// Detects inactivity, distraction patterns, and proactively offers guidance.
/// This is the NEW system that makes v3 proactive instead of reactive.
final class PassiveInterventionEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isInterventionNeeded = false
    @Published private(set) var currentIntervention: PassiveIntervention?
    @Published private(set) var inactivityDuration: TimeInterval = 0
    
    // MARK: - Dependencies
    
    private let energyModel: EnergyModel
    private let resistanceModel: ResistanceModel
    
    // MARK: - Private Properties
    
    private var lastActivityTime: Date = Date()
    private var inactivityTimer: Timer?
    private var lastInterventionTime: Date?
    private let minInterventionInterval: TimeInterval = 5 * 60 // 5 minutes between interventions
    
    // MARK: - Initialization
    
    init(energyModel: EnergyModel, resistanceModel: ResistanceModel) {
        self.energyModel = energyModel
        self.resistanceModel = resistanceModel
    }
    
    // MARK: - Core Methods
    
    /// Records user activity (resets inactivity timer)
    func recordActivity() {
        lastActivityTime = Date()
        inactivityDuration = 0
        inactivityTimer?.invalidate()
        startInactivityMonitoring()
    }
    
    /// Checks if passive intervention is needed
    func evaluateInterventionNeed(
        inactiveSeconds: TimeInterval,
        hasActiveTask: Bool
    ) -> PassiveIntervention? {
        
        inactivityDuration = inactiveSeconds
        
        // Don't intervene if there's no active task
        guard hasActiveTask else {
            // Consider suggesting task initiation
            if inactiveSeconds > 600 { // 10 minutes of no activity
                return .nudge(type: .idle, message: "Ready to get started?")
            }
            return nil
        }
        
        // Prevent too-frequent interventions
        if let lastTime = lastInterventionTime,
           Date().timeIntervalSince(lastTime) < minInterventionInterval {
            return nil
        }
        
        // Determine intervention type
        if inactiveSeconds > 1800 { // 30 minutes inactive
            return .breakSuggestion
        } else if inactiveSeconds > 600 { // 10 minutes
            return .nudge(type: .stuck, message: "Still with me?")
        } else if inactiveSeconds > 300 { // 5 minutes
            // Gentle check-in
            if energyModel.currentEnergyLevel == .low {
                return .nudge(type: .encouragement, message: "Just one more minute.")
            }
        }
        
        return nil
    }
    
    /// Generates intervention message based on current state
    func generateIntervention(
        taskTitle: String,
        energy: EnergyLevel,
        resistance: ResistanceLevel
    ) -> PassiveIntervention? {
        
        // Map detected patterns to interventions
        
        if resistance == .high && energy == .low {
            return .nudge(
                type: .gentle,
                message: "No pressure. Take it one step at a time."
            )
        }
        
        if inactivityDuration > 1200 { // 20 minutes
            return .breakSuggestion
        }
        
        if resistance == .high {
            return .taskReduction
        }
        
        return nil
    }
    
    /// Detects distraction patterns (app switching, repeated checks, etc.)
    func detectDistractionPattern(
        appSwitchCount: Int,
        checkFrequency: Double // checks per minute
    ) -> DistractionPattern? {
        
        if appSwitchCount > 5 && checkFrequency > 0.5 {
            return .heavyDistractionWithAppSwitching
        }
        
        if checkFrequency > 1.0 { // More than 1 check per minute
            return .compulsiveChecking
        }
        
        if appSwitchCount > 10 {
            return .avoidanceViaAppSwitching
        }
        
        return nil
    }
    
    /// Suggests breaks (smart break system)
    func suggestBreak(
        taskDurationMinutes: Int,
        energy: EnergyLevel
    ) -> BreakSuggestion {
        
        // Recommend break duration based on work duration and energy
        let breakDuration: Int
        
        if taskDurationMinutes > 45 {
            breakDuration = 10
        } else if taskDurationMinutes > 25 {
            breakDuration = 5
        } else {
            breakDuration = 2
        }
        
        // Suggest break type based on energy
        let breakType: BreakType
        
        if energy == .low {
            breakType = .walk // Physical movement helps
        } else {
            breakType = .breathing // Calming
        }
        
        return BreakSuggestion(
            duration: breakDuration,
            type: breakType,
            message: breakType.suggestionMessage(for: breakDuration)
        )
    }
    
    // MARK: - Private Methods
    
    private func startInactivityMonitoring() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.inactivityDuration += 30
        }
    }
}

// MARK: - Passive Intervention Types

enum PassiveIntervention {
    case nudge(type: NudgeType, message: String)
    case breakSuggestion
    case taskReduction
    case focusMode
    
    var priority: Int {
        switch self {
        case .nudge: return 1
        case .breakSuggestion: return 2
        case .taskReduction: return 3
        case .focusMode: return 4
        }
    }
}

enum NudgeType {
    case idle
    case stuck
    case encouragement
    case gentle
}

// MARK: - Distraction Pattern

enum DistractionPattern {
    case heavyDistractionWithAppSwitching
    case compulsiveChecking
    case avoidanceViaAppSwitching
    
    var requiresIntervention: Bool { true }
    
    var interventionMessage: String {
        switch self {
        case .heavyDistractionWithAppSwitching:
            return "I notice you're jumping between apps. Want to focus with me?"
        case .compulsiveChecking:
            return "You're checking frequently. Let's get back on track."
        case .avoidanceViaAppSwitching:
            return "Let's stay focused on this for just a bit longer."
        }
    }
}

// MARK: - Break Suggestion

struct BreakSuggestion {
    let duration: Int // minutes
    let type: BreakType
    let message: String
}

enum BreakType {
    case walk
    case breathing
    case stretch
    case rest
    
    func suggestionMessage(for duration: Int) -> String {
        switch self {
        case .walk:
            return "Take a \(duration)-minute walk to clear your head."
        case .breathing:
            return "Let's do \(duration) minutes of deep breathing."
        case .stretch:
            return "Time for a \(duration)-minute stretch break."
        case .rest:
            return "Rest your eyes for \(duration) minutes."
        }
    }
}
