import SwiftUI

// MARK: - Voice View
/// Full-screen voice interaction view.
/// Shows when actively listening or Sage is speaking.
struct VoiceView: View {
    
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Visual feedback
                visualFeedback
                
                // State indicator
                stateLabel
                
                // Transcription
                if !viewModel.transcribedText.isEmpty {
                    transcriptionView
                }
                
                Spacer()
                
                // Action buttons
                actionButtons
            }
            .padding(32)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Visual Feedback
    
    private var visualFeedback: some View {
        ZStack {
            // Outer pulsing rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 2)
                    .frame(width: 160 + CGFloat(index * 40), height: 160 + CGFloat(index * 40))
                    .scaleEffect(viewModel.voiceState == .listening ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: viewModel.voiceState
                    )
            }
            
            // Audio level ring
            if viewModel.voiceState == .listening {
                Circle()
                    .stroke(Theme.Colors.accent, lineWidth: 4)
                    .frame(width: 150, height: 150)
                    .scaleEffect(1.0 + CGFloat(viewModel.audioLevel) * 0.2)
                    .animation(.easeOut(duration: 0.05), value: viewModel.audioLevel)
            }
            
            // Center circle
            Circle()
                .fill(centerColor)
                .frame(width: 120, height: 120)
                .shadow(color: centerColor.opacity(0.5), radius: 16)
            
            // Icon
            Image(systemName: centerIcon)
                .font(.system(size: 40, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var centerColor: Color {
        switch viewModel.voiceState {
        case .idle: return .accent
        case .listening: return .red
        case .processing: return .orange
        case .speaking: return .accent
        }
    }
    
    private var centerIcon: String {
        switch viewModel.voiceState {
        case .idle: return "mic"
        case .listening: return "mic.fill"
        case .processing: return "ellipsis"
        case .speaking: return "speaker.wave.2.fill"
        }
    }
    
    // MARK: - State Label
    
    private var stateLabel: some View {
        Text(viewModel.voiceState.description)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.primary)
    }
    
    // MARK: - Transcription
    
    private var transcriptionView: some View {
        Text(viewModel.transcribedText)
            .font(.body)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .transition(.opacity)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 40) {
            // Cancel button
            Button(action: { dismiss() }) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24))
                    Text("Cancel")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            
            // Main action button
            Button(action: mainAction) {
                VStack(spacing: 8) {
                    Image(systemName: mainActionIcon)
                        .font(.system(size: 24))
                    Text(mainActionLabel)
                        .font(.caption)
                }
                .foregroundColor(.accent)
            }
        }
        .padding(.bottom, 32)
    }
    
    private var mainActionIcon: String {
        switch viewModel.voiceState {
        case .idle: return "mic"
        case .listening: return "stop.fill"
        case .processing: return "ellipsis"
        case .speaking: return "hand.raised"
        }
    }
    
    private var mainActionLabel: String {
        switch viewModel.voiceState {
        case .idle: return "Start"
        case .listening: return "Stop"
        case .processing: return "Wait"
        case .speaking: return "Interrupt"
        }
    }
    
    private func mainAction() {
        switch viewModel.voiceState {
        case .idle:
            viewModel.startListening()
        case .listening:
            viewModel.stopListening()
        case .processing:
            break // Can't interrupt processing
        case .speaking:
            viewModel.interruptSage()
        }
    }
}

// MARK: - Preview

#Preview {
    VoiceView(viewModel: MainViewModel())
}
