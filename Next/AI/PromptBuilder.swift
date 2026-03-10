import Foundation

// MARK: - Prompt Builder
/// Builds structured prompts for the Sage AI API.
/// Ensures consistent prompt formatting and context management.
struct PromptBuilder {
    
    // MARK: - System Prompt
    
    /// The core system prompt that defines Sage's personality
    static let systemPrompt = """
    You are Sage, a calm and supportive AI assistant inside the Next app.
    
    Your purpose is to help users overcome overwhelm and accomplish their goals one small step at a time.
    
    Core principles:
    - Break large goals into small, achievable tasks (10-40 minutes each)
    - Present only ONE task at a time
    - Use a calm, encouraging, conversational tone
    - If the user seems overwhelmed, make tasks even smaller
    - Celebrate small wins genuinely
    - Never be preachy or lecture the user
    - Keep responses concise and focused
    
    Response style:
    - Speak naturally, as a supportive friend would
    - Keep responses brief (1-3 sentences for most interactions)
    - Use simple, clear language
    - Avoid productivity jargon or buzzwords
    
    When decomposing goals:
    - Start with the smallest possible first step
    - Make the first task something the user can start immediately
    - Consider the user's stated energy level
    - If uncertain, ask one clarifying question
    
    Always respond in the structured JSON format specified.
    """
    
    // MARK: - Build Methods
    
    /// Builds a prompt for goal decomposition
    static func buildGoalDecompositionPrompt(
        goal: String,
        energyLevel: EnergyLevel,
        context: [ConversationMessage] = []
    ) -> [PromptMessage] {
        var messages: [PromptMessage] = [
            PromptMessage(role: "system", content: systemPrompt)
        ]
        
        // Add conversation context
        for message in context.suffix(4) {
            let role = message.role == .user ? "user" : "assistant"
            messages.append(PromptMessage(role: role, content: message.content))
        }
        
        // Build the user request
        let userContent = """
        The user wants to: "\(goal)"
        
        Their current energy level is: \(energyLevel.displayName)
        This means tasks should be \(energyLevel.contextDescription).
        
        Please break this goal into 3-5 small, actionable tasks. Respond with a JSON object in this exact format:
        {
            "intro_message": "A brief, encouraging message about helping with this goal (1-2 sentences)",
            "tasks": [
                {
                    "title": "Short, clear task title",
                    "description": "Optional brief description",
                    "estimated_minutes": 15
                }
            ],
            "first_task_message": "What you would say to introduce the first task (1-2 sentences)"
        }
        """
        
        messages.append(PromptMessage(role: "user", content: userContent))
        
        return messages
    }
    
    /// Builds a prompt for task completion response
    static func buildTaskCompletionPrompt(
        completedTask: SageTask,
        nextTask: SageTask?,
        goal: Goal
    ) -> [PromptMessage] {
        var messages: [PromptMessage] = [
            PromptMessage(role: "system", content: systemPrompt)
        ]
        
        let hasNextTask = nextTask != nil
        let progressPercent = Int(goal.progress * 100)
        
        let userContent = """
        The user just completed the task: "\(completedTask.title)"
        
        Goal: "\(goal.title)"
        Progress: \(progressPercent)% (\(goal.completedTaskCount)/\(goal.totalTaskCount) tasks done)
        \(hasNextTask ? "Next task: \"\(nextTask!.title)\"" : "This was the final task! The goal is complete!")
        
        Respond with a JSON object:
        {
            "completion_message": "Brief celebration of completing this task (1 sentence)",
            \(hasNextTask ? "\"transition_message\": \"Brief intro to the next task (1 sentence)\"" : "\"celebration_message\": \"Celebrate completing the entire goal! (2-3 sentences)\"")
        }
        """
        
        messages.append(PromptMessage(role: "user", content: userContent))
        
        return messages
    }
    
    /// Builds a prompt for resistance/overwhelm handling
    static func buildResistancePrompt(
        currentTask: SageTask,
        userMessage: String
    ) -> [PromptMessage] {
        var messages: [PromptMessage] = [
            PromptMessage(role: "system", content: systemPrompt)
        ]
        
        let userContent = """
        Current task: "\(currentTask.title)"
        User said: "\(userMessage)"
        
        The user seems resistant or overwhelmed. Suggest a smaller version of this task.
        
        Respond with a JSON object:
        {
            "empathy_message": "Brief acknowledgment of their feeling (1 sentence)",
            "smaller_task": {
                "title": "Even smaller version of the task",
                "description": "Optional brief description",
                "estimated_minutes": 5
            },
            "encouragement": "Brief encouragement (1 sentence)"
        }
        """
        
        messages.append(PromptMessage(role: "user", content: userContent))
        
        return messages
    }
    
    /// Builds a generic conversation prompt
    static func buildConversationPrompt(
        userMessage: String,
        context: [ConversationMessage],
        currentGoal: Goal?
    ) -> [PromptMessage] {
        var messages: [PromptMessage] = [
            PromptMessage(role: "system", content: systemPrompt)
        ]
        
        // Add context
        for message in context.suffix(6) {
            let role = message.role == .user ? "user" : "assistant"
            messages.append(PromptMessage(role: role, content: message.content))
        }
        
        var contextInfo = ""
        if let goal = currentGoal {
            contextInfo = "\nCurrent goal: \"\(goal.title)\" (Progress: \(Int(goal.progress * 100))%)"
            if let task = goal.currentTask {
                contextInfo += "\nCurrent task: \"\(task.title)\""
            }
        }
        
        let userContent = """
        User message: "\(userMessage)"
        \(contextInfo)
        
        Respond naturally and briefly. If they need help with a goal, offer your assistance.
        
        Respond with a JSON object:
        {
            "message": "Your response (1-3 sentences)",
            "action": "none" | "new_goal" | "complete_task" | "skip_task" | "make_smaller"
        }
        """
        
        messages.append(PromptMessage(role: "user", content: userContent))
        
        return messages
    }
}

// MARK: - Prompt Message

struct PromptMessage: Codable {
    let role: String
    let content: String
}
