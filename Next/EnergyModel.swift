import Foundation

// MARK: - Energy Model
/// Estimates and tracks user energy levels through multiple signals.
/// Provides dynamic energy detection based on behavior patterns.
final class EnergyModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentEnergyLevel: EnergyLevel = .medium
    @Published private(set) var energyHistory: [EnergySnapshot] = []
    @Published private(set) var predictedEnergyTrend: EnergyTrend = .stable
    
    // MARK: - Private Properties
    
    private var energyScores: [EnergySignal: Float] = [
        .timeOfDay: 0.5,
        .completionRate: 0.5,
        .interactionSpeed: 0.5,
        .sessionDuration: 0.5,
        .recentActivity: 0.5
    ]
    
    private let maxHistorySize = 168 // One week of hourly data
    private var lastEnergyCheckTime: Date?
    
    // MARK: - Initialization
    
    init() {
        // Load from storage or use defaults
    }
    
    // MARK: - Core Methods
    
    /// Detects energy level from multiple signals
    func detectEnergyDynamically(
        taskCompletionRate: Float,
        interactionSpeed: Float,
        sessionDurationMinutes: Int,
        recentActivityCount: Int
    ) -> EnergyLevel {
        // Update individual signals
        energyScores[.completionRate] = taskCompletionRate
        energyScores[.interactionSpeed] = interactionSpeed
        energyScores[.sessionDuration] = Float(sessionDurationMinutes) / 60.0 // Normalize to 0-1
        energyScores[.recentActivity] = Float(min(recentActivityCount, 10)) / 10.0 // Normalize
        energyScores[.timeOfDay] = calculateTimeOfDayEnergy()
        
        let detectedLevel = calculateEnergyLevel()
        
        // Record snapshot for trend analysis
        recordEnergySnapshot(level: detectedLevel)
        
        currentEnergyLevel = detectedLevel
        
        return detectedLevel
    }
    
    /// Gets estimated energy based on time of day alone
    func estimateEnergyByTimeOfDay() -> EnergyLevel {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Early morning (5am-8am) - low to medium
        if hour >= 5 && hour < 8 {
            return .low
        }
        // Morning peak (8am-12pm) - high
        else if hour >= 8 && hour < 12 {
            return .high
        }
        // Lunch dip (12pm-2pm) - low to medium
        else if hour >= 12 && hour < 14 {
            return .low
        }
        // Afternoon peak (2pm-5pm) - medium to high
        else if hour >= 14 && hour < 17 {
            return .medium
        }
        // Evening wind-down (5pm-9pm) - low to medium
        else if hour >= 17 && hour < 21 {
            return .low
        }
        // Late night (9pm-5am) - low
        else {
            return .low
        }
    }
    
    /// Predicts energy trend (improving, declining, or stable)
    func predictEnergyTrend() -> EnergyTrend {
        guard energyHistory.count >= 3 else {
            return .stable
        }
        
        let recent = energyHistory.suffix(3).map { $0.level.rawValue }
        let average = recent.reduce(0, +) / Float(recent.count)
        
        let oldest = recent[0]
        let newest = recent[2]
        
        if newest > oldest && newest > average {
            return .improving
        } else if newest < oldest && newest < average {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// Checks if energy is very low (requires special handling)
    var isVeryLow: Bool {
        currentEnergyLevel == .low && predictedEnergyTrend == .declining
    }
    
    /// Gets recommended task duration for current energy
    func getRecommendedTaskDuration() -> Int {
        switch currentEnergyLevel {
        case .low: return 5
        case .medium: return 15
        case .high: return 30
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateTimeOfDayEnergy() -> Float {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Normalize hour (0-23) to energy score (0-1)
        switch hour {
        case 5..<8: return 0.3 // Early morning - low
        case 8..<12: return 0.9 // Morning peak - high
        case 12..<14: return 0.4 // Lunch dip
        case 14..<17: return 0.7 // Afternoon peak
        case 17..<21: return 0.3 // Evening wind-down
        default: return 0.2 // Late night - very low
        }
    }
    
    private func calculateEnergyLevel() -> EnergyLevel {
        let weights: [EnergySignal: Float] = [
            .timeOfDay: 0.25,
            .completionRate: 0.25,
            .interactionSpeed: 0.2,
            .sessionDuration: 0.15,
            .recentActivity: 0.15
        ]
        
        var weightedScore: Float = 0
        
        for (signal, weight) in weights {
            if let score = energyScores[signal] {
                weightedScore += score * weight
            }
        }
        
        // Convert weighted score (0-1) to EnergyLevel
        if weightedScore >= 0.65 {
            return .high
        } else if weightedScore >= 0.35 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func recordEnergySnapshot(level: EnergyLevel) {
        let snapshot = EnergySnapshot(
            level: level,
            timestamp: Date(),
            signalValues: energyScores
        )
        
        energyHistory.append(snapshot)
        
        if energyHistory.count > maxHistorySize {
            energyHistory.removeFirst(energyHistory.count - maxHistorySize)
        }
        
        predictedEnergyTrend = predictEnergyTrend()
    }
}

// MARK: - Energy Signal

enum EnergySignal {
    case timeOfDay
    case completionRate
    case interactionSpeed
    case sessionDuration
    case recentActivity
}

// MARK: - Energy Snapshot

struct EnergySnapshot {
    let level: EnergyLevel
    let timestamp: Date
    let signalValues: [EnergySignal: Float]
}

// MARK: - Energy Trend

enum EnergyTrend {
    case improving
    case declining
    case stable
    
    var description: String {
        switch self {
        case .improving: return "Energy is improving"
        case .declining: return "Energy is declining"
        case .stable: return "Energy is stable"
        }
    }
}
