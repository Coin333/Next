import SwiftUI

// MARK: - Energy Check View
/// Daily energy check prompt (Feature 6)
/// "How's your energy today?" - Low, Medium, High
struct EnergyCheckView: View {
    
    @EnvironmentObject var state: NextState
    @State private var selectedLevel: EnergyLevel?
    @State private var animationOffset: CGFloat = 50
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Greeting
            greetingSection
            
            Spacer()
                .frame(height: Theme.Spacing.xxLarge)
            
            // Energy Options
            energyOptions
            
            Spacer()
            
            // Continue Button
            if selectedLevel != nil {
                continueButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            Spacer()
                .frame(height: Theme.Spacing.xLarge)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                animationOffset = 0
                opacity = 1
            }
        }
    }
    
    // MARK: - Greeting Section
    
    private var greetingSection: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Text(greetingText)
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text("How's your energy today?")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .offset(y: animationOffset)
        .opacity(opacity)
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good morning"
        } else if hour < 17 {
            return "Good afternoon"
        } else {
            return "Good evening"
        }
    }
    
    // MARK: - Energy Options
    
    private var energyOptions: some View {
        VStack(spacing: Theme.Spacing.medium) {
            ForEach(EnergyLevel.allCases, id: \.self) { level in
                EnergyOptionButton(
                    level: level,
                    isSelected: selectedLevel == level,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedLevel = level
                        }
                    }
                )
            }
        }
        .offset(y: animationOffset * 0.5)
        .opacity(opacity)
    }
    
    // MARK: - Continue Button
    
    private var continueButton: some View {
        Button(action: {
            if let level = selectedLevel {
                withAnimation(.easeInOut(duration: 0.3)) {
                    state.setEnergyLevel(level)
                }
            }
        }) {
            Text("Continue")
                .primaryButton()
        }
        .padding(.horizontal, Theme.Spacing.large)
    }
}

// MARK: - Energy Option Button

struct EnergyOptionButton: View {
    let level: EnergyLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                // Icon
                Image(systemName: level.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Theme.Colors.background : Theme.Colors.accent)
                    .frame(width: 40)
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(Theme.Typography.button)
                        .foregroundColor(isSelected ? Theme.Colors.background : Theme.Colors.primaryText)
                    
                    Text(level.description)
                        .font(Theme.Typography.caption)
                        .foregroundColor(isSelected ? Theme.Colors.background.opacity(0.7) : Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.Colors.background)
                }
            }
            .padding(Theme.Spacing.medium)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Theme.Colors.accent : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    EnergyCheckView()
        .environmentObject(NextState())
}
