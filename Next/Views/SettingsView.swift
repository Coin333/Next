import SwiftUI

// MARK: - Settings View
/// Settings sheet for API key configuration and app preferences.
struct SettingsView: View {
    
    @ObservedObject var viewModel: MainViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isAPIKeyFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // API Key Section
                        apiKeySection
                        
                        // Energy Level Section
                        if viewModel.hasAPIKey {
                            energyLevelSection
                        }
                        
                        // About Section
                        aboutSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("API Key", systemImage: "key")
                .font(.headline)
                .foregroundColor(.primary)
            
            if viewModel.hasAPIKey {
                // Already configured
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("API key configured")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Remove") {
                        viewModel.deleteAPIKey()
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(12)
            } else {
                // Input field
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter your OpenAI API key to enable Sage")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("sk-...", text: $viewModel.apiKeyInput)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .focused($isAPIKeyFocused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    Button(action: { viewModel.saveAPIKey() }) {
                        Text("Save API Key")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.apiKeyInput.isEmpty ? Color.gray : Color.accent)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.apiKeyInput.isEmpty)
                    
                    Text("Your API key is stored securely in iOS Keychain and never leaves your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Energy Level Section
    
    private var energyLevelSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Energy Level", systemImage: "battery.50")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Sage will size tasks based on your energy")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker("Energy Level", selection: $viewModel.energyLevel) {
                ForEach(EnergyLevel.allCases, id: \.self) { level in
                    HStack {
                        Image(systemName: level.icon)
                        Text(level.displayName)
                    }
                    .tag(level)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("About", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Next")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Your calm AI companion for getting things done, one step at a time.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Version 2.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: MainViewModel())
}
