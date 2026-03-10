# Next

Next is a **voice-first AI assistant** iOS app designed to help users overcome overwhelm and complete goals one step at a time. Guided by a calm AI companion called **Sage**, the app breaks down your goals into small, achievable tasks and presents only **one task at a time**.

> Next exists to help people start when starting feels hard.

## Features

### Core Features (v2)

- **Voice-First Interface**: Talk to Sage naturally to set goals and manage tasks
- **One-Task System**: Only one task visible at a time — no overwhelming lists
- **AI Task Decomposition**: Sage breaks goals into micro-tasks (10-40 min each)
- **Real-Time Speech**: Sage speaks responses back to you
- **Resistance Detection**: If you feel overwhelmed, Sage shrinks the task
- **Energy-Aware**: Tasks sized to match your current energy level
- **Secure API Storage**: API key stored in iOS Keychain

### Design Philosophy

- Minimal, dark, calm interface
- Voice-first interactions
- No dashboards, metrics, or gamification
- Never punishes missed days
- Always offers achievable actions

## Architecture (v2)

```
Next/
├── AI/
│   ├── SageAPIManager.swift       # API communication
│   ├── PromptBuilder.swift        # Structured prompts
│   └── ResponseParser.swift       # JSON response parsing
├── Voice/
│   ├── VoiceEngine.swift          # Voice orchestration
│   ├── SpeechRecognizer.swift     # Speech-to-text
│   └── SpeechSynthesizer.swift    # Text-to-speech
├── Models/
│   ├── Task.swift                 # Task model
│   ├── Goal.swift                 # Goal model
│   └── ConversationState.swift    # Conversation tracking
├── Services/
│   ├── ConversationManager.swift  # Conversation flow
│   └── TaskEngine.swift           # Task operations
├── Security/
│   └── KeychainManager.swift      # Secure key storage
├── ViewModels/
│   └── MainViewModel.swift        # Primary view model
├── Views/
│   ├── MainView.swift             # Main interface
│   ├── VoiceView.swift            # Voice interaction
│   └── SettingsView.swift         # Settings & API key
├── Utilities/
│   ├── Logger.swift               # Structured logging
│   └── NetworkMonitor.swift       # Connectivity
└── NextApp.swift                  # App entry point
```

## Setup

1. Clone the repository
2. Open `Next.xcodeproj` in Xcode
3. Build and run on a real iOS device (microphone required)
4. Enter your OpenAI API key in Settings

## Requirements

- iOS 17.0+
- Xcode 15+
- OpenAI API key

## Color Palette

| Element     | Color     |
| ----------- | --------- | |
| Background  | `#1C1C1E` |
| Text        | `#FFFFFF` |
| Accent      | `#8FAF9A` |

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Getting Started

1. Open `Next.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘R)

## Behavioral Principles

1. Reduce cognitive load
2. Shrink tasks to reduce resistance
3. Never punish missed days
4. Always offer achievable actions
5. Encourage momentum

## License

MIT
