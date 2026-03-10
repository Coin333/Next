import Foundation
import Combine

// MARK: - Conversation Manager
/// Orchestrates the conversation flow between user and Sage.
/// Manages state transitions and coordinates between voice, AI, and tasks.
final class ConversationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var conversationState = ConversationState()
    @Published private(set) var isProcessing = false
    @Published private(set) var lastSageMessage: String?
    @Published private(set) var error: ConversationError?
    
    // MARK: - Components
    
    private let voiceEngine: VoiceEngine
    private let taskEngine: TaskEngine
    private let apiManager = SageAPIManager.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(voiceEngine: VoiceEngine, taskEngine: TaskEngine) {
        self.voiceEngine = voiceEngine
        self.taskEngine = taskEngine
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Handle user speech completion
        voiceEngine.onUserSpeechComplete = { [weak self] text in
            self?.handleUserInput(text)
        }
        
        // Handle Sage speech completion
        voiceEngine.onSageSpeechComplete = { [weak self] in
            self?.onSageSpeechComplete()
        }
        
        // Bind voice state to conversation state
        voiceEngine.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .listening:
                    self?.conversationState.phase = .listening
                    self?.conversationState.isUserSpeaking = true
                case .speaking:
                    self?.conversationState.phase = .responding
                    self?.conversationState.isSageSpeaking = true
                case .processing:
                    self?.conversationState.phase = .processing
                    self?.conversationState.isUserSpeaking = false
                case .idle:
                    self?.conversationState.isUserSpeaking = false
                    self?.conversationState.isSageSpeaking = false
                    if self?.taskEngine.hasActiveTask == true {
                        self?.conversationState.phase = .taskActive
                    } else {
                        self?.conversationState.phase = .idle
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - User Input Handling
    
    /// Processes user input and determines appropriate response
    func handleUserInput(_ text: String) {
        // Add to conversation history
        conversationState.addUserMessage(text)
        
        // Determine intent and respond
        Task {
            await processUserInput(text)
        }
    }
    
    private func processUserInput(_ text: String) async {
        DispatchQueue.main.async {
            self.isProcessing = true
            self.conversationState.phase = .processing
        }
        
        do {
            // Check if this looks like a new goal
            if isNewGoalIntent(text) && taskEngine.currentGoal == nil {
                try await handleNewGoal(text)
            }
            // Check for task completion intent
            else if isTaskCompleteIntent(text) && taskEngine.currentTask != nil {
                try await handleTaskCompletion()
            }
            // Check for skip intent
            else if isSkipIntent(text) && taskEngine.currentTask != nil {
                try await handleSkipTask()
            }
            // Check for resistance/overwhelm
            else if isResistanceIntent(text) && taskEngine.currentTask != nil {
                try await handleResistance(text)
            }
            // General conversation
            else {
                try await handleGeneralConversation(text)
            }
        } catch {
            handleError(error)
        }
        
        DispatchQueue.main.async {
            self.isProcessing = false
        }
    }
    
    // MARK: - Goal Handling
    
    /// Handles a new goal from user
    private func handleNewGoal(_ goalText: String) async throws {
        let response = try await apiManager.decomposeGoal(
            goalText,
            energyLevel: conversationState.energyLevel,
            context: conversationState.getRecentContext()
        )
        
        // Create goal with tasks
        let goal = taskEngine.createGoal(from: response, title: goalText)
        
        DispatchQueue.main.async {
            self.conversationState.activeGoalId = goal.id
        }
        
        // Build response message
        let message = "\(response.introMessage) \(response.firstTaskMessage)"
        
        sageRespond(message)
    }
    
    // MARK: - Task Completion
    
    private func handleTaskCompletion() async throws {
        guard let result = taskEngine.completeCurrentTask(),
              let goal = taskEngine.currentGoal else {
            return
        }
        
        let response = try await apiManager.getTaskCompletionResponse(
            completedTask: result.completed,
            nextTask: result.next,
            goal: goal
        )
        
        var message = response.completionMessage
        
        if let transition = response.transitionMessage {
            message += " \(transition)"
        } else if let celebration = response.celebrationMessage {
            message += " \(celebration)"
            DispatchQueue.main.async {
                self.conversationState.phase = .celebrating
            }
        }
        
        sageRespond(message)
    }
    
    // MARK: - Skip Task
    
    private func handleSkipTask() async throws {
        guard let nextTask = taskEngine.skipCurrentTask() else {
            sageRespond("No worries, let's move on. That's all the tasks for now!")
            return
        }
        
        sageRespond("No problem, let's skip that one. Your next task is: \(nextTask.title)")
    }
    
    // MARK: - Resistance Handling
    
    private func handleResistance(_ userMessage: String) async throws {
        guard let currentTask = taskEngine.currentTask else { return }
        
        let response = try await apiManager.handleResistance(
            currentTask: currentTask,
            userMessage: userMessage
        )
        
        // Replace with smaller task
        taskEngine.replaceWithSmallerTask(response.smallerTask)
        
        let message = "\(response.empathyMessage) How about this instead: \(response.smallerTask.title). \(response.encouragement)"
        
        sageRespond(message)
    }
    
    // MARK: - General Conversation
    
    private func handleGeneralConversation(_ text: String) async throws {
        let response = try await apiManager.getConversationResponse(
            userMessage: text,
            context: conversationState.getRecentContext(),
            currentGoal: taskEngine.currentGoal
        )
        
        // Handle any action from the response
        switch response.action {
        case .newGoal:
            // User wants to set a new goal
            try await handleNewGoal(text)
            return
        case .completeTask:
            try await handleTaskCompletion()
            return
        case .skipTask:
            try await handleSkipTask()
            return
        case .makeSmaller:
            try await handleResistance(text)
            return
        case .none:
            break
        }
        
        sageRespond(response.message)
    }
    
    // MARK: - Sage Response
    
    /// Makes Sage respond with the given message
    func sageRespond(_ message: String) {
        DispatchQueue.main.async {
            self.lastSageMessage = message
            self.conversationState.addSageMessage(message)
        }
        
        voiceEngine.speak(message)
    }
    
    private func onSageSpeechComplete() {
        // Transition to appropriate state after Sage finishes speaking
        DispatchQueue.main.async {
            if self.taskEngine.hasActiveTask {
                self.conversationState.phase = .taskActive
            } else {
                self.conversationState.phase = .idle
            }
        }
    }
    
    // MARK: - Voice Control
    
    /// Starts listening for user input
    func startListening() {
        error = nil
        voiceEngine.startListening()
    }
    
    /// Stops listening
    func stopListening() {
        voiceEngine.stopListening()
    }
    
    /// Toggles listening state
    func toggleListening() {
        voiceEngine.toggleListening()
    }
    
    /// Interrupts Sage to speak
    func interruptSage() {
        voiceEngine.interruptSpeech()
    }
    
    // MARK: - Energy Level
    
    /// Sets the user's energy level
    func setEnergyLevel(_ level: EnergyLevel) {
        conversationState.energyLevel = level
    }
    
    // MARK: - Intent Detection
    
    private func isNewGoalIntent(_ text: String) -> Bool {
        let goalKeywords = ["want to", "need to", "help me", "i want", "i need", "let's", "can you help", "goal", "accomplish"]
        let lowerText = text.lowercased()
        return goalKeywords.contains { lowerText.contains($0) }
    }
    
    private func isTaskCompleteIntent(_ text: String) -> Bool {
        let completeKeywords = ["done", "finished", "completed", "did it", "i did", "complete", "next"]
        let lowerText = text.lowercased()
        return completeKeywords.contains { lowerText.contains($0) }
    }
    
    private func isSkipIntent(_ text: String) -> Bool {
        let skipKeywords = ["skip", "pass", "move on", "next one", "different task"]
        let lowerText = text.lowercased()
        return skipKeywords.contains { lowerText.contains($0) }
    }
    
    private func isResistanceIntent(_ text: String) -> Bool {
        let resistanceKeywords = ["too hard", "can't", "overwhelming", "smaller", "easier", "too much", "difficult", "struggle"]
        let lowerText = text.lowercased()
        return resistanceKeywords.contains { lowerText.contains($0) }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        Logger.shared.error(error)
        
        let userMessage: String
        
        if let apiError = error as? SageAPIManager.APIError {
            userMessage = apiError.userMessage
        } else {
            userMessage = "Something went wrong. Let's try that again."
        }
        
        DispatchQueue.main.async {
            self.error = .processingFailed(userMessage)
        }
        
        sageRespond(userMessage)
    }
    
    // MARK: - Reset
    
    /// Resets the conversation state
    func resetConversation() {
        conversationState.reset()
        error = nil
        lastSageMessage = nil
    }
    
    // MARK: - Error Types
    
    enum ConversationError: LocalizedError {
        case processingFailed(String)
        case voiceError(String)
        
        var errorDescription: String? {
            switch self {
            case .processingFailed(let message):
                return message
            case .voiceError(let message):
                return message
            }
        }
    }
}
