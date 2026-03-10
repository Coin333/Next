import Foundation
import SwiftUI

// MARK: - V1 Compatibility Layer
// This file provides types and extensions needed for v1 code to work with v2.

// MARK: - App Screen
/// Screens in the v1 app flow
enum AppScreen {
    case energyCheck
    case taskView
    case completion
    case goalInput
    case reflection
    case empty
}

// MARK: - User Model
/// User model for v1 compatibility
struct User: Codable {
    var id: UUID
    var energyLevel: EnergyLevel
    var lastEnergyCheckDate: Date?
    var totalCompletedTasks: Int
    var preferences: UserPreferences
    
    init(
        id: UUID = UUID(),
        energyLevel: EnergyLevel = .medium,
        lastEnergyCheckDate: Date? = nil,
        totalCompletedTasks: Int = 0,
        preferences: UserPreferences = UserPreferences()
    ) {
        self.id = id
        self.energyLevel = energyLevel
        self.lastEnergyCheckDate = lastEnergyCheckDate
        self.totalCompletedTasks = totalCompletedTasks
        self.preferences = preferences
    }
    
    var needsEnergyCheck: Bool {
        guard let lastCheck = lastEnergyCheckDate else { return true }
        return !Calendar.current.isDateInToday(lastCheck)
    }
    
    mutating func updateEnergyLevel(_ level: EnergyLevel) {
        self.energyLevel = level
        self.lastEnergyCheckDate = Date()
    }
    
    mutating func incrementCompletedTasks() {
        totalCompletedTasks += 1
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var enableDailyReflection: Bool = true
    var enableNotifications: Bool = true
    var preferredWorkTime: Date?
}

// MARK: - Difficulty Level
/// Task difficulty levels for v1
enum DifficultyLevel: Int, Codable, CaseIterable {
    case micro = 1
    case small = 2
    case medium = 3
    case large = 4
    
    var displayName: String {
        switch self {
        case .micro: return "Micro"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
    
    var minuteRange: ClosedRange<Int> {
        switch self {
        case .micro: return 5...10
        case .small: return 10...20
        case .medium: return 20...40
        case .large: return 40...60
        }
    }
}

// MARK: - Daily Summary
/// Summary of daily progress for v1
struct DailySummary {
    let date: Date
    let completedTasks: Int
    let totalMinutes: Int
    
    var formattedTime: String {
        if totalMinutes < 60 {
            return "\(totalMinutes) minutes"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return "\(hours)h \(mins)m"
        }
    }
    
    /// Main summary message
    var message: String {
        if completedTasks == 0 {
            return "No tasks completed today, but tomorrow is a new day."
        } else if completedTasks == 1 {
            return "You completed 1 task today."
        } else {
            return "You completed \(completedTasks) tasks today."
        }
    }
    
    /// Encouragement message
    var encouragement: String {
        if completedTasks == 0 {
            return "Rest up and start fresh tomorrow."
        } else if completedTasks < 3 {
            return "Every step forward counts."
        } else {
            return "Great progress! You're building momentum."
        }
    }
}

// MARK: - Task Template
/// Template for generating tasks from goals (v1)
struct TaskTemplate {
    let title: String
    let estimatedMinutes: Int
    let difficulty: DifficultyLevel
    let shrunkVersions: [String]
    
    func toTask(goalId: UUID) -> NextTask {
        return NextTask(
            id: UUID(),
            title: title,
            description: nil,
            estimatedMinutes: estimatedMinutes,
            status: .pending,
            goalId: goalId,
            order: 0,
            sageMessage: nil
        )
    }
}

// MARK: - SageTask Extensions for V1 Compatibility
extension SageTask {
    /// V1-compatible initializer with difficultyLevel
    init(
        goalId: UUID,
        title: String,
        estimatedMinutes: Int,
        difficultyLevel: DifficultyLevel,
        shrunkVersions: [String] = []
    ) {
        self.init(
            id: UUID(),
            title: title,
            description: nil,
            estimatedMinutes: estimatedMinutes,
            status: .pending,
            goalId: goalId,
            order: 0,
            sageMessage: nil
        )
    }
    
    /// V1-compatible initializer with shrunkVersions
    init(
        goalId: UUID,
        title: String,
        estimatedMinutes: Int,
        shrunkVersions: [String] = []
    ) {
        self.init(
            id: UUID(),
            title: title,
            description: nil,
            estimatedMinutes: estimatedMinutes,
            status: .pending,
            goalId: goalId,
            order: 0,
            sageMessage: nil
        )
    }
    
    /// Computed property for v1 compatibility
    var difficultyLevel: DifficultyLevel {
        switch estimatedMinutes {
        case 0...10: return .micro
        case 11...20: return .small
        case 21...40: return .medium
        default: return .large
        }
    }
    
    /// V1 shrunk versions - returns generic shrink options
    var shrunkVersions: [String] {
        return [
            "Work for 5 minutes on: \(title)",
            "Just start: \(title)",
            "Open what you need for: \(title)"
        ]
    }
    
    /// V1 compatibility - shrink level (how many times shrunk)
    var shrinkLevel: Int {
        // Estimate based on time - smaller time = more shrunk
        if estimatedMinutes <= 5 { return 3 }
        if estimatedMinutes <= 10 { return 2 }
        if estimatedMinutes <= 15 { return 1 }
        return 0
    }
    
    /// V1 compatibility - current title (may be shrunk version)
    var currentTitle: String {
        return title
    }
    
    /// V1 compatibility - formatted time string
    var formattedTime: String {
        return timeEstimate
    }
    
    /// V1 compatibility - whether task can be shrunk
    var canShrink: Bool {
        return estimatedMinutes > 5
    }
    
    /// V1 compatibility - current shrink level
    var currentShrinkLevel: Int {
        return shrinkLevel
    }
    
    /// V1 compatibility - completed date
    var completedDate: Date? {
        return completedAt
    }
    
    /// V1 compatibility - created date
    var createdDate: Date {
        return createdAt
    }
    
    /// V1 mutating method - shrink task
    mutating func shrink() {
        estimatedMinutes = max(5, estimatedMinutes / 2)
    }
    
    /// V1 mutating method - mark complete
    mutating func markComplete() {
        complete()
    }
    
    /// V1 mutating method - mark skipped
    mutating func markSkipped() {
        skip()
    }
}

// MARK: - Goal Extensions for V1 Compatibility
extension Goal {
    /// Task IDs for v1 compatibility
    var taskIds: [UUID] {
        get { tasks.map { $0.id } }
        set { /* no-op for compatibility */ }
    }
    
    /// V1 mutating method - mark complete
    mutating func markComplete() {
        status = .completed
        completedAt = Date()
    }
}

// MARK: - EnergyLevel Extensions for V1 Compatibility
extension EnergyLevel {
    /// Maximum estimated minutes for tasks at this energy level
    var maxEstimatedMinutes: Int {
        switch self {
        case .low: return 15
        case .medium: return 30
        case .high: return 45
        }
    }
    
    /// Description shown in energy check view
    var description: String {
        switch self {
        case .low: return "Small steps today"
        case .medium: return "Ready for moderate tasks"
        case .high: return "Bring on the challenges"
        }
    }
}
