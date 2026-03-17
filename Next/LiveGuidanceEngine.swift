import Foundation

// MARK: - Live Guidance Engine
/// Provides real-time guidance while user is working on a task.
/// Sends micro-prompts at strategic intervals to maintain momentum.
/// Converts from planning→execution to active task support.
final class LiveGuidanceEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentGuidance: String?
    @Published private(set) var nextGuidanceTime: Date?
    @Published private(set) var timeElapsed: TimeInterval = 0
    
    // MARK: - Dependencies
    
    private let energyModel: EnergyModel
    private let resistanceModel: ResistanceModel
    
    // MARK: - Private Properties
    
    private var guidanceTimer: Timer?
    private var taskStartTime: Date?
    private var guidanceHistory: [GuidanceEvent] = []
    
    // MARK: - Initialization
    
    init(energyModel: EnergyModel, resistanceModel: ResistanceModel) {
        self.energyModel = energyModel
        self.resistanceModel = resistanceModel
    }
    
    // MARK: - Core Methods
    
    /// Starts live guidance for a task
    func startGuidance(
        for task: SageTask,
        energy: EnergyLevel,
        resistance: ResistanceLevel
    ) {
        taskStartTime = Date()
        timeElapsed = 0
        guidanceTimer?.invalidate()
        
        // Initial guidance
        let initialGuidance = generateInitialGuidance(
            task: task,
            energy: energy,
            resistance: resistance
        )
        
        currentGuidance = initialGuidance
        recordGuidance(initialGuidance, at: 0)
        
        // Setup periodic guidance
        startPeriodicGuidance(for: task, energy: energy, resistance: resistance)
    }
    
    /// Stops live guidance
    func stopGuidance() {
        guidanceTimer?.invalidate()
        currentGuidance = nil
        taskStartTime = nil
        timeElapsed = 0
    }
    
    /// Updates time elapsed (called from external timer)
    func updateTimeElapsed(_ elapsed: TimeInterval) {
        timeElapsed = elapsed
    }
    
    // MARK: - Private Methods
    
    private func generateInitialGuidance(
        task: SageTask,
        energy: EnergyLevel,
        resistance: ResistanceLevel
    ) -> String {
        if resistance == .high && energy == .low {
            return "Just get started. That's all you need to do right now."
        }
        
        if task.estimatedMinutes <= 5 {
            return "Quick one - let's go."
        }
        
        return "You've got this. Let's begin."
    }
    
    private func startPeriodicGuidance(
        for task: SageTask,
        energy: EnergyLevel,
        resistance: ResistanceLevel
    ) {
        // Send guidance at strategic intervals
        guidanceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.sendTimeBasedGuidance(
                task: task,
                energy: energy,
                resistance: resistance
            )
        }
    }
    
    private func sendTimeBasedGuidance(
        task: SageTask,
        energy: EnergyLevel,
        resistance: ResistanceLevel
    ) {
        guard let startTime = taskStartTime else { return }
        
        let elapsed = Int(Date().timeIntervalSince(startTime))
        
        // Guidance varies by task duration and elapsed time
        let guidance: String?
        
        if task.estimatedMinutes <= 5 {
            // For very short tasks, minimal guidance
            if elapsed == 2 {
                guidance = "Keep going."
            } else {
                guidance = nil
            }
        } else if task.estimatedMinutes <= 15 {
            // For small tasks, check in at half-time
            let halfway = task.estimatedMinutes * 30
            if elapsed == halfway {
                guidance = "Halfway there - nice work."
            } else if elapsed == task.estimatedMinutes * 60 - 30 {
                guidance = "Almost done. Finish strong."
            } else {
                guidance = nil
            }
        } else {
            // For longer tasks, regular check-ins
            if elapsed % 300 == 0 { // Every 5 minutes
                guidance = generateProgressGuidance(
                    elapsed: elapsed,
                    taskDuration: task.estimatedMinutes,
                    energy: energy
                )
            } else {
                guidance = nil
            }
        }
        
        if let guidance = guidance {
            currentGuidance = guidance
            recordGuidance(guidance, at: Double(elapsed))
        }
    }
    
    private func generateProgressGuidance(
        elapsed: Int,
        taskDuration: Int,
        energy: EnergyLevel
    ) -> String {
        let percentComplete = Float(elapsed) / Float(taskDuration * 60)
        
        if percentComplete < 0.3 {
            return "Getting warmed up - keep it going."
        } else if percentComplete < 0.6 {
            return "Good momentum. Stay with it."
        } else if percentComplete < 0.85 {
            return "You're in the groove now. Push to the end."
        } else {
            return "Final stretch - almost there."
        }
    }
    
    private func recordGuidance(_ guidance: String, at timeElapsed: Double) {
        let event = GuidanceEvent(
            message: guidance,
            timeElapsedSeconds: timeElapsed,
            timestamp: Date()
        )
        
        guidanceHistory.append(event)
        
        // Keep recent history only
        if guidanceHistory.count > 20 {
            guidanceHistory.removeFirst()
        }
    }
}

// MARK: - Guidance Event

private struct GuidanceEvent {
    let message: String
    let timeElapsedSeconds: Double
    let timestamp: Date
}

// MARK: - Guidance Strategy

enum GuidanceStrategy {
    case minimal // Very short tasks - minimal guidance
    case moderate // Standard tasks - regular check-ins
    case intensive // Long/difficult tasks - frequent support
    
    var checkInInterval: TimeInterval {
        switch self {
        case .minimal: return 120 // 2 minutes
        case .moderate: return 300 // 5 minutes
        case .intensive: return 180 // 3 minutes
        }
    }
}
