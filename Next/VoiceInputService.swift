import Foundation
import Speech
import AVFoundation

// MARK: - Voice Input Service
/// Handles speech-to-text for voice goal input (Feature 1)
/// Uses Apple's on-device Speech framework - no API key required
class VoiceInputService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isListening = false
    @Published var transcribedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false
    @Published var audioLevel: Float = 0.0
    
    // MARK: - Private Properties
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private let silenceTimeout: TimeInterval = 2.0
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        speechRecognizer?.delegate = self
        requestAuthorization()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        // Request microphone permission first
        AVAudioApplication.requestRecordPermission { [weak self] micGranted in
            guard micGranted else {
                DispatchQueue.main.async {
                    self?.isAuthorized = false
                    self?.errorMessage = "Microphone access denied. Enable in Settings."
                }
                return
            }
            
            // Then request speech recognition permission
            SFSpeechRecognizer.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self?.isAuthorized = true
                        self?.errorMessage = nil
                    case .denied:
                        self?.isAuthorized = false
                        self?.errorMessage = "Speech recognition denied. Enable in Settings."
                    case .restricted:
                        self?.isAuthorized = false
                        self?.errorMessage = "Speech recognition restricted on this device."
                    case .notDetermined:
                        self?.isAuthorized = false
                        self?.errorMessage = "Speech recognition not determined."
                    @unknown default:
                        self?.isAuthorized = false
                        self?.errorMessage = "Speech recognition unavailable."
                    }
                }
            }
        }
    }
    
    // MARK: - Start Listening
    
    func startListening() {
        // Ensure we're authorized
        guard isAuthorized else {
            errorMessage = "Please enable microphone and speech recognition in Settings"
            requestAuthorization()
            return
        }
        
        // Ensure speech recognizer is available
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available right now"
            return
        }
        
        // Don't start if already listening
        guard !isListening else { return }
        
        // Cancel any existing task
        cancelRecognitionTask()
        
        // Reset state
        DispatchQueue.main.async {
            self.transcribedText = ""
            self.errorMessage = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not configure audio: \(error.localizedDescription)"
            }
            return
        }
        
        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else {
            DispatchQueue.main.async {
                self.errorMessage = "Could not create recognition request"
            }
            return
        }
        
        // Configure request
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        // Add context hints for better recognition
        recognitionRequest.contextualStrings = [
            "write", "essay", "paper", "study", "homework", "project",
            "clean", "organize", "exercise", "workout", "read", "learn",
            "finish", "complete", "start", "begin", "work on"
        ]
        
        // Create audio engine
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            DispatchQueue.main.async {
                self.errorMessage = "Could not create audio engine"
            }
            return
        }
        
        let inputNode = audioEngine.inputNode
        
        // Get the native format of the input node
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Check if format is valid
        guard recordingFormat.sampleRate > 0 else {
            DispatchQueue.main.async {
                self.errorMessage = "Invalid audio format. Please try again."
            }
            return
        }
        
        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            
            // Calculate audio level for visual feedback
            self?.calculateAudioLevel(buffer: buffer)
        }
        
        // Prepare and start engine
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isListening = true
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Could not start recording: \(error.localizedDescription)"
            }
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
                // Check if it's just a timeout or cancellation (not a real error)
                let nsError = error as NSError
                if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 1110 {
                    // No speech detected - not an error, just silence
                    isFinal = true
                } else if nsError.domain == "kAFAssistantErrorDomain" && nsError.code == 216 {
                    // Request was cancelled - not an error
                    isFinal = true
                } else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Recognition error: \(error.localizedDescription)"
                    }
                }
            }
            
            if isFinal {
                self.stopListening()
            }
        }
        
        // Start silence timer
        startSilenceTimer()
    }
    
    // MARK: - Stop Listening
    
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
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Cancel Recognition
    
    private func cancelRecognitionTask() {
        recognitionTask?.cancel()
        recognitionTask = nil
    }
    
    // MARK: - Toggle
    
    func toggleListening() {
        if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
    
    // MARK: - Audio Level Calculation
    
    private func calculateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameLength)
        let level = min(1.0, average * 10) // Scale for visual feedback
        
        DispatchQueue.main.async {
            self.audioLevel = level
        }
    }
    
    // MARK: - Silence Timer
    
    private func startSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceTimeout, repeats: false) { [weak self] _ in
            // Stop listening after silence timeout
            if let self = self, self.isListening {
                self.stopListening()
            }
        }
    }
    
    private func resetSilenceTimer() {
        startSilenceTimer()
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceInputService: SFSpeechRecognizerDelegate {
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        DispatchQueue.main.async {
            if !available {
                self.errorMessage = "Speech recognition became unavailable"
                self.stopListening()
            }
        }
    }
}
