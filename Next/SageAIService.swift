import Foundation

// MARK: - Sage AI Service
/// Handles AI-powered task decomposition and shrinking
/// Named after the AI companion "Sage" from the product spec
class SageAIService {
    
    // MARK: - Singleton
    static let shared = SageAIService()
    
    private init() {}
    
    // MARK: - Task Decomposition
    /// Breaks down a goal into micro tasks (10-40 minutes each)
    /// In production, this would call an LLM API
    func decomposeGoal(_ goalTitle: String, energyLevel: EnergyLevel) -> [TaskTemplate] {
        // Simulate AI task decomposition
        // In production, this would call OpenAI or similar
        
        let templates = generateTaskTemplates(for: goalTitle, energy: energyLevel)
        return templates
    }
    
    // MARK: - Task Shrinking
    /// Generates progressively smaller versions of a task
    func generateShrunkVersions(for taskTitle: String) -> [String] {
        // Generate 3 levels of shrinking
        // Level 1: Slightly smaller
        // Level 2: Much smaller
        // Level 3: Minimal action (just start)
        
        let shrunkVersions = generateShrinkLevels(for: taskTitle)
        return shrunkVersions
    }
    
    // MARK: - Private Helpers
    
    private func generateTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let goalLower = goal.lowercased()
        
        // Pattern matching for common goal types
        if goalLower.contains("paper") || goalLower.contains("essay") || goalLower.contains("write") {
            return writingTaskTemplates(for: goal, energy: energy)
        } else if goalLower.contains("study") || goalLower.contains("learn") || goalLower.contains("read") {
            return studyTaskTemplates(for: goal, energy: energy)
        } else if goalLower.contains("clean") || goalLower.contains("organize") || goalLower.contains("tidy") {
            return organizingTaskTemplates(for: goal, energy: energy)
        } else if goalLower.contains("project") || goalLower.contains("work") || goalLower.contains("task") {
            return projectTaskTemplates(for: goal, energy: energy)
        } else if goalLower.contains("exercise") || goalLower.contains("workout") || goalLower.contains("run") {
            return exerciseTaskTemplates(for: goal, energy: energy)
        } else {
            return genericTaskTemplates(for: goal, energy: energy)
        }
    }
    
    private func writingTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        
        return [
            TaskTemplate(
                title: "Research 3 sources for your writing",
                estimatedMinutes: Int(Double(baseMinutes) * 0.8),
                difficulty: .medium,
                shrunkVersions: [
                    "Find 1 good source",
                    "Open a search page and look for sources",
                    "Open your browser"
                ]
            ),
            TaskTemplate(
                title: "Write an outline with main points",
                estimatedMinutes: baseMinutes,
                difficulty: energy == .low ? .small : .medium,
                shrunkVersions: [
                    "Write 3 bullet points for the outline",
                    "Write 1 main idea",
                    "Open your document"
                ]
            ),
            TaskTemplate(
                title: "Draft the introduction section",
                estimatedMinutes: Int(Double(baseMinutes) * 1.2),
                difficulty: .medium,
                shrunkVersions: [
                    "Write the opening sentence",
                    "Write a rough thesis statement",
                    "Type anything to start"
                ]
            ),
            TaskTemplate(
                title: "Draft the main body",
                estimatedMinutes: Int(Double(baseMinutes) * 1.5),
                difficulty: .large,
                shrunkVersions: [
                    "Write one paragraph",
                    "Write 3 sentences",
                    "Write the first sentence"
                ]
            ),
            TaskTemplate(
                title: "Edit and polish your writing",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "Read through once and note issues",
                    "Fix one section",
                    "Read the first paragraph"
                ]
            )
        ]
    }
    
    private func studyTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        let topic = extractTopic(from: goal)
        
        return [
            TaskTemplate(
                title: "Gather your \(topic) materials",
                estimatedMinutes: 10,
                difficulty: .small,
                shrunkVersions: [
                    "Open your notes app",
                    "Find your textbook",
                    "Sit at your desk"
                ]
            ),
            TaskTemplate(
                title: "Review the key concepts",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "Read through one section",
                    "Read the summary/highlights",
                    "Open your notes"
                ]
            ),
            TaskTemplate(
                title: "Take notes on important points",
                estimatedMinutes: Int(Double(baseMinutes) * 0.8),
                difficulty: .medium,
                shrunkVersions: [
                    "Write down 3 key points",
                    "Write 1 thing you learned",
                    "Write a title for your notes"
                ]
            ),
            TaskTemplate(
                title: "Practice with examples or problems",
                estimatedMinutes: baseMinutes,
                difficulty: energy == .high ? .large : .medium,
                shrunkVersions: [
                    "Try one practice problem",
                    "Read through one example",
                    "Look at the practice section"
                ]
            ),
            TaskTemplate(
                title: "Review and summarize what you learned",
                estimatedMinutes: 15,
                difficulty: .small,
                shrunkVersions: [
                    "Write a 3-sentence summary",
                    "Say out loud what you remember",
                    "Close your eyes and recall one thing"
                ]
            )
        ]
    }
    
    private func organizingTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        
        return [
            TaskTemplate(
                title: "Clear visible clutter first",
                estimatedMinutes: 15,
                difficulty: .small,
                shrunkVersions: [
                    "Pick up 5 items",
                    "Pick up 1 item",
                    "Stand up and look around"
                ]
            ),
            TaskTemplate(
                title: "Sort items into categories",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "Create 3 piles: keep, toss, unsure",
                    "Sort one type of item",
                    "Pick up one item and decide"
                ]
            ),
            TaskTemplate(
                title: "Find homes for sorted items",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "Put away 5 items",
                    "Put away 1 item",
                    "Open a drawer or closet"
                ]
            ),
            TaskTemplate(
                title: "Final tidying and cleaning",
                estimatedMinutes: 15,
                difficulty: .small,
                shrunkVersions: [
                    "Wipe down one surface",
                    "Straighten one area",
                    "Take a look at your progress"
                ]
            )
        ]
    }
    
    private func projectTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        
        return [
            TaskTemplate(
                title: "Define the project scope and goals",
                estimatedMinutes: Int(Double(baseMinutes) * 0.7),
                difficulty: .medium,
                shrunkVersions: [
                    "Write down the main objective",
                    "Ask yourself: what does done look like?",
                    "Open a note to plan"
                ]
            ),
            TaskTemplate(
                title: "Break down into smaller steps",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "List 3 main steps",
                    "Write down the first step",
                    "Think about where to start"
                ]
            ),
            TaskTemplate(
                title: "Start on the first actionable item",
                estimatedMinutes: baseMinutes,
                difficulty: energy == .low ? .small : .medium,
                shrunkVersions: [
                    "Work for 10 minutes",
                    "Work for 5 minutes",
                    "Open the project files"
                ]
            ),
            TaskTemplate(
                title: "Continue working and track progress",
                estimatedMinutes: Int(Double(baseMinutes) * 1.3),
                difficulty: .large,
                shrunkVersions: [
                    "Complete one sub-task",
                    "Make any progress",
                    "Review where you left off"
                ]
            ),
            TaskTemplate(
                title: "Review and plan next steps",
                estimatedMinutes: 15,
                difficulty: .small,
                shrunkVersions: [
                    "Note what's left to do",
                    "Write tomorrow's first task",
                    "Save your work"
                ]
            )
        ]
    }
    
    private func exerciseTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        
        return [
            TaskTemplate(
                title: "Get ready and change clothes",
                estimatedMinutes: 10,
                difficulty: .micro,
                shrunkVersions: [
                    "Put on workout clothes",
                    "Find your workout clothes",
                    "Stand up"
                ]
            ),
            TaskTemplate(
                title: "Warm up your body",
                estimatedMinutes: 10,
                difficulty: .small,
                shrunkVersions: [
                    "Do 5 minutes of stretching",
                    "Do 2 minutes of movement",
                    "Move your arms and legs"
                ]
            ),
            TaskTemplate(
                title: "Main workout session",
                estimatedMinutes: baseMinutes,
                difficulty: energy == .low ? .medium : .large,
                shrunkVersions: [
                    "Exercise for 15 minutes",
                    "Exercise for 5 minutes",
                    "Do 10 reps of anything"
                ]
            ),
            TaskTemplate(
                title: "Cool down and stretch",
                estimatedMinutes: 10,
                difficulty: .micro,
                shrunkVersions: [
                    "Stretch for 3 minutes",
                    "Take 5 deep breaths",
                    "Sit down and rest"
                ]
            )
        ]
    }
    
    private func genericTaskTemplates(for goal: String, energy: EnergyLevel) -> [TaskTemplate] {
        let baseMinutes = energy.maxEstimatedMinutes
        
        return [
            TaskTemplate(
                title: "Plan how to approach \(goal.lowercased())",
                estimatedMinutes: 15,
                difficulty: .small,
                shrunkVersions: [
                    "Write down 3 steps",
                    "Think about the first step",
                    "Open a note"
                ]
            ),
            TaskTemplate(
                title: "Start working on \(goal.lowercased())",
                estimatedMinutes: baseMinutes,
                difficulty: .medium,
                shrunkVersions: [
                    "Work for 15 minutes",
                    "Work for 5 minutes",
                    "Take any small action"
                ]
            ),
            TaskTemplate(
                title: "Continue making progress",
                estimatedMinutes: baseMinutes,
                difficulty: energy == .low ? .small : .medium,
                shrunkVersions: [
                    "Complete one part",
                    "Make any progress",
                    "Review what you've done"
                ]
            ),
            TaskTemplate(
                title: "Wrap up and note next steps",
                estimatedMinutes: 10,
                difficulty: .micro,
                shrunkVersions: [
                    "Write what's next",
                    "Save your progress",
                    "Take a breath"
                ]
            )
        ]
    }
    
    private func generateShrinkLevels(for taskTitle: String) -> [String] {
        let title = taskTitle.lowercased()
        
        // Default shrinking pattern
        if title.contains("write") {
            return [
                "Write 3 sentences",
                "Write 1 sentence",
                "Open your document"
            ]
        } else if title.contains("read") || title.contains("review") {
            return [
                "Read for 5 minutes",
                "Read 1 page",
                "Open the material"
            ]
        } else if title.contains("research") || title.contains("find") {
            return [
                "Find 1 source",
                "Do a quick search",
                "Open your browser"
            ]
        } else if title.contains("clean") || title.contains("organize") {
            return [
                "Clean one area",
                "Pick up 3 items",
                "Stand up and look around"
            ]
        } else {
            return [
                "Work for 5 minutes",
                "Take one small action",
                "Start anywhere"
            ]
        }
    }
    
    private func extractTopic(from goal: String) -> String {
        let words = goal.lowercased()
            .replacingOccurrences(of: "study", with: "")
            .replacingOccurrences(of: "learn", with: "")
            .replacingOccurrences(of: "read", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        return words.isEmpty ? "study" : words
    }
}

// MARK: - Task Template
/// Template for generating tasks from goals
struct TaskTemplate {
    let title: String
    let estimatedMinutes: Int
    let difficulty: DifficultyLevel
    let shrunkVersions: [String]
    
    func toTask(goalId: UUID) -> NextTask {
        return NextTask(
            goalId: goalId,
            title: title,
            estimatedMinutes: estimatedMinutes,
            difficultyLevel: difficulty,
            shrunkVersions: shrunkVersions
        )
    }
}
