import Foundation

// MARK: - Task Engine
/// Manages task operations and state.
/// Handles task lifecycle and persistence.
final class TaskEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var currentGoal: Goal?
    @Published private(set) var currentTask: SageTask?
    
    // MARK: - Private Properties
    
    private let storageKey = "com.next.goals"
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    init() {
        loadGoals()
    }
    
    // MARK: - Goal Management
    
    /// Creates a new goal from AI decomposition
    func createGoal(from response: ResponseParser.GoalDecompositionResponse, title: String) -> Goal {
        var goal = Goal(
            title: title,
            sageIntroMessage: response.introMessage
        )
        
        // Add tasks from AI response
        for (index, parsedTask) in response.tasks.enumerated() {
            let task = SageTask(
                title: parsedTask.title,
                description: parsedTask.description,
                estimatedMinutes: parsedTask.estimatedMinutes,
                goalId: goal.id,
                order: index,
                sageMessage: index == 0 ? response.firstTaskMessage : nil
            )
            goal.tasks.append(task)
        }
        
        // Add to goals list
        goals.insert(goal, at: 0)
        currentGoal = goal
        currentTask = goal.currentTask
        
        saveGoals()
        Logger.shared.info("Created goal: \(title) with \(goal.tasks.count) tasks")
        
        return goal
    }
    
    /// Gets or creates the active goal
    func getActiveGoal() -> Goal? {
        if let current = currentGoal {
            return current
        }
        
        // Find first active goal
        currentGoal = goals.first { $0.status == .active }
        currentTask = currentGoal?.currentTask
        
        return currentGoal
    }
    
    /// Sets the current active goal
    func setActiveGoal(_ goal: Goal?) {
        currentGoal = goal
        currentTask = goal?.currentTask
        saveGoals()
    }
    
    // MARK: - Task Management
    
    /// Completes the current task
    func completeCurrentTask() -> (completed: SageTask, next: SageTask?)? {
        guard var goal = currentGoal,
              let taskIndex = goal.tasks.firstIndex(where: { $0.id == currentTask?.id }) else {
            return nil
        }
        
        let completedTask = goal.tasks[taskIndex]
        goal.tasks[taskIndex].complete()
        
        // Update current task
        let nextTask = goal.currentTask
        
        // Check if goal is complete
        if goal.isComplete {
            goal.status = .completed
            goal.completedAt = Date()
        }
        
        // Update stored goal
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex] = goal
        }
        
        currentGoal = goal
        currentTask = nextTask
        
        saveGoals()
        Logger.shared.info("Completed task: \(completedTask.title)")
        
        return (completed: completedTask, next: nextTask)
    }
    
    /// Skips the current task
    func skipCurrentTask() -> SageTask? {
        guard var goal = currentGoal,
              let taskIndex = goal.tasks.firstIndex(where: { $0.id == currentTask?.id }) else {
            return nil
        }
        
        goal.tasks[taskIndex].skip()
        
        let nextTask = goal.currentTask
        
        // Update stored goal
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex] = goal
        }
        
        currentGoal = goal
        currentTask = nextTask
        
        saveGoals()
        Logger.shared.info("Skipped task, moving to: \(nextTask?.title ?? "none")")
        
        return nextTask
    }
    
    /// Replaces current task with a smaller version
    func replaceWithSmallerTask(_ smallerTask: ResponseParser.ParsedTask) {
        guard var goal = currentGoal,
              let taskIndex = goal.tasks.firstIndex(where: { $0.id == currentTask?.id }) else {
            return
        }
        
        let newTask = SageTask(
            title: smallerTask.title,
            description: smallerTask.description,
            estimatedMinutes: smallerTask.estimatedMinutes,
            goalId: goal.id,
            order: goal.tasks[taskIndex].order
        )
        
        goal.tasks[taskIndex] = newTask
        
        // Update stored goal
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex] = goal
        }
        
        currentGoal = goal
        currentTask = newTask
        
        saveGoals()
        Logger.shared.info("Replaced task with smaller: \(newTask.title)")
    }
    
    /// Pauses the current goal
    func pauseCurrentGoal() {
        guard var goal = currentGoal else { return }
        
        goal.pause()
        
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex] = goal
        }
        
        currentGoal = nil
        currentTask = nil
        
        saveGoals()
        Logger.shared.info("Paused goal: \(goal.title)")
    }
    
    /// Resumes a paused goal
    func resumeGoal(_ goal: Goal) {
        guard var updatedGoal = goals.first(where: { $0.id == goal.id }) else { return }
        
        updatedGoal.resume()
        
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex] = updatedGoal
        }
        
        currentGoal = updatedGoal
        currentTask = updatedGoal.currentTask
        
        saveGoals()
        Logger.shared.info("Resumed goal: \(updatedGoal.title)")
    }
    
    // MARK: - Queries
    
    /// Gets all active goals
    var activeGoals: [Goal] {
        goals.filter { $0.status == .active }
    }
    
    /// Gets completed goals
    var completedGoals: [Goal] {
        goals.filter { $0.status == .completed }
    }
    
    /// Whether there's an active task
    var hasActiveTask: Bool {
        currentTask != nil
    }
    
    // MARK: - Persistence
    
    private func saveGoals() {
        guard let data = try? encoder.encode(goals) else {
            Logger.shared.error("Failed to encode goals")
            return
        }
        
        defaults.set(data, forKey: storageKey)
    }
    
    private func loadGoals() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([Goal].self, from: data) else {
            goals = []
            return
        }
        
        goals = decoded
        currentGoal = goals.first { $0.status == .active }
        currentTask = currentGoal?.currentTask
        
        Logger.shared.info("Loaded \(goals.count) goals")
    }
    
    /// Clears all data (for testing)
    func clearAllData() {
        goals = []
        currentGoal = nil
        currentTask = nil
        defaults.removeObject(forKey: storageKey)
        Logger.shared.info("Cleared all task data")
    }
}
