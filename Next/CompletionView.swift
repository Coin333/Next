import SwiftUI

// MARK: - Completion View
/// Shown after completing a task - celebrates and encourages momentum
struct CompletionView: View {
    
    @EnvironmentObject var state: NextState
    @State private var animationScale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xxLarge) {
            Spacer()
            
            // Completion indicator
            completionIcon
            
            // Message
            completionMessage
            
            Spacer()
            
            // Stats (subtle)
            statsSection
            
            // Next Step Button
            nextButton
            
            Spacer()
                .frame(height: Theme.Spacing.xLarge)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                animationScale = 1.0
                opacity = 1.0
            }
        }
    }
    
    // MARK: - Completion Icon
    
    private var completionIcon: some View {
        ZStack {
            Circle()
                .fill(Theme.Colors.accent.opacity(0.2))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(Theme.Colors.accent.opacity(0.3))
                .frame(width: 80, height: 80)
            
            Image(systemName: "checkmark")
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(Theme.Colors.accent)
        }
        .scaleEffect(animationScale)
        .opacity(opacity)
    }
    
    // MARK: - Completion Message
    
    private var completionMessage: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("Nice.")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text("That moved you forward.")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .opacity(opacity)
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            let completed = state.completedTasksCount
            if completed > 1 {
                Text("\(completed) tasks completed today")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.7))
            }
        }
        .opacity(opacity)
    }
    
    // MARK: - Next Button
    
    private var nextButton: some View {
        VStack(spacing: Theme.Spacing.medium) {
            if state.hasPendingTasks {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state.moveToNextTask()
                    }
                }) {
                    Text("Next Step")
                        .primaryButton()
                }
            } else {
                Button(action: {
                    state.showGoalInput()
                }) {
                    Text("Add New Goal")
                        .primaryButton()
                }
                
                Button(action: {
                    state.moveToNextTask()
                }) {
                    Text("Done for now")
                        .tertiaryButton()
                }
            }
        }
        .opacity(opacity)
    }
}

// MARK: - Preview
#Preview {
    CompletionView()
        .environmentObject(NextState())
}
