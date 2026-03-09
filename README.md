# Next

Next is a minimalist iOS focus app that reduces overwhelm by showing only one task at a time. Guided by a calm AI companion called **Sage**, the system shrinks tasks when resistance appears and replaces productivity pressure with small, achievable progress.

> Next exists to help people start when starting feels hard.

## Features

### Core Features (v1)

- **One-Task System**: Only one task visible at a time — no overwhelming lists
- **Goal Input**: Add goals via text or voice
- **AI Task Decomposition**: Sage breaks goals into micro-tasks (10-40 min each)
- **Resistance Detection**: "Done", "Not Now", or "Too Big" options
- **Task Shrinking**: Tasks automatically shrink when you feel resistance
- **Daily Energy Check**: Tasks sized to match your energy level
- **Daily Reflection**: Simple evening summary

### Design Philosophy

- Minimal, dark, calm interface
- No dashboards, metrics, or gamification
- Never punishes missed days
- Always offers achievable actions

## Project Structure

```
Next/
├── NextApp.swift              # App entry point
├── ContentView.swift          # Main navigation container
├── Task.swift                 # Data models (Task, Goal, User)
├── NextState.swift            # Application state management
├── Theme.swift                # Design system (colors, typography)
├── SageAIService.swift        # AI task decomposition service
├── StorageService.swift       # Local persistence service
├── VoiceInputService.swift    # Speech-to-text service
├── TaskView.swift             # Main task display
├── CompletionView.swift       # Task completion celebration
├── EnergyCheckView.swift      # Daily energy level selection
├── GoalInputView.swift        # Add new goals
├── ReflectionView.swift       # Evening reflection
├── EmptyStateView.swift       # No tasks state
└── Assets.xcassets/           # App icons and colors
```

## Color Palette

| Element     | Color     |
| ----------- | --------- |
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
