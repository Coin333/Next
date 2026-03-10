import XCTest
@testable import Next

// MARK: - Task Tests
final class TaskTests: XCTestCase {
    
    func testTaskCreation() {
        let task = SageTask(
            title: "Test Task",
            description: "A test description",
            estimatedMinutes: 20
        )
        
        XCTAssertEqual(task.title, "Test Task")
        XCTAssertEqual(task.description, "A test description")
        XCTAssertEqual(task.estimatedMinutes, 20)
        XCTAssertEqual(task.status, .pending)
        XCTAssertTrue(task.isActionable)
    }
    
    func testTaskTimeEstimateClamping() {
        // Test minimum clamping
        let shortTask = SageTask(title: "Short", estimatedMinutes: 1)
        XCTAssertEqual(shortTask.estimatedMinutes, 5)
        
        // Test maximum clamping
        let longTask = SageTask(title: "Long", estimatedMinutes: 120)
        XCTAssertEqual(longTask.estimatedMinutes, 60)
    }
    
    func testTaskCompletion() {
        var task = SageTask(title: "Test")
        
        XCTAssertNil(task.completedAt)
        XCTAssertEqual(task.status, .pending)
        
        task.complete()
        
        XCTAssertNotNil(task.completedAt)
        XCTAssertEqual(task.status, .completed)
        XCTAssertFalse(task.isActionable)
    }
    
    func testTaskSkip() {
        var task = SageTask(title: "Test")
        
        task.skip()
        
        XCTAssertEqual(task.status, .skipped)
        XCTAssertFalse(task.isActionable)
    }
}

// MARK: - Goal Tests
final class GoalTests: XCTestCase {
    
    func testGoalCreation() {
        let goal = Goal(title: "Test Goal")
        
        XCTAssertEqual(goal.title, "Test Goal")
        XCTAssertEqual(goal.status, .active)
        XCTAssertTrue(goal.tasks.isEmpty)
        XCTAssertEqual(goal.progress, 0)
    }
    
    func testGoalProgress() {
        var goal = Goal(title: "Test Goal")
        
        // Add tasks
        goal.addTask(SageTask(title: "Task 1"))
        goal.addTask(SageTask(title: "Task 2"))
        goal.addTask(SageTask(title: "Task 3"))
        
        XCTAssertEqual(goal.totalTaskCount, 3)
        XCTAssertEqual(goal.completedTaskCount, 0)
        XCTAssertEqual(goal.progress, 0)
        
        // Complete first task
        _ = goal.completeCurrentTask()
        
        XCTAssertEqual(goal.completedTaskCount, 1)
        XCTAssertEqual(goal.progress, 1.0/3.0, accuracy: 0.01)
    }
    
    func testGoalCompletion() {
        var goal = Goal(title: "Test Goal")
        goal.addTask(SageTask(title: "Only Task"))
        
        XCTAssertFalse(goal.isComplete)
        
        _ = goal.completeCurrentTask()
        
        XCTAssertTrue(goal.isComplete)
        XCTAssertEqual(goal.status, .completed)
    }
}

// MARK: - Response Parser Tests
final class ResponseParserTests: XCTestCase {
    
    func testGoalDecompositionParsing() throws {
        let json = """
        {
            "intro_message": "Let's break this down!",
            "tasks": [
                {
                    "title": "First step",
                    "description": "Do this first",
                    "estimated_minutes": 15
                },
                {
                    "title": "Second step",
                    "estimated_minutes": 20
                }
            ],
            "first_task_message": "Start with the first step."
        }
        """
        
        let response = try ResponseParser.parseGoalDecomposition(from: json)
        
        XCTAssertEqual(response.introMessage, "Let's break this down!")
        XCTAssertEqual(response.tasks.count, 2)
        XCTAssertEqual(response.tasks[0].title, "First step")
        XCTAssertEqual(response.tasks[0].estimatedMinutes, 15)
        XCTAssertEqual(response.firstTaskMessage, "Start with the first step.")
    }
    
    func testTaskCompletionParsing() throws {
        let json = """
        {
            "completion_message": "Great job!",
            "transition_message": "Now let's do the next thing."
        }
        """
        
        let response = try ResponseParser.parseTaskCompletion(from: json)
        
        XCTAssertEqual(response.completionMessage, "Great job!")
        XCTAssertEqual(response.transitionMessage, "Now let's do the next thing.")
        XCTAssertNil(response.celebrationMessage)
    }
    
    func testJSONExtraction() {
        let messyResponse = "Here's the response: {\"message\": \"Hello\"} end"
        
        let extracted = ResponseParser.extractJSON(from: messyResponse)
        
        XCTAssertNotNil(extracted)
        XCTAssertEqual(extracted, "{\"message\": \"Hello\"}")
    }
    
    func testInvalidJSONHandling() {
        let invalidJSON = "not json at all"
        
        XCTAssertThrowsError(try ResponseParser.parseGoalDecomposition(from: invalidJSON))
    }
}

// MARK: - Conversation State Tests
final class ConversationStateTests: XCTestCase {
    
    func testMessageHistory() {
        var state = ConversationState()
        
        XCTAssertTrue(state.history.isEmpty)
        
        state.addUserMessage("Hello")
        state.addSageMessage("Hi there!")
        
        XCTAssertEqual(state.history.count, 2)
        XCTAssertEqual(state.history[0].role, .user)
        XCTAssertEqual(state.history[1].role, .sage)
    }
    
    func testHistoryLimiting() {
        var state = ConversationState()
        
        // Add more than 20 messages
        for i in 0..<25 {
            state.addUserMessage("Message \(i)")
        }
        
        // Should be capped at 20
        XCTAssertEqual(state.history.count, 20)
    }
    
    func testReset() {
        var state = ConversationState()
        state.phase = .listening
        state.addUserMessage("Test")
        state.activeGoalId = UUID()
        
        state.reset()
        
        XCTAssertEqual(state.phase, .idle)
        XCTAssertTrue(state.history.isEmpty)
        XCTAssertNil(state.activeGoalId)
    }
}

// MARK: - Energy Level Tests
final class EnergyLevelTests: XCTestCase {
    
    func testTaskTimeRanges() {
        XCTAssertEqual(EnergyLevel.low.taskTimeRange, 5...15)
        XCTAssertEqual(EnergyLevel.medium.taskTimeRange, 10...25)
        XCTAssertEqual(EnergyLevel.high.taskTimeRange, 15...40)
    }
}
