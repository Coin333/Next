import Foundation

// MARK: - Energy Level
/// User's energy level affects task sizing
enum EnergyLevel: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.100"
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Take it easy today"
        case .medium: return "Balanced energy"
        case .high: return "Ready to tackle more"
        }
    }
    
    var taskSizeMultiplier: Double {
        switch self {
        case .low: return 0.5
        case .medium: return 1.0
        case .high: return 1.5
        }
    }
    
    var maxEstimatedMinutes: Int {
        switch self {
        case .low: return 15
        case .medium: return 30
        case .high: return 45
        }
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case skipped
}

// MARK: - Goal Status
enum GoalStatus: String, Codable {
    case active
    case completed
    case paused
}

// MARK: - Difficulty Level
enum DifficultyLevel: Int, Codable, CaseIterable {
    case micro = 1
    case small = 2
    case medium = 3
    case large = 4
    
    var description: String {
        switch self {
        case .micro: return "Micro"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

// MARK: - Task Model
struct NextTask: Identifiable, Codable, Equatable {
    let id: UUID
    let goalId: UUID
    var title: String
    var estimatedMinutes: Int
    var difficultyLevel: DifficultyLevel
    var status: TaskStatus
    var shrinkLevel: Int  // 0 = original, higher = more shrunk
    var shrunkVersions: [String]  // Pre-computed shrunk versions
    var createdDate: Date
    var completedDate: Date?
    
    init(
        id: UUID = UUID(),
        goalId: UUID,
        title: String,
        estimatedMinutes: Int = 20,
        difficultyLevel: DifficultyLevel = .medium,
        status: TaskStatus = .pending,
        shrinkLevel: Int = 0,
        shrunkVersions: [String] = [],
        createdDate: Date = Date(),
        completedDate: Date? = nil
    ) {
        self.id = id
        self.goalId = goalId
        self.title = title
        self.estimatedMinutes = estimatedMinutes
        self.difficultyLevel = difficultyLevel
        self.status = status
        self.shrinkLevel = shrinkLevel
        self.shrunkVersions = shrunkVersions
        self.createdDate = createdDate
        self.completedDate = completedDate
    }
    
    /// Returns the current title based on shrink level
    var currentTitle: String {
        if shrinkLevel > 0 && shrinkLevel <= shrunkVersions.count {
            return shrunkVersions[shrinkLevel - 1]
        }
        return title
    }
    
    /// Current estimated time (decreases with shrinking)
    var currentEstimatedMinutes: Int {
        let reduction = Double(shrinkLevel) * 0.3
        let adjusted = Double(estimatedMinutes) * max(0.2, 1.0 - reduction)
        return max(5, Int(adjusted))
    }
    
    /// Formatted time string
    var formattedTime: String {
        let mins = currentEstimatedMinutes
        if mins < 60 {
            return "~\(mins) min"
        } else {
            let hours = mins / 60
            let remainder = mins % 60
            if remainder == 0 {
                return "~\(hours) hr"
            }
            return "~\(hours) hr \(remainder) min"
        }
    }
    
    /// Whether the task can be shrunk further
    var canShrink: Bool {
        shrinkLevel < shrunkVersions.count
    }
    
    /// Shrink the task to a smaller version
    mutating func shrink() {
        if canShrink {
            shrinkLevel += 1
        }
    }
    
    /// Mark the task as completed
    mutating func markComplete() {
        status = .completed
        completedDate = Date()
    }
    
    /// Mark the task as skipped
    mutating func markSkipped() {
        status = .skipped
    }
    
    static func == (lhs: NextTask, rhs: NextTask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Goal Model
struct Goal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var status: GoalStatus
    var createdDate: Date
    var completedDate: Date?
    var taskIds: [UUID]
    
    init(
        id: UUID = UUID(),
        title: String,
        status: GoalStatus = .active,
        createdDate: Date = Date(),
        completedDate: Date? = nil,
        taskIds: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.status = status
        self.createdDate = createdDate
        self.completedDate = completedDate
        self.taskIds = taskIds
    }
    
    /// Mark the goal as completed
    mutating func markComplete() {
        status = .completed
        completedDate = Date()
    }
    
    static func == (lhs: Goal, rhs: Goal) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - User Model
struct User: Codable {
    let id: UUID
    var energyLevel: EnergyLevel
    var lastEnergyCheckDate: Date?
    var preferences: UserPreferences
    var completedTasksToday: Int
    var lastActiveDate: Date?
    
    init(
        id: UUID = UUID(),
        energyLevel: EnergyLevel = .medium,
        lastEnergyCheckDate: Date? = nil,
        preferences: UserPreferences = UserPreferences(),
        completedTasksToday: Int = 0,
        lastActiveDate: Date? = nil
    ) {
        self.id = id
        self.energyLevel = energyLevel
        self.lastEnergyCheckDate = lastEnergyCheckDate
        self.preferences = preferences
        self.completedTasksToday = completedTasksToday
        self.lastActiveDate = lastActiveDate
    }
    
    /// Whether the user needs a daily energy check
    var needsEnergyCheck: Bool {
        guard let lastCheck = lastEnergyCheckDate else { return true }
        return !Calendar.current.isDateInToday(lastCheck)
    }
    
    /// Update the user's energy level
    mutating func updateEnergyLevel(_ level: EnergyLevel) {
        energyLevel = level
        lastEnergyCheckDate = Date()
    }
    
    /// Increment the completed tasks counter
    mutating func incrementCompletedTasks() {
        // Reset counter if it's a new day
        if let lastActive = lastActiveDate,
           !Calendar.current.isDateInToday(lastActive) {
            completedTasksToday = 0
        }
        completedTasksToday += 1
        lastActiveDate = Date()
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var enableVoiceInput: Bool
    var enableDailyReflection: Bool
    var preferredTaskDuration: Int  // in minutes
    
    init(
        enableVoiceInput: Bool = true,
        enableDailyReflection: Bool = true,
        preferredTaskDuration: Int = 20
    ) {
        self.enableVoiceInput = enableVoiceInput
        self.enableDailyReflection = enableDailyReflection
        self.preferredTaskDuration = preferredTaskDuration
    }
}

// MARK: - Daily Summary
struct DailySummary {
    let date: Date
    let completedTasks: Int
    let totalMinutes: Int
    
    var message: String {
        if completedTasks == 0 {
            return "No tasks completed today.\nThat's okay — tomorrow is a fresh start."
        } else if completedTasks == 1 {
            return "You completed 1 task today.\nEvery step counts."
        } else {
            return "You completed \(completedTasks) tasks today.\nGreat momentum!"
        }
    }
    
    var encouragement: String {
        if completedTasks == 0 {
            return "Rest is productive too."
        } else if completedTasks < 3 {
            return "Progress, not perfection."
        } else {
            return "You're on fire!"
        }
    }
}

// MARK: - App Screen State
enum AppScreen: Equatable {
    case energyCheck
    case taskView
    case completion
    case goalInput
    case reflection
    case empty
}
