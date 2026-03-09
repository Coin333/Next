import SwiftUI

// MARK: - Content View
/// Main container view that handles navigation between screens
struct ContentView: View {
    
    @EnvironmentObject var state: NextState
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()
            
            // Main content based on current screen
            screenContent
                .animation(.easeInOut(duration: 0.3), value: state.currentScreen)
        }
        .sheet(isPresented: $state.showingGoalInput) {
            GoalInputView()
                .environmentObject(state)
        }
    }
    
    @ViewBuilder
    private var screenContent: some View {
        switch state.currentScreen {
        case .energyCheck:
            EnergyCheckView()
                .transition(.opacity)
            
        case .taskView:
            TaskView()
                .transition(.opacity)
            
        case .completion:
            CompletionView()
                .transition(.scale.combined(with: .opacity))
            
        case .goalInput:
            GoalInputView()
                .transition(.opacity)
            
        case .reflection:
            ReflectionView()
                .transition(.opacity)
            
        case .empty:
            EmptyStateView()
                .transition(.opacity)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(NextState())
}
