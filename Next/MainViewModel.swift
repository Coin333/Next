import Foundation
import Combine
import SwiftUI

// MARK: - Main View Model
/// Primary view model for the Next app.
/// Coordinates between all services and provides state to views.
@MainActor
final class MainViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    // Voice State
    @Published private(set) var voiceState: VoiceEngine.VoiceState = .idle
    @Published private(set) var transcribedText = ""
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var isVoiceAuthorized = false
    
    // Conversation State
    @Published private(set) var phase: ConversationPhase = .idle
    @Published private(set) var lastSageMessage: String?
    @Published private(set) var isProcessing = false
    
    // Task State
    @Published private(set) var currentGoal: Goal?
    @Published private(set) var currentTask: SageTask?
    @Published private(set) var hasActiveTask = false
    
    // Settings
    @Published var energyLevel: EnergyLevel = .medium
    @Published private(set) var hasAPIKey = false
    @Published var showSettings = false
    @Published var apiKeyInput = ""
    
    // Network
    @Published private(set) var isConnected = true
    
    // Errors
    @Published var error: AppError?
    @Published var showError = false
    
    // MARK: - Components
    
    private let voiceEngine = VoiceEngine()
    private let taskEngine = TaskEngine()
    private var conversationManager: ConversationManager!
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        conversationManager = ConversationManager(voiceEngine: voiceEngine, taskEngine: taskEngine)
        
        setupBindings()
        checkAPIKey()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Voice Engine Bindings
        voiceEngine.$state
            .receive(on: DispatchQueue.main)
            .assign(to: &$voiceState)
        
        voiceEngine.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcribedText)
        
        voiceEngine.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
        
        voiceEngine.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$isVoiceAuthorized)
        
        // Conversation Manager Bindings
        conversationManager.$conversationState
            .map { $0.phase }
            .receive(on: DispatchQueue.main)
            .assign(to: &$phase)
        
        conversationManager.$lastSageMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$lastSageMessage)
        
        conversationManager.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: &$isProcessing)
        
        conversationManager.$error
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.error = .conversation(error.localizedDescription)
                self?.showError = true
            }
            .store(in: &cancellables)
        
        // Task Engine Bindings
        taskEngine.$currentGoal
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentGoal)
        
        taskEngine.$currentTask
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentTask)
        
        taskEngine.$currentTask
            .map { $0 != nil }
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasActiveTask)
        
        // Network Monitor
        NetworkMonitor.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .assign(to: &$isConnected)
        
        // Energy Level Changes
        $energyLevel
            .sink { [weak self] level in
                self?.conversationManager.setEnergyLevel(level)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Voice Actions
    
    /// Toggles the microphone for voice input
    func toggleMicrophone() {
        guard hasAPIKey else {
            showSettings = true
            return
        }
        
        guard isConnected else {
            error = .noConnection
            showError = true
            return
        }
        
        conversationManager.toggleListening()
    }
    
    /// Starts listening for voice input
    func startListening() {
        conversationManager.startListening()
    }
    
    /// Stops listening
    func stopListening() {
        conversationManager.stopListening()
    }
    
    /// Interrupts Sage to speak
    func interruptSage() {
        conversationManager.interruptSage()
    }
    
    // MARK: - Task Actions
    
    /// Marks current task as complete (manual button)
    func completeTask() {
        if let result = taskEngine.completeCurrentTask() {
            let message: String
            if let next = result.next {
                message = "Great job! Next up: \(next.title)"
            } else {
                message = "Amazing! You've completed all tasks for this goal! 🎉"
            }
            conversationManager.sageRespond(message)
        }
    }
    
    /// Skips current task (manual button)
    func skipTask() {
        if let next = taskEngine.skipCurrentTask() {
            conversationManager.sageRespond("No worries. Let's try: \(next.title)")
        } else {
            conversationManager.sageRespond("That's all the tasks for now.")
        }
    }
    
    // MARK: - Settings Actions
    
    /// Saves the API key
    func saveAPIKey() {
        let key = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !key.isEmpty else {
            error = .invalidAPIKey
            showError = true
            return
        }
        
        do {
            try KeychainManager.shared.saveAPIKey(key)
            hasAPIKey = true
            apiKeyInput = ""
            showSettings = false
            
            // Greet the user
            conversationManager.sageRespond("Hello! I'm Sage. Tell me what you'd like to accomplish today, and I'll help break it down into manageable steps.")
        } catch {
            self.error = .keychainError
            showError = true
        }
    }
    
    /// Deletes the API key
    func deleteAPIKey() {
        do {
            try KeychainManager.shared.deleteAPIKey()
            hasAPIKey = false
        } catch {
            self.error = .keychainError
            showError = true
        }
    }
    
    /// Checks if API key exists
    func checkAPIKey() {
        hasAPIKey = KeychainManager.shared.hasAPIKey
        
        if !hasAPIKey {
            // Show settings on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showSettings = true
            }
        }
    }
    
    // MARK: - Greetings
    
    /// Initial greeting when app launches
    func greetUser() {
        guard hasAPIKey else { return }
        
        let greeting: String
        
        if let goal = currentGoal, let task = currentTask {
            greeting = "Welcome back! You were working on: \(task.title)"
        } else {
            greeting = "Hi there! I'm Sage. What would you like to accomplish today?"
        }
        
        conversationManager.sageRespond(greeting)
    }
    
    // MARK: - Error Types
    
    enum AppError: LocalizedError, Identifiable {
        var id: String { localizedDescription }
        
        case noConnection
        case invalidAPIKey
        case keychainError
        case conversation(String)
        case voice(String)
        
        var errorDescription: String? {
            switch self {
            case .noConnection:
                return "No internet connection"
            case .invalidAPIKey:
                return "Please enter a valid API key"
            case .keychainError:
                return "Could not save API key"
            case .conversation(let message):
                return message
            case .voice(let message):
                return message
            }
        }
    }
}
