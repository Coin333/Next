import Foundation
import Speech
import AVFoundation

// MARK: - Speech Recognizer
/// Handles speech-to-text conversion using Apple's Speech framework.
/// Supports real-time transcription with silence detection.
final class SpeechRecognizer: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isListening = false
    @Published private(set) var transcribedText = ""
    @Published private(set) var isAuthorized = false
    @Published private(set) var audioLevel: Float = 0.0
    @Published private(set) var error: RecognitionError?
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    
    /// Silence timeout before stopping (seconds)
    private let silenceTimeout: TimeInterval = 2.0
    
    /// Callback when transcription is finalized
    var onTranscriptionComplete: ((String) -> Void)?
    
    /// Callback when listening starts
    var onListeningStarted: (() -> Void)?
    
    /// Callback when listening stops
    var onListeningStopped: (() -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    /// Checks and requests authorization for speech recognition
    func checkAuthorization() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] micGranted in
            guard micGranted else {
                DispatchQueue.main.async {
                    self?.isAuthorized = false
                    self?.error = .microphoneNotAuthorized
                }
                Logger.shared.error("Microphone permission denied")
                return
            }
            
            // Request speech recognition permission
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.isAuthorized = true
                        self?.error = nil
                        Logger.shared.info("Speech recognition authorized")
                    case .denied:
                        self?.isAuthorized = false
                        self?.error = .speechRecognitionNotAuthorized
                    case .restricted:
                        self?.isAuthorized = false
                        self?.error = .speechRecognitionRestricted
                    case .notDetermined:
                        self?.isAuthorized = false
                    @unknown default:
                        self?.isAuthorized = false
                    }
                }
            }
        }
    }
    
    // MARK: - Start Listening
    
    /// Starts listening for speech input
    func startListening() {
        // Validate state
        guard isAuthorized else {
            error = .notAuthorized
            checkAuthorization()
            return
        }
        
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            error = .recognizerUnavailable
            return
        }
        
        guard !isListening else { return }
        
        // Cancel any existing task
        cancelCurrentTask()
        
        // Reset state
        DispatchQueue.main.async {
            self.transcribedText = ""
            self.error = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async {
                self.error = .audioSessionError
            }
            Logger.shared.info("Audio session error: \(error.localizedDescription)")
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            error = .requestCreationFailed
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Add context hints for better recognition
        recognitionRequest.contextualStrings = [
            "goal", "task", "done", "complete", "finished", "next",
            "skip", "smaller", "break", "help", "stop", "start"
        ]
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            error = .audioEngineError
            return
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        guard recordingFormat.sampleRate > 0 else {
            error = .invalidAudioFormat
            return
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.calculateAudioLevel(buffer: buffer)
        }
        
        // Start audio engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
            onListeningStarted?()
            Logger.shared.info("Started listening")
        } catch {
            DispatchQueue.main.async {
                self.error = .audioEngineError
            }
            Logger.shared.error("Audio engine start error: \(error.localizedDescription)")
            return
        }
        
        // Start recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                let transcription = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.transcribedText = transcription
                }
                isFinal = result.isFinal
                
                // Reset silence timer on new speech
                self.resetSilenceTimer()
            }
            
            if let error = error {
                let nsError = error as NSError
                // Ignore cancellation and silence errors
                if nsError.domain != "kAFAssistantErrorDomain" || 
                   (nsError.code != 1110 && nsError.code != 216) {
                    Logger.shared.error("Recognition error: \(error.localizedDescription)")
                }
                isFinal = true
            }
            
            if isFinal {
                self.finalizeTranscription()
            }
        }
        
        // Start silence timer
        startSilenceTimer()
    }
    
    // MARK: - Stop Listening
    
    /// Stops listening and finalizes transcription
    func stopListening() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
            self.audioLevel = 0.0
        }
        
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        
        onListeningStopped?()
        Logger.shared.info("Stopped listening")
    }
    
    // MARK: - Cancel
    
    /// Cancels current recognition without finalizing
    func cancel() {
        cancelCurrentTask()
        stopListening()
        DispatchQueue.main.async {
            self.transcribedText = ""
        }
    }
    
    // MARK: - Private Methods
    
    private func cancelCurrentTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    private func finalizeTranscription() {
        let finalText = transcribedText.trimmingCharacters(in: .whitespacesAndNewlines)
        stopListening()
        
        if !finalText.isEmpty {
            onTranscriptionComplete?(finalText)
            Logger.shared.info("Transcription complete: \(finalText.prefix(50))...")
        }
    }
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        let level = min(1.0, average * 10)
        
        DispatchQueue.main.async {
            self.audioLevel = level
        }
    }
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            self?.finalizeTranscription()
        }
    }
    
    private func resetSilenceTimer() {
        startSilenceTimer()
    }
    
    // MARK: - Error Types
    
    enum RecognitionError: LocalizedError {
        case notAuthorized
        case microphoneNotAuthorized
        case speechRecognitionNotAuthorized
        case speechRecognitionRestricted
        case recognizerUnavailable
        case requestCreationFailed
        case audioSessionError
        case audioEngineError
        case invalidAudioFormat
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Speech recognition not authorized"
            case .microphoneNotAuthorized:
                return "Microphone access not authorized"
            case .speechRecognitionNotAuthorized:
                return "Speech recognition access denied"
            case .speechRecognitionRestricted:
                return "Speech recognition restricted on this device"
            case .recognizerUnavailable:
                return "Speech recognizer not available"
            case .requestCreationFailed:
                return "Could not create recognition request"
            case .audioSessionError:
                return "Could not configure audio session"
            case .audioEngineError:
                return "Could not start audio engine"
            case .invalidAudioFormat:
                return "Invalid audio format"
            }
        }
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognizer: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.error = .recognizerUnavailable
                self.stopListening()
            }
        }
        Logger.shared.info("Availability changed: \(available)")
    }
}
