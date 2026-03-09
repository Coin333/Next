import SwiftUI

// MARK: - Task View
/// Main task display view showing the current "Next" task
/// Following design: Minimal, Dark, Calm, No distractions
struct TaskView: View {
    
    @EnvironmentObject var state: NextState
    @State private var showingStartConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Header
            headerSection
            
            Spacer()
                .frame(height: Theme.Spacing.xxLarge)
            
            // Task Card
            taskCard
            
            Spacer()
            
            // Action Buttons
            actionButtons
            
            Spacer()
                .frame(height: Theme.Spacing.xLarge)
        }
        .padding(.horizontal, Theme.Spacing.large)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            Text("NEXT")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.accent)
                .tracking(4)
        }
    }
    
    // MARK: - Task Card
    
    private var taskCard: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Shrink indicator (if shrunk)
            if let task = state.currentTask, task.shrinkLevel > 0 {
                HStack {
                    ForEach(0..<task.shrinkLevel, id: \.self) { _ in
                        Circle()
                            .fill(Theme.Colors.accent.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, Theme.Spacing.xSmall)
            }
            
            // Task Title
            Text(state.currentTask?.currentTitle ?? "No task")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
            
            // Estimated Time
            if let task = state.currentTask {
                Text("Estimated: \(task.formattedTime)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
        }
        .padding(Theme.Spacing.xLarge)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Primary Action - Start/Done
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    state.completeCurrentTask()
                }
            }) {
                Text("Done")
                    .primaryButton()
            }
            
            // Secondary Actions
            HStack(spacing: Theme.Spacing.medium) {
                // Not Now
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        state.shrinkCurrentTask()
                    }
                }) {
                    Text("Not Now")
                        .secondaryButton()
                }
                
                // Too Big
                if state.currentTask?.canShrink == true {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            state.taskTooBig()
                        }
                    }) {
                        Text("Too Big")
                            .secondaryButton()
                    }
                }
            }
            
            // Skip option (subtle)
            Button(action: {
                state.skipCurrentTask()
            }) {
                Text("Skip this task")
                    .tertiaryButton()
            }
            .padding(.top, Theme.Spacing.small)
        }
    }
}

// MARK: - Preview
#Preview {
    let state = NextState()
    state.currentTask = NextTask(
        goalId: UUID(),
        title: "Write 3 bullet points for your essay",
        estimatedMinutes: 20,
        shrunkVersions: ["Write 1 bullet point", "Open your document"]
    )
    state.currentScreen = .taskView
    
    return TaskView()
        .environmentObject(state)
}
