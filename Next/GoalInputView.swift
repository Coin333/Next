import SwiftUI

// MARK: - Goal Input View
/// View for adding new goals via text or voice (Feature 1)
struct GoalInputView: View {
    
    @EnvironmentObject var state: NextState
    @StateObject private var voiceService = VoiceInputService()
    @FocusState private var isTextFieldFocused: Bool
    @State private var animationOffset: CGFloat = 30
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                headerSection
                
                Spacer()
                
                // Main content
                inputSection
                
                Spacer()
                
                // Submit button
                if !state.goalInputText.isEmpty {
                    submitButton
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                    .frame(height: Theme.Spacing.xLarge)
            }
            .padding(.horizontal, Theme.Spacing.large)
            
            // Loading overlay
            if state.isProcessingGoal {
                processingOverlay
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                animationOffset = 0
                opacity = 1
            }
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .onChange(of: voiceService.transcribedText) { oldValue, newValue in
            if !newValue.isEmpty {
                state.goalInputText = newValue
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                voiceService.stopListening()
                state.hideGoalInput()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Theme.Colors.secondaryText)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
        }
        .padding(.top, Theme.Spacing.medium)
    }
    
    // MARK: - Input Section
    
    private var inputSection: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Prompt
            VStack(spacing: Theme.Spacing.small) {
                Text("What do you want")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("to accomplish?")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.accent)
            }
            .offset(y: animationOffset)
            .opacity(opacity)
            
            // Text Input with Voice Button
            HStack(spacing: Theme.Spacing.small) {
                TextField("", text: $state.goalInputText, prompt: Text("e.g., Write my history paper")
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.5)))
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                    .padding(Theme.Spacing.medium)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if !state.goalInputText.isEmpty {
                            submitGoal()
                        }
                    }
                
                // Voice Input Button
                if voiceService.isAuthorized {
                    voiceButton
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .offset(y: animationOffset * 0.5)
            .opacity(opacity)
            
            // Helper text or listening indicator
            if voiceService.isListening {
                listeningIndicator
            } else {
                Text("Sage will break this down into achievable steps")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText.opacity(0.7))
                    .offset(y: animationOffset * 0.3)
                    .opacity(opacity)
            }
        }
    }
    
    // MARK: - Voice Button
    
    private var voiceButton: some View {
        Button(action: {
            isTextFieldFocused = false
            voiceService.toggleListening()
        }) {
            ZStack {
                Circle()
                    .fill(voiceService.isListening ? Theme.Colors.accent : Theme.Colors.cardBackground)
                    .frame(width: 44, height: 44)
                
                Image(systemName: voiceService.isListening ? "mic.fill" : "mic")
                    .font(.system(size: 18))
                    .foregroundColor(voiceService.isListening ? Theme.Colors.background : Theme.Colors.accent)
            }
        }
        .padding(.trailing, Theme.Spacing.xSmall)
    }
    
    // MARK: - Listening Indicator
    
    private var listeningIndicator: some View {
        HStack(spacing: Theme.Spacing.small) {
            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: 8, height: 8)
                .opacity(0.8)
            
            Text("Listening...")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.accent)
        }
        .padding(.vertical, Theme.Spacing.small)
    }
    
    // MARK: - Submit Button
    
    private var submitButton: some View {
        Button(action: submitGoal) {
            HStack {
                Text("Let Sage plan this")
                Image(systemName: "sparkles")
            }
            .primaryButton()
        }
    }
    
    // MARK: - Processing Overlay
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.medium) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.accent))
                    .scaleEffect(1.5)
                
                Text("Sage is thinking...")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .padding(Theme.Spacing.xLarge)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
        }
    }
    
    // MARK: - Actions
    
    private func submitGoal() {
        isTextFieldFocused = false
        state.submitGoal()
    }
}

// MARK: - Preview
#Preview {
    GoalInputView()
        .environmentObject(NextState())
}
