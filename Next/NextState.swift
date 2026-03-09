import Foundation
import SwiftUI
import Combine

// MARK: - Next State
/// Main application state manager
/// Handles all business logic and state transitions
@MainActor
class NextState: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current screen being displayed
    @Published var currentScreen: AppScreen = .energyCheck
    
    /// Current user
    @Published var user: User
    
    /// All goals
    @Published var goals: [Goal] = []
    
    /// All tasks
    @Published var tasks: [Task] = []
    
    /// The current task to display (the "Next" task)
    @Published var currentTask: Task?
    
    /// Whether we're showing the goal input sheet
    @Published var showingGoalInput: Bool = false
    
    /// Text input for new goal
    @Published var goalInputText: String = ""
    
    /// Whether we're in the process of creating tasks
    @Published var isProcessingGoal: Bool = false
    
    /// Error message if any
    @Published var errorMessage: String?
    
    /// Animation trigger for task completion
    @Published var showCompletionAnimation: Bool = false
    
    // MARK: - Services
    
    private let storage = StorageService.shared
    private let sage = SageAIService.shared
    
    // MARK: - Initialization
    
    init() {
        // Load or create user
        self.user = storage.getOrCreateUser()
        
        // Load existing data
        self.goals = storage.loadGoals()
        self.tasks = storage.loadTasks()
        
        // Determine initial screen
        determineInitialScreen()
    }
    
    // MARK: - Screen Flow Logic
    
    private func determineInitialScreen() {
        // Check if user needs energy check (daily)
        if user.needsEnergyCheck {
            currentScreen = .energyCheck
            return
        }
        
        // Check if there's a pending task
        if let nextTask = getNextPendingTask() {
            currentTask = nextTask
            currentScreen = .taskView
            return
        }
        
        // Check if we should show reflection (evening, has completed tasks)
        if shouldShowReflection() {
            currentScreen = .reflection
            return
        }
        
        // No tasks - show empty state
        currentScreen = .empty
    }
    
    private func shouldShowReflection() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        let completedToday = storage.getCompletedTasksToday()
        
        // Show reflection in evening (after 6 PM) if user has completed tasks
        return hour >= 18 && completedToday > 0 && user.preferences.enableDailyReflection
    }
    
    // MARK: - Task Selection Algorithm
    
    /// Gets the next pending task based on priority
    func getNextPendingTask() -> Task? {
        let pendingTasks = tasks.filter { $0.status == .pending }
        
        guard !pendingTasks.isEmpty else { return nil }
        
        // Sort by:
        // 1. Difficulty appropriate for energy level
        // 2. Created date (older first)
        let sortedTasks = pendingTasks.sorted { task1, task2 in
            // Prefer tasks matching current energy level
            let energyDiff1 = abs(task1.difficultyLevel.rawValue - idealDifficultyForEnergy().rawValue)
            let energyDiff2 = abs(task2.difficultyLevel.rawValue - idealDifficultyForEnergy().rawValue)
            
            if energyDiff1 != energyDiff2 {
                return energyDiff1 < energyDiff2
            }
            
            // Then by creation date
            return task1.createdDate < task2.createdDate
        }
        
        return sortedTasks.first
    }
    
    private func idealDifficultyForEnergy() -> DifficultyLevel {
        switch user.energyLevel {
        case .low: return .micro
        case .medium: return .small
        case .high: return .medium
        }
    }
    
    // MARK: - Energy Check Actions
    
    func setEnergyLevel(_ level: EnergyLevel) {
        user.updateEnergyLevel(level)
        storage.saveUser(user)
        
        // Move to next screen
        if let nextTask = getNextPendingTask() {
            currentTask = nextTask
            currentScreen = .taskView
        } else {
            currentScreen = .empty
        }
    }
    
    // MARK: - Task Actions
    
    /// Called when user taps "Done" - mark task complete
    func completeCurrentTask() {
        guard var task = currentTask else { return }
        
        // Mark as completed
        task.markComplete()
        
        // Update in storage
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        storage.saveTasks(tasks)
        storage.saveCompletedTaskDate(Date())
        
        // Update user stats
        user.incrementCompletedTasks()
        storage.saveUser(user)
        
        // Check if all tasks for this goal are complete
        checkGoalCompletion(for: task.goalId)
        
        // Show completion animation
        showCompletionAnimation = true
        currentScreen = .completion
    }
    
    /// Called when user taps "Not Now" - shrink the task
    func shrinkCurrentTask() {
        guard var task = currentTask else { return }
        
        if task.canShrink {
            task.shrink()
            currentTask = task
            
            // Update in storage
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = task
            }
            storage.saveTasks(tasks)
        } else {
            // Can't shrink further - skip and move to next
            skipCurrentTask()
        }
    }
    
    /// Called when user taps "Too Big" - same as shrink
    func taskTooBig() {
        shrinkCurrentTask()
    }
    
    /// Skip the current task and move to next
    func skipCurrentTask() {
        guard var task = currentTask else { return }
        
        task.markSkipped()
        
        // Update in storage
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
        storage.saveTasks(tasks)
        
        // Move to next task
        moveToNextTask()
    }
    
    /// Move to the next pending task after completion
    func moveToNextTask() {
        showCompletionAnimation = false
        
        if let nextTask = getNextPendingTask() {
            currentTask = nextTask
            currentScreen = .taskView
        } else if shouldShowReflection() {
            currentScreen = .reflection
        } else {
            currentScreen = .empty
        }
    }
    
    private func checkGoalCompletion(for goalId: UUID) {
        let goalTasks = tasks.filter { $0.goalId == goalId }
        let allCompleted = goalTasks.allSatisfy { $0.status == .completed }
        
        if allCompleted {
            if let index = goals.firstIndex(where: { $0.id == goalId }) {
                goals[index].markComplete()
                storage.saveGoals(goals)
            }
        }
    }
    
    // MARK: - Goal Input Actions
    
    func showGoalInput() {
        goalInputText = ""
        showingGoalInput = true
    }
    
    func hideGoalInput() {
        showingGoalInput = false
        goalInputText = ""
    }
    
    func submitGoal() {
        let trimmedGoal = goalInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGoal.isEmpty else { return }
        
        isProcessingGoal = true
        
        // Create the goal
        let goal = Goal(title: trimmedGoal)
        goals.append(goal)
        storage.saveGoals(goals)
        
        // Generate tasks using Sage AI
        let taskTemplates = sage.decomposeGoal(trimmedGoal, energyLevel: user.energyLevel)
        
        // Convert templates to tasks
        var newTasks: [Task] = []
        var taskIds: [UUID] = []
        
        for template in taskTemplates {
            let task = template.toTask(goalId: goal.id)
            newTasks.append(task)
            taskIds.append(task.id)
        }
        
        // Update goal with task IDs
        if let goalIndex = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[goalIndex].taskIds = taskIds
            storage.saveGoals(goals)
        }
        
        // Save tasks
        tasks.append(contentsOf: newTasks)
        storage.saveTasks(tasks)
        
        // Update UI
        isProcessingGoal = false
        hideGoalInput()
        
        // Move to task view
        if let nextTask = getNextPendingTask() {
            currentTask = nextTask
            currentScreen = .taskView
        }
    }
    
    // MARK: - Reflection Actions
    
    func getDailySummary() -> DailySummary {
        return storage.generateDailySummary()
    }
    
    func finishReflection(tomorrowGoal: String?) {
        // If user entered a goal for tomorrow, save it
        if let goal = tomorrowGoal, !goal.isEmpty {
            let newGoal = Goal(title: goal)
            goals.append(newGoal)
            storage.saveGoals(goals)
            
            // Generate tasks for it
            let taskTemplates = sage.decomposeGoal(goal, energyLevel: .medium) // Default to medium for tomorrow
            let newTasks = taskTemplates.map { $0.toTask(goalId: newGoal.id) }
            tasks.append(contentsOf: newTasks)
            storage.saveTasks(tasks)
        }
        
        // Move to appropriate screen
        if let nextTask = getNextPendingTask() {
            currentTask = nextTask
            currentScreen = .taskView
        } else {
            currentScreen = .empty
        }
    }
    
    // MARK: - Reset / Debug
    
    func resetAllData() {
        storage.clearAllData()
        user = User()
        goals = []
        tasks = []
        currentTask = nil
        currentScreen = .energyCheck
    }
    
    // MARK: - Computed Properties
    
    var hasPendingTasks: Bool {
        tasks.contains { $0.status == .pending }
    }
    
    var completedTasksCount: Int {
        storage.getCompletedTasksToday()
    }
    
    var activeGoalsCount: Int {
        goals.filter { $0.status == .active }.count
    }
}
