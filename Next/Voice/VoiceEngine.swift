import Foundation
import Combine

// MARK: - Voice Engine
/// Orchestrates speech recognition and synthesis for voice interactions.
/// Provides a unified interface for voice input/output.
final class VoiceEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var state: VoiceState = .idle
    @Published private(set) var transcribedText = ""
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var isAuthorized = false
    @Published private(set) var error: VoiceError?
    
    // MARK: - Components
    
    private let recognizer = SpeechRecognizer()
    private let synthesizer = SpeechSynthesizer()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Callback when user speech is finalized
    var onUserSpeechComplete: ((String) -> Void)?
    
    /// Callback when Sage finishes speaking
    var onSageSpeechComplete: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind recognizer authorization
        recognizer.$isAuthorized
            .receive(on: DispatchQueue.main)
            .assign(to: &$isAuthorized)
        
        // Bind transcribed text
        recognizer.$transcribedText
            .receive(on: DispatchQueue.main)
            .assign(to: &$transcribedText)
        
        // Bind audio level
        recognizer.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
        
        // Handle transcription completion
        recognizer.onTranscriptionComplete = { [weak self] text in
            self?.handleTranscriptionComplete(text)
        }
        
        // Handle listening state changes
        recognizer.onListeningStarted = { [weak self] in
            DispatchQueue.main.async {
                self?.state = .listening
            }
        }
        
        recognizer.onListeningStopped = { [weak self] in
            DispatchQueue.main.async {
                if self?.state == .listening {
                    self?.state = .idle
                }
            }
        }
        
        // Bind synthesizer state
        synthesizer.$isSpeaking
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSpeaking in
                if isSpeaking {
                    self?.state = .speaking
                } else if self?.state == .speaking {
                    self?.state = .idle
                    self?.onSageSpeechComplete?()
                }
            }
            .store(in: &cancellables)
        
        // Bind recognizer errors
        recognizer.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] recognizerError in
                self?.error = .recognitionError(recognizerError.localizedDescription)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Voice Input
    
    /// Starts listening for user voice input
    func startListening() {
        // Don't listen while Sage is speaking
        if state == .speaking {
            stopSpeaking()
        }
        
        error = nil
        recognizer.startListening()
    }
    
    /// Stops listening for voice input
    func stopListening() {
        recognizer.stopListening()
    }
    
    /// Cancels listening without processing
    func cancelListening() {
        recognizer.cancel()
        transcribedText = ""
        state = .idle
    }
    
    /// Toggles listening state
    func toggleListening() {
        if state == .listening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    // MARK: - Voice Output
    
    /// Makes Sage speak the given text
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Stop listening if active
        if state == .listening {
            cancelListening()
        }
        
        state = .speaking
        synthesizer.speak(text) { [weak self] in
            self?.state = .idle
            completion?()
        }
    }
    
    /// Stops Sage from speaking
    func stopSpeaking() {
        synthesizer.stop()
        state = .idle
    }
    
    /// Interrupts Sage speech (user wants to speak)
    func interruptSpeech() {
        if state == .speaking {
            stopSpeaking()
            // Brief delay before starting to listen
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.startListening()
            }
        }
    }
    
    // MARK: - Authorization
    
    /// Requests necessary permissions
    func requestAuthorization() {
        recognizer.checkAuthorization()
    }
    
    // MARK: - Private Methods
    
    private func handleTranscriptionComplete(_ text: String) {
        guard !text.isEmpty else { return }
        
        state = .processing
        onUserSpeechComplete?(text)
    }
    
    // MARK: - State Types
    
    enum VoiceState: Equatable {
        case idle
        case listening
        case processing
        case speaking
        
        var description: String {
            switch self {
            case .idle: return "Ready"
            case .listening: return "Listening..."
            case .processing: return "Processing..."
            case .speaking: return "Speaking..."
            }
        }
        
        var isActive: Bool {
            self != .idle
        }
    }
    
    // MARK: - Error Types
    
    enum VoiceError: LocalizedError {
        case notAuthorized
        case recognitionError(String)
        case synthesisError(String)
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Voice features require microphone access"
            case .recognitionError(let message):
                return message
            case .synthesisError(let message):
                return message
            }
        }
    }
}
