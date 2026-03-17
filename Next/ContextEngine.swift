import Foundation

// MARK: - Context Engine
/// Provides context-aware task timing and scheduling.
/// Integrates with calendar, known routines, and time availability.
final class ContextEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var availableTimeMinutes: Int = 0
    @Published private(set) var currentTimeBlock: TimeBlock?
    @Published private(set) var recommendedTaskDuration: Int = 15
    
    // MARK: - Private Properties
    
    private var userRoutines: [DayRoutine] = []
    private var scheduledTimeBlocks: [TimeBlock] = []
    
    // MARK: - Initialization
    
    init() {
        setupDefaultRoutines()
    }
    
    // MARK: - Core Methods
    
    /// Calculates available time until next commitment
    func calculateAvailableTime() -> Int {
        let now = Date()
        let calendar = Calendar.current
        let currentMinute = calendar.component(.minute, from: now)
        let currentHour = calendar.component(.hour, from: now)
        
        // Find next scheduled block
        for block in scheduledTimeBlocks.sorted(by: { $0.startHour < $1.startHour }) {
            if block.startHour > currentHour ||
               (block.startHour == currentHour && block.startMinute > currentMinute) {
                let minutesUntilBlock = (block.startHour * 60 + block.startMinute) -
                                       (currentHour * 60 + currentMinute)
                availableTimeMinutes = minutesUntilBlock
                return minutesUntilBlock
            }
        }
        
        // If no scheduled block today, plenty of time
        availableTimeMinutes = 480 // 8 hours
        return 480
    }
    
    /// Gets recommended task size based on available time
    func getTaskSizeForAvailableTime(_ minutes: Int) -> TaskSize {
        if minutes <= 5 {
            return .micro
        } else if minutes <= 15 {
            return .small
        } else if minutes <= 30 {
            return .medium
        } else {
            return .large
        }
    }
    
    /// Checks if right time for focus work
    func isOptimalFocusTime() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Early morning (8am-12pm) and early afternoon (2pm-4pm) are optimal
        return (hour >= 8 && hour < 12) || (hour >= 14 && hour < 16)
    }
    
    /// Suggests optimal task based on time and routine
    func suggestTaskType(for availableMinutes: Int) -> SuggestedTaskType {
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Morning - good for focused, complex work
        if hour >= 8 && hour < 12 {
            return .focused
        }
        // Lunch - lighter tasks
        else if hour >= 12 && hour < 14 {
            return .light
        }
        // Afternoon - moderate work
        else if hour >= 14 && hour < 17 {
            return .moderate
        }
        // Evening - admin/planning tasks
        else if hour >= 17 && hour < 21 {
            return .admin
        }
        // Night - minimal
        else {
            return .minimal
        }
    }
    
    /// Detects if user is in a known routine
    func isInKnownRoutine() -> DayRoutine? {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        
        return userRoutines.first { routine in
            routine.dayOfWeek == weekday
        }
    }
    
    /// Gets time until next routine event
    func timeUntilNextRoutineEvent() -> TimeInterval? {
        guard let routine = isInKnownRoutine() else {
            return nil
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        for event in routine.events.sorted(by: { $0.startTime < $1.startTime }) {
            if event.startTime > now {
                return event.startTime.timeIntervalSince(now)
            }
        }
        
        return nil
    }
    
    /// Adds a time block (e.g., meeting, appointment)
    func addTimeBlock(_ block: TimeBlock) {
        scheduledTimeBlocks.append(block)
        scheduledTimeBlocks.sort { $0.startHour < $1.startHour }
    }
    
    /// Gets today's schedule summary
    func getTodaysSummary() -> String {
        let availableMinutes = calculateAvailableTime()
        let taskType = suggestTaskType(for: availableMinutes)
        
        return "You have about \(availableMinutes) minutes available. Perfect for \(taskType.rawValue) work."
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultRoutines() {
        // Monday-Friday routine
        let workdayRoutine = DayRoutine(
            dayOfWeek: 2, // Monday
            name: "Weekday",
            events: [
                RoutineEvent(name: "Morning", startTime: Date().addingTimeInterval(8 * 3600)),
                RoutineEvent(name: "Midday", startTime: Date().addingTimeInterval(12 * 3600)),
                RoutineEvent(name: "Evening", startTime: Date().addingTimeInterval(18 * 3600))
            ]
        )
        
        userRoutines.append(workdayRoutine)
    }
}

// MARK: - Time Block

struct TimeBlock {
    let name: String
    let startHour: Int // 0-23
    let startMinute: Int // 0-59
    let durationMinutes: Int
    
    var endHour: Int {
        (startHour + (startMinute + durationMinutes) / 60) % 24
    }
    
    var endMinute: Int {
        (startMinute + durationMinutes) % 60
    }
}

// MARK: - Task Size

enum TaskSize: String {
    case micro = "very short (2-5 min)"
    case small = "short (5-15 min)"
    case medium = "moderate (15-30 min)"
    case large = "extended (30+ min)"
}

// MARK: - Suggested Task Type

enum SuggestedTaskType: String {
    case focused = "focused, deep work"
    case light = "light, varied tasks"
    case moderate = "moderate tasks"
    case admin = "admin and planning"
    case minimal = "minimal activity"
}

// MARK: - Day Routine

struct DayRoutine {
    let dayOfWeek: Int // 1=Sunday, 2=Monday, etc.
    let name: String
    let events: [RoutineEvent]
}

// MARK: - Routine Event

struct RoutineEvent {
    let name: String
    let startTime: Date
}
