import SwiftUI

// MARK: - Empty State View
/// Shown when there are no pending tasks
/// Encourages user to add a new goal
struct EmptyStateView: View {
    
    @EnvironmentObject var state: NextState
    @State private var animationOffset: CGFloat = 30
    @State private var opacity: Double = 0
    @State private var iconRotation: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Main content
            emptyContent
            
            Spacer()
            
            // Add Goal Button
            addGoalButton
            
            Spacer()
                .frame(height: Theme.Spacing.xLarge)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animationOffset = 0
                opacity = 1
            }
            // Subtle icon animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                iconRotation = 5
            }
        }
    }
    
    // MARK: - Empty Content
    
    private var emptyContent: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 50))
                    .foregroundColor(Theme.Colors.accent)
                    .rotationEffect(.degrees(iconRotation))
            }
            
            // Message
            VStack(spacing: Theme.Spacing.medium) {
                Text("All clear")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("You have no pending tasks.\nReady to start something new?")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Completed stats (if any)
            if state.completedTasksCount > 0 {
                completedStats
            }
        }
        .offset(y: animationOffset)
        .opacity(opacity)
    }
    
    // MARK: - Completed Stats
    
    private var completedStats: some View {
        HStack(spacing: Theme.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.Colors.accent)
            
            Text("\(state.completedTasksCount) completed today")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.pill)
    }
    
    // MARK: - Add Goal Button
    
    private var addGoalButton: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button(action: {
                state.showGoalInput()
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Add a Goal")
                }
                .primaryButton()
            }
            
            Text("Tell Sage what you want to accomplish")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText.opacity(0.7))
        }
        .opacity(opacity)
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView()
        .environmentObject(NextState())
}
