import Foundation
import AVFoundation

// MARK: - Speech Synthesizer
/// Handles text-to-speech conversion for Sage's responses.
/// Provides a calm, natural speaking voice.
final class SpeechSynthesizer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isSpeaking = false
    @Published private(set) var currentUtterance: String?
    
    // MARK: - Private Properties
    
    private let synthesizer = AVSpeechSynthesizer()
    private var completionHandler: (() -> Void)?
    
    /// Voice configuration
    private let voiceIdentifier: String
    private let speechRate: Float
    private let pitchMultiplier: Float
    private let volume: Float
    
    // MARK: - Initialization
    
    override init() {
        // Use a calm, friendly voice
        // Try to get Samantha (default iOS voice) or fall back to first available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            self.voiceIdentifier = voice.identifier
        } else {
            self.voiceIdentifier = AVSpeechSynthesisVoice.speechVoices().first?.identifier ?? ""
        }
        
        // Configure for calm, moderate pacing
        self.speechRate = 0.48  // Slightly slower than default (0.5)
        self.pitchMultiplier = 1.0  // Natural pitch
        self.volume = 0.9
        
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Speech Methods
    
    /// Speaks the given text
    /// - Parameters:
    ///   - text: The text to speak
    ///   - completion: Called when speech finishes
    func speak(_ text: String, completion: (() -> Void)? = nil) {
        // Stop any current speech
        if isSpeaking {
            stop()
        }
        
        // Configure audio session for playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .voicePrompt, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            Logger.shared.error("Audio session error for speech: \(error.localizedDescription)")
        }
        
        // Create utterance
        let utterance = AVSpeechUtterance(string: text)
        
        // Configure voice
        if let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        // Apply settings
        utterance.rate = speechRate
        utterance.pitchMultiplier = pitchMultiplier
        utterance.volume = volume
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.2
        
        // Store state
        completionHandler = completion
        
        DispatchQueue.main.async {
            self.currentUtterance = text
            self.isSpeaking = true
        }
        
        // Speak
        synthesizer.speak(utterance)
        Logger.shared.logSpeechSynthesis(event: "Started speaking: \(text.prefix(50))...")
    }
    
    /// Stops current speech immediately
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        
        completionHandler = nil
        Logger.shared.logSpeechSynthesis(event: "Stopped speaking")
    }
    
    /// Pauses current speech
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        Logger.shared.logSpeechSynthesis(event: "Paused speaking")
    }
    
    /// Continues paused speech
    func continueSpeaking() {
        synthesizer.continueSpeaking()
        Logger.shared.logSpeechSynthesis(event: "Continued speaking")
    }
    
    // MARK: - Voice Selection
    
    /// Gets available voices for a language
    static func availableVoices(for language: String = "en-US") -> [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.language == language }
    }
    
    /// Gets premium (enhanced) voices
    static var premiumVoices: [AVSpeechSynthesisVoice] {
        return AVSpeechSynthesisVoice.speechVoices().filter { $0.quality == .enhanced }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        completionHandler?()
        completionHandler = nil
        Logger.shared.logSpeechSynthesis(event: "Finished speaking")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.currentUtterance = nil
        }
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        completionHandler = nil
        Logger.shared.logSpeechSynthesis(event: "Cancelled speaking")
    }
}
