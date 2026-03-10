import Foundation
import os.log

// MARK: - Logger
/// Structured logging system for debugging and monitoring.
/// Disabled in production builds for performance and security.
final class Logger {
    
    // MARK: - Singleton
    
    static let shared = Logger()
    
    private init() {}
    
    // MARK: - Log Levels
    
    enum LogLevel: String {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
    }
    
    // MARK: - Configuration
    
    #if DEBUG
    private let isEnabled = true
    #else
    private let isEnabled = false
    #endif
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    // MARK: - OS Log
    
    private let osLog = OSLog(subsystem: "com.next.sage", category: "general")
    private let apiLog = OSLog(subsystem: "com.next.sage", category: "api")
    private let voiceLog = OSLog(subsystem: "com.next.sage", category: "voice")
    
    // MARK: - Logging Methods
    
    /// Logs a debug message
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Logs an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Logs a warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Logs an error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Logs an error with Error object
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        log("Error: \(error.localizedDescription)", level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - API Logging
    
    /// Logs API request details
    func logAPIRequest(endpoint: String, method: String) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        os_log("[%{public}@] API Request: %{public}@ %{public}@", 
               log: apiLog, 
               type: .info, 
               timestamp, method, endpoint)
    }
    
    /// Logs API response with latency
    func logAPIResponse(endpoint: String, statusCode: Int, latency: TimeInterval) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let latencyMs = Int(latency * 1000)
        
        os_log("[%{public}@] API Response: %{public}@ status=%{public}d latency=%{public}dms", 
               log: apiLog, 
               type: .info, 
               timestamp, endpoint, statusCode, latencyMs)
    }
    
    /// Logs API error
    func logAPIError(endpoint: String, error: Error) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        os_log("[%{public}@] API Error: %{public}@ - %{public}@", 
               log: apiLog, 
               type: .error, 
               timestamp, endpoint, error.localizedDescription)
    }
    
    // MARK: - Voice Logging
    
    /// Logs speech recognition event
    func logSpeechRecognition(event: String) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        os_log("[%{public}@] Speech: %{public}@", 
               log: voiceLog, 
               type: .info, 
               timestamp, event)
    }
    
    /// Logs speech synthesis event
    func logSpeechSynthesis(event: String) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        os_log("[%{public}@] Synthesis: %{public}@", 
               log: voiceLog, 
               type: .info, 
               timestamp, event)
    }
    
    // MARK: - Private Methods
    
    private func log(_ message: String, level: LogLevel, file: String, function: String, line: Int) {
        guard isEnabled else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        
        let logMessage = "[\(timestamp)] [\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        switch level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: osLog, type: .error, logMessage)
        }
        
        #if DEBUG
        print(logMessage)
        #endif
    }
}
