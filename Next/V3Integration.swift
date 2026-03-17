import Foundation

// MARK: - V3 Enhancement Extension for ConversationManager
/// Adds v3 functionality: Friction Engine, Live Guidance, Passive Intervention, etc.
extension ConversationManager {
    
    // MARK: - V3 System Initialization
    
    /// Initializes v3 systems within the conversation manager
    func initializeV3Systems(resistanceModel: ResistanceModel, energyModel: EnergyModel, contextEngine: ContextEngine) {
        V3SystemCoordinator.shared.setup(
            conversationManager: self,
            resistanceModel: resistanceModel,
            energyModel: energyModel,
            contextEngine: contextEngine
        )
    }
    
    /// Starts live guidance for current task
    func startLiveGuidance() {
        guard let currentTask = taskEngine.currentTask else { return }
        
        let guidance = V3SystemCoordinator.shared.liveGuidanceEngine
        guidance?.startGuidance(
            for: currentTask,
            energy: conversationState.energyLevel,
            resistance: V3SystemCoordinator.shared.resistanceModel?.getResistanceLevel(for: currentTask) ?? .none
        )
    }
    
    /// Stops live guidance
    func stopLiveGuidance() {
        V3SystemCoordinator.shared.liveGuidanceEngine?.stopGuidance()
    }
    
    /// Applies friction reduction to current task
    func reduceFrictionForCurrentTask() -> SageTask? {
        guard let currentTask = taskEngine.currentTask,
              let frictionEngine = V3SystemCoordinator.shared.frictionEngine,
              let energyModel = V3SystemCoordinator.shared.energyModel else {
            return nil
        }
        
        let reducedTask = frictionEngine.reduceFriction(
            for: currentTask,
            energy: energyModel.currentEnergyLevel
        )
        
        // Update task in engine
        taskEngine.replaceWithSmallerTask(reducedTask)
        
        return reducedTask
    }
    
    /// Checks for passive interventions needed
    func evaluatePassiveIntervention(inactiveSeconds: TimeInterval) {
        guard let interventionEngine = V3SystemCoordinator.shared.passiveInterventionEngine else { return }
        
        let intervention = interventionEngine.evaluateInterventionNeed(
            inactiveSeconds: inactiveSeconds,
            hasActiveTask: taskEngine.hasActiveTask
        )
        
        if let intervention = intervention {
            respondToPassiveIntervention(intervention)
        }
    }
    
    /// Handles passive intervention responses
    private func respondToPassiveIntervention(_ intervention: PassiveIntervention) {
        switch intervention {
        case .nudge(let type, let message):
            sageRespond(message)
        case .breakSuggestion:
            let breakSuggestion = V3SystemCoordinator.shared.passiveInterventionEngine?
                .suggestBreak(taskDurationMinutes: taskEngine.currentTask?.estimatedMinutes ?? 10, energy: conversationState.energyLevel)
            
            if let suggestion = breakSuggestion {
                sageRespond(suggestion.message)
            }
        case .taskReduction:
            _ = reduceFrictionForCurrentTask()
        case .focusMode:
            sageRespond("Let's focus on this together. I'll help keep you on track.")
        }
    }
    
    /// Records user action for resistance model
    func recordUserAction(_ action: ResistanceModelAction) {
        guard let resistanceModel = V3SystemCoordinator.shared.resistanceModel else { return }
        guard let currentTask = taskEngine.currentTask else { return }
        
        switch action {
        case .taskStarted:
            resistanceModel.recordStart(for: currentTask.id)
        case .taskCompleted:
            resistanceModel.recordCompletion(for: currentTask.id)
        case .taskSkipped:
            resistanceModel.recordSkip(for: currentTask.id, delaySeconds: 0)
        case .taskDeclined(let reason):
            resistanceModel.recordDecline(for: currentTask.id, reason: reason)
        }
    }
    
    /// Gets next task with friction reduction applied
    func getNextTaskWithFrictionReduction() -> SageTask? {
        guard let nextTask = taskEngine.getNextPendingTask() else { return nil }
        
        // Apply friction reduction
        return reduceFrictionForCurrentTask() ?? nextTask
    }
}

// MARK: - Resistance Model Action

enum ResistanceModelAction {
    case taskStarted
    case taskCompleted
    case taskSkipped
    case taskDeclined(reason: String)
}

// MARK: - V3 System Coordinator
/// Central coordinator for all v3 systems
class V3SystemCoordinator {
    
    static let shared = V3SystemCoordinator()
    
    private(set) var frictionEngine: FrictionEngine?
    private(set) var passiveInterventionEngine: PassiveInterventionEngine?
    private(set) var liveGuidanceEngine: LiveGuidanceEngine?
    private(set) var resistanceModel: ResistanceModel?
    private(set) var energyModel: EnergyModel?
    private(set) var contextEngine: ContextEngine?
    
    private var conversationManager: ConversationManager?
    
    func setup(
        conversationManager: ConversationManager,
        resistanceModel: ResistanceModel,
        energyModel: EnergyModel,
        contextEngine: ContextEngine
    ) {
        self.conversationManager = conversationManager
        self.resistanceModel = resistanceModel
        self.energyModel = energyModel
        self.contextEngine = contextEngine
        
        // Initialize engines
        self.frictionEngine = FrictionEngine(
            resistanceModel: resistanceModel,
            energyModel: energyModel
        )
        
        self.passiveInterventionEngine = PassiveInterventionEngine(
            energyModel: energyModel,
            resistanceModel: resistanceModel
        )
        
        self.liveGuidanceEngine = LiveGuidanceEngine(
            energyModel: energyModel,
            resistanceModel: resistanceModel
        )
    }
    
    /// Gets status of all v3 systems
    var systemsStatus: [String: String] {
        [
            "friction": frictionEngine != nil ? "active" : "inactive",
            "passive_intervention": passiveInterventionEngine != nil ? "active" : "inactive",
            "live_guidance": liveGuidanceEngine != nil ? "active" : "inactive",
            "resistance_tracking": resistanceModel != nil ? "active" : "inactive",
            "energy_tracking": energyModel != nil ? "active" : "inactive",
            "context_awareness": contextEngine != nil ? "active" : "inactive"
        ]
    }
}
