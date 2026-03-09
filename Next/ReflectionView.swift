import SwiftUI

// MARK: - Reflection View
/// Evening reflection view (Feature 7)
/// Shows daily summary and asks about tomorrow
struct ReflectionView: View {
    
    @EnvironmentObject var state: NextState
    @State private var tomorrowGoal: String = ""
    @State private var animationOffset: CGFloat = 40
    @State private var opacity: Double = 0
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Summary Section
            summarySection
            
            Spacer()
                .frame(height: Theme.Spacing.xxLarge)
            
            // Tomorrow Section
            tomorrowSection
            
            Spacer()
            
            // Done Button
            doneButton
            
            Spacer()
                .frame(height: Theme.Spacing.xLarge)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                animationOffset = 0
                opacity = 1
            }
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.Colors.accent)
            
            // Daily summary
            let summary = state.getDailySummary()
            
            Text(summary.message)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            Text(summary.encouragement)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .offset(y: animationOffset)
        .opacity(opacity)
    }
    
    // MARK: - Tomorrow Section
    
    private var tomorrowSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text("Anything urgent for tomorrow?")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
            
            TextField("", text: $tomorrowGoal, prompt: Text("Optional: add a goal for tomorrow")
                .foregroundColor(Theme.Colors.secondaryText.opacity(0.5)))
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.primaryText)
                .multilineTextAlignment(.center)
                .padding(Theme.Spacing.medium)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                .focused($isInputFocused)
                .submitLabel(.done)
                .onSubmit {
                    isInputFocused = false
                }
        }
        .offset(y: animationOffset * 0.5)
        .opacity(opacity)
    }
    
    // MARK: - Done Button
    
    private var doneButton: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Button(action: {
                isInputFocused = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    state.finishReflection(tomorrowGoal: tomorrowGoal.isEmpty ? nil : tomorrowGoal)
                }
            }) {
                Text("Done for today")
                    .primaryButton()
            }
            
            // Skip option
            if tomorrowGoal.isEmpty {
                Button(action: {
                    state.finishReflection(tomorrowGoal: nil)
                }) {
                    Text("Skip")
                        .tertiaryButton()
                }
            }
        }
        .opacity(opacity)
    }
}

// MARK: - Preview
#Preview {
    ReflectionView()
        .environmentObject(NextState())
}
