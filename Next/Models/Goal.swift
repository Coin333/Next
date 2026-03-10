import Foundation

// MARK: - Goal Model
/// Represents a user's goal that gets decomposed into tasks.
/// Goals are the high-level objectives that Sage helps break down.
struct Goal: Identifiable, Codable, Equatable {
    
    /// Unique identifier
    let id: UUID
    
    /// Goal title from user input
    let title: String
    
    /// Original user input (may differ from processed title)
    var originalInput: String?
    
    /// Current status
    var status: GoalStatus
    
    /// Associated tasks
    var tasks: [SageTask]
    
    /// When the goal was created
    let createdAt: Date
    
    /// When the goal was completed (if applicable)
    var completedAt: Date?
    
    /// Initial message from Sage about this goal
    var sageIntroMessage: String?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        title: String,
        originalInput: String? = nil,
        status: GoalStatus = .active,
        tasks: [SageTask] = [],
        sageIntroMessage: String? = nil
    ) {
        self.id = id
        self.title = title
        self.originalInput = originalInput ?? title
        self.status = status
        self.tasks = tasks
        self.createdAt = Date()
        self.completedAt = nil
        self.sageIntroMessage = sageIntroMessage
    }
    
    // MARK: - Computed Properties
    
    /// Number of completed tasks
    var completedTaskCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    /// Total number of tasks
    var totalTaskCount: Int {
        tasks.count
    }
    
    /// Progress percentage (0.0 - 1.0)
    var progress: Double {
        guard totalTaskCount > 0 else { return 0 }
        return Double(completedTaskCount) / Double(totalTaskCount)
    }
    
    /// The current active task (first pending or in-progress)
    var currentTask: SageTask? {
        tasks.first { $0.status == .pending || $0.status == .inProgress }
    }
    
    /// Whether the goal is complete
    var isComplete: Bool {
        !tasks.isEmpty && tasks.allSatisfy { $0.status == .completed || $0.status == .skipped }
    }
    
    /// Remaining tasks count
    var remainingTaskCount: Int {
        tasks.filter { $0.status == .pending || $0.status == .inProgress }.count
    }
    
    // MARK: - Mutations
    
    /// Adds a task to the goal
    mutating func addTask(_ task: SageTask) {
        var newTask = task
        newTask.goalId = id
        newTask.order = tasks.count
        tasks.append(newTask)
    }
    
    /// Completes the current task and returns the next one
    mutating func completeCurrentTask() -> SageTask? {
        guard let index = tasks.firstIndex(where: { $0.status == .inProgress || $0.status == .pending }) else {
            return nil
        }
        
        tasks[index].complete()
        
        // Check if goal is complete
        if isComplete {
            status = .completed
            completedAt = Date()
            return nil
        }
        
        // Return the next task
        return currentTask
    }
    
    /// Skips the current task
    mutating func skipCurrentTask() -> SageTask? {
        guard let index = tasks.firstIndex(where: { $0.status == .inProgress || $0.status == .pending }) else {
            return nil
        }
        
        tasks[index].skip()
        return currentTask
    }
    
    /// Marks the goal as paused
    mutating func pause() {
        status = .paused
    }
    
    /// Resumes a paused goal
    mutating func resume() {
        status = .active
    }
}

// MARK: - Goal Status

enum GoalStatus: String, Codable, CaseIterable {
    case active = "active"
    case completed = "completed"
    case paused = "paused"
    case abandoned = "abandoned"
    
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .paused: return "Paused"
        case .abandoned: return "Abandoned"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "target"
        case .completed: return "checkmark.seal.fill"
        case .paused: return "pause.circle"
        case .abandoned: return "xmark.circle"
        }
    }
}
