import SwiftUI

// MARK: - Main View
/// Primary view of the Next app.
/// Presents one task at a time with voice interaction.
struct MainView: View {
    
    @StateObject private var viewModel = MainViewModel()
    
    var body: some View {
        ZStack {
            // Background
            Color.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                // Main Content Area
                contentArea
                
                Spacer()
                
                // Voice Button
                voiceButtonArea
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            viewModel.greetUser()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Connection indicator
            if !viewModel.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.red)
                    .font(.system(size: 14))
            }
            
            Spacer()
            
            // Settings button
            Button(action: { viewModel.showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Content Area
    
    @ViewBuilder
    private var contentArea: some View {
        VStack(spacing: 32) {
            // Sage Message
            if let message = viewModel.lastSageMessage {
                sageMessageView(message)
            }
            
            // Current Task Card
            if let task = viewModel.currentTask {
                taskCardView(task)
            }
            
            // Transcription (while listening)
            if viewModel.voiceState == .listening && !viewModel.transcribedText.isEmpty {
                transcriptionView
            }
            
            // Processing indicator
            if viewModel.isProcessing {
                processingView
            }
        }
    }
    
    // MARK: - Sage Message
    
    private func sageMessageView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Sage")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.accent)
                
                if viewModel.voiceState == .speaking {
                    speakingIndicator
                }
                
                Spacer()
            }
            
            Text(message)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Task Card
    
    private func taskCardView(_ task: SageTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Task title
            Text(task.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Time estimate
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text(task.timeEstimate)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Action buttons
            HStack(spacing: 16) {
                Button(action: { viewModel.completeTask() }) {
                    Label("Done", systemImage: "checkmark")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .tint(.accent)
                
                Button(action: { viewModel.skipTask() }) {
                    Label("Skip", systemImage: "forward")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accent.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Transcription View
    
    private var transcriptionView: some View {
        Text(viewModel.transcribedText)
            .font(.body)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground.opacity(0.5))
            .cornerRadius(12)
    }
    
    // MARK: - Processing View
    
    private var processingView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.accent)
            Text("Thinking...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // MARK: - Speaking Indicator
    
    private var speakingIndicator: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.accent)
                    .frame(width: 4, height: 4)
                    .scaleEffect(viewModel.voiceState == .speaking ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.4)
                        .repeatForever()
                        .delay(Double(index) * 0.15),
                        value: viewModel.voiceState
                    )
            }
        }
    }
    
    // MARK: - Voice Button Area
    
    private var voiceButtonArea: some View {
        VStack(spacing: 16) {
            // Audio level indicator
            if viewModel.voiceState == .listening {
                audioLevelIndicator
            }
            
            // Main voice button
            VoiceButton(
                state: viewModel.voiceState,
                onTap: { viewModel.toggleMicrophone() },
                onLongPress: { viewModel.interruptSage() }
            )
            
            // State label
            Text(voiceStateLabel)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 32)
    }
    
    private var audioLevelIndicator: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.accent)
                .frame(width: geometry.size.width * CGFloat(viewModel.audioLevel), height: 4)
                .animation(.easeOut(duration: 0.05), value: viewModel.audioLevel)
        }
        .frame(height: 4)
        .padding(.horizontal, 40)
    }
    
    private var voiceStateLabel: String {
        switch viewModel.voiceState {
        case .idle:
            return viewModel.hasAPIKey ? "Tap to speak" : "Set up API key to start"
        case .listening:
            return "Listening..."
        case .processing:
            return "Processing..."
        case .speaking:
            return "Sage is speaking"
        }
    }
}

// MARK: - Voice Button

struct VoiceButton: View {
    let state: VoiceEngine.VoiceState
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background circle
                Circle()
                    .fill(buttonColor)
                    .frame(width: 80, height: 80)
                    .shadow(color: buttonColor.opacity(0.4), radius: isPressed ? 4 : 8, y: isPressed ? 2 : 4)
                
                // Icon
                Image(systemName: buttonIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.easeOut(duration: 0.15), value: isPressed)
    }
    
    private var buttonColor: Color {
        switch state {
        case .idle: return .accent
        case .listening: return .red
        case .processing: return .orange
        case .speaking: return .accent.opacity(0.7)
        }
    }
    
    private var buttonIcon: String {
        switch state {
        case .idle: return "mic"
        case .listening: return "mic.fill"
        case .processing: return "ellipsis"
        case .speaking: return "speaker.wave.2"
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
