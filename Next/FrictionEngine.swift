import Foundation

// MARK: - Friction Engine
/// Core behavioral system that minimizes psychological effort to start tasks.
/// Transforms large/resisted tasks into the smallest possible actionable step.
/// This is the HEART of v3 functionality.
final class FrictionEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentResistanceLevel: ResistanceLevel = .none
    @Published private(set) var taskScalingLevel: TaskScalingLevel = .L1
    @Published private(set) var isStartOnlyMode = false
    
    // MARK: - Dependencies
    
    private let resistanceModel: ResistanceModel
    private let energyModel: EnergyModel
    
    // MARK: - Initialization
    
    init(resistanceModel: ResistanceModel, energyModel: EnergyModel) {
        self.resistanceModel = resistanceModel
        self.energyModel = energyModel
    }
    
    // MARK: - Core Algorithm
    
    /// Evaluates a task and shrinks it based on resistance and energy levels
    /// - Parameters:
    ///   - task: The task to evaluate
    ///   - energy: Current user energy level
    /// - Returns: A friction-reduced version of the task
    func reduceFriction(for task: SageTask, energy: EnergyLevel) -> SageTask {
        let resistance = resistanceModel.getResistanceLevel(for: task)
        let selectedLevel = selectScalingLevel(resistance: resistance, energy: energy)
        
        currentResistanceLevel = resistance
        taskScalingLevel = selectedLevel
        
        // If resistance is very high, switch to start-only mode
        if resistance == .high && energyModel.isVeryLow {
            isStartOnlyMode = true
            return createStartOnlyTask(from: task)
        }
        
        isStartOnlyMode = false
        
        // Apply scaling
        return scaleTask(task, to: selectedLevel)
    }
    
    /// Selects appropriate task scaling level based on resistance and energy
    private func selectScalingLevel(resistance: ResistanceLevel, energy: EnergyLevel) -> TaskScalingLevel {
        switch (resistance, energy) {
        case (.none, .low):
            return .L2
        case (.none, .medium):
            return .L1
        case (.none, .high):
            return .L0
            
        case (.low, .low):
            return .L3
        case (.low, .medium):
            return .L2
        case (.low, .high):
            return .L1
            
        case (.high, .low):
            return .L4
        case (.high, .medium):
            return .L3
        case (.high, .high):
            return .L2
        }
    }
    
    /// Scales a task to specified level
    private func scaleTask(_ task: SageTask, to level: TaskScalingLevel) -> SageTask {
        var scaledTask = task
        
        switch level {
        case .L0: // Full task - no change
            break
            
        case .L1: // Reduced - about 70% of original
            scaledTask.estimatedMinutes = max(10, Int(Double(task.estimatedMinutes) * 0.7))
            scaledTask.difficultyLevel = .small
            if !task.description.isEmpty {
                scaledTask.description = "Start: \(task.description)"
            }
            
        case .L2: // Small task - about 40-50% of original
            scaledTask.estimatedMinutes = max(8, Int(Double(task.estimatedMinutes) * 0.4))
            scaledTask.difficultyLevel = .small
            if let shrunk = task.shrunkVersions.first {
                scaledTask.title = shrunk
            }
            
        case .L3: // Micro task - about 20-30% of original
            scaledTask.estimatedMinutes = max(5, Int(Double(task.estimatedMinutes) * 0.25))
            scaledTask.difficultyLevel = .micro
            if task.shrunkVersions.count > 1 {
                scaledTask.title = task.shrunkVersions[1]
            } else if !task.shrunkVersions.isEmpty {
                scaledTask.title = task.shrunkVersions[0]
            }
            
        case .L4: // Start-only - 2 minutes
            scaledTask.estimatedMinutes = 2
            scaledTask.difficultyLevel = .micro
            if task.shrunkVersions.count > 2 {
                scaledTask.title = task.shrunkVersions[2]
            } else if !task.shrunkVersions.isEmpty {
                scaledTask.title = task.shrunkVersions.last ?? "Get started"
            }
        }
        
        return scaledTask
    }
    
    /// Creates a start-only task (required when very high resistance)
    private func createStartOnlyTask(from task: SageTask) -> SageTask {
        var startTask = task
        startTask.estimatedMinutes = 2
        startTask.difficultyLevel = .micro
        
        // Use the smallest shrunk version or create minimal task
        if task.shrunkVersions.count > 2 {
            startTask.title = task.shrunkVersions[2]
        } else if !task.shrunkVersions.isEmpty {
            startTask.title = task.shrunkVersions.last ?? "Just open it"
        } else {
            startTask.title = "Open \(task.title.lowercased())"
        }
        
        return startTask
    }
    
    /// Progressive expansion - gradually increase difficulty as momentum builds
    func expandTaskProgression(
        completedSuccessfully: Bool,
        currentLevel: TaskScalingLevel
    ) -> TaskScalingLevel {
        guard completedSuccessfully else {
            // If user failed, don't increase difficulty
            return currentLevel
        }
        
        // Gradually shift from L4 -> L3 -> L2 -> L1 as momentum builds
        switch currentLevel {
        case .L4: return .L3
        case .L3: return .L2
        case .L2: return .L1
        case .L1, .L0: return currentLevel
        }
    }
    
    /// Handles task failure - never increase difficulty
    func handleTaskFailure(currentLevel: TaskScalingLevel) -> TaskScalingLevel {
        // Decrease difficulty
        switch currentLevel {
        case .L0: return .L1
        case .L1: return .L2
        case .L2: return .L3
        case .L3, .L4: return .L4
        }
    }
    
    /// Gets feedback message for user after task interaction
    func getFrictionMessage(
        resistance: ResistanceLevel,
        isStartingTask: Bool
    ) -> String {
        if isStartingTask && resistance == .high {
            return "Just that's enough for now. Nice start."
        }
        
        switch resistance {
        case .none:
            return "Let's keep this momentum going."
        case .low:
            return "Good, you've got this."
        case .high:
            return "No pressure. Just one small step."
        }
    }
}

// MARK: - Task Scaling Levels

enum TaskScalingLevel {
    case L0 // Full task
    case L1 // Reduced task (70%)
    case L2 // Small task (40-50%)
    case L3 // Micro task (20-30%)
    case L4 // Start-only task (2 min)
    
    var description: String {
        switch self {
        case .L0: return "Full task"
        case .L1: return "Reduced task"
        case .L2: return "Small task"
        case .L3: return "Micro task"
        case .L4: return "Start-only"
        }
    }
    
    var maxEstimatedMinutes: Int {
        switch self {
        case .L0: return 60
        case .L1: return 40
        case .L2: return 25
        case .L3: return 15
        case .L4: return 2
        }
    }
}

// MARK: - Resistance Level

enum ResistanceLevel: Int, Comparable {
    case none = 0
    case low = 1
    case high = 2
    
    static func < (lhs: ResistanceLevel, rhs: ResistanceLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var description: String {
        switch self {
        case .none: return "No resistance"
        case .low: return "Some resistance"
        case .high: return "High resistance"
        }
    }
}
