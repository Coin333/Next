import Foundation

// MARK: - Storage Service
/// Handles local persistence using UserDefaults
/// In production, this would use Firestore or Core Data
class StorageService {
    
    // MARK: - Singleton
    static let shared = StorageService()
    
    // MARK: - Keys
    private enum Keys {
        static let user = "next.user"
        static let goals = "next.goals"
        static let tasks = "next.tasks"
        static let completedTasksHistory = "next.completedTasksHistory"
        static let onboardingCompleted = "next.onboardingCompleted"
    }
    
    // MARK: - User Defaults
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - User
    
    func saveUser(_ user: User) {
        if let encoded = try? encoder.encode(user) {
            defaults.set(encoded, forKey: Keys.user)
        }
    }
    
    func loadUser() -> User? {
        guard let data = defaults.data(forKey: Keys.user),
              let user = try? decoder.decode(User.self, from: data) else {
            return nil
        }
        return user
    }
    
    func getOrCreateUser() -> User {
        if let existingUser = loadUser() {
            return existingUser
        }
        let newUser = User()
        saveUser(newUser)
        return newUser
    }
    
    // MARK: - Goals
    
    func saveGoals(_ goals: [Goal]) {
        if let encoded = try? encoder.encode(goals) {
            defaults.set(encoded, forKey: Keys.goals)
        }
    }
    
    func loadGoals() -> [Goal] {
        guard let data = defaults.data(forKey: Keys.goals),
              let goals = try? decoder.decode([Goal].self, from: data) else {
            return []
        }
        return goals
    }
    
    func addGoal(_ goal: Goal) {
        var goals = loadGoals()
        goals.append(goal)
        saveGoals(goals)
    }
    
    func updateGoal(_ goal: Goal) {
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            saveGoals(goals)
        }
    }
    
    func deleteGoal(id: UUID) {
        var goals = loadGoals()
        goals.removeAll { $0.id == id }
        saveGoals(goals)
    }
    
    // MARK: - Tasks
    
    func saveTasks(_ tasks: [Task]) {
        if let encoded = try? encoder.encode(tasks) {
            defaults.set(encoded, forKey: Keys.tasks)
        }
    }
    
    func loadTasks() -> [Task] {
        guard let data = defaults.data(forKey: Keys.tasks),
              let tasks = try? decoder.decode([Task].self, from: data) else {
            return []
        }
        return tasks
    }
    
    func addTasks(_ newTasks: [Task]) {
        var tasks = loadTasks()
        tasks.append(contentsOf: newTasks)
        saveTasks(tasks)
    }
    
    func updateTask(_ task: Task) {
        var tasks = loadTasks()
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveTasks(tasks)
        }
    }
    
    func deleteTask(id: UUID) {
        var tasks = loadTasks()
        tasks.removeAll { $0.id == id }
        saveTasks(tasks)
    }
    
    func getTasksForGoal(_ goalId: UUID) -> [Task] {
        return loadTasks().filter { $0.goalId == goalId }
    }
    
    func getPendingTasks() -> [Task] {
        return loadTasks().filter { $0.status == .pending }
    }
    
    // MARK: - Completed Tasks History
    
    func saveCompletedTaskDate(_ date: Date) {
        var history = loadCompletedTasksHistory()
        history.append(date)
        if let encoded = try? encoder.encode(history) {
            defaults.set(encoded, forKey: Keys.completedTasksHistory)
        }
    }
    
    func loadCompletedTasksHistory() -> [Date] {
        guard let data = defaults.data(forKey: Keys.completedTasksHistory),
              let history = try? decoder.decode([Date].self, from: data) else {
            return []
        }
        return history
    }
    
    func getCompletedTasksToday() -> Int {
        let history = loadCompletedTasksHistory()
        let today = Calendar.current.startOfDay(for: Date())
        return history.filter { Calendar.current.isDate($0, inSameDayAs: today) }.count
    }
    
    // MARK: - Onboarding
    
    func isOnboardingCompleted() -> Bool {
        return defaults.bool(forKey: Keys.onboardingCompleted)
    }
    
    func setOnboardingCompleted() {
        defaults.set(true, forKey: Keys.onboardingCompleted)
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        defaults.removeObject(forKey: Keys.user)
        defaults.removeObject(forKey: Keys.goals)
        defaults.removeObject(forKey: Keys.tasks)
        defaults.removeObject(forKey: Keys.completedTasksHistory)
        defaults.removeObject(forKey: Keys.onboardingCompleted)
    }
    
    // MARK: - Daily Summary
    
    func generateDailySummary() -> DailySummary {
        let completedToday = getCompletedTasksToday()
        let tasks = loadTasks().filter { task in
            guard let completedDate = task.completedDate else { return false }
            return Calendar.current.isDateInToday(completedDate)
        }
        
        let totalMinutes = tasks.reduce(0) { $0 + $1.estimatedMinutes }
        
        return DailySummary(
            date: Date(),
            completedTasks: completedToday,
            totalMinutes: totalMinutes
        )
    }
}
