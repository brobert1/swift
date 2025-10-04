# Neura

A digital wellness iOS app that helps users manage screen time through personalized micro-challenges.

## Features

- **App Time Monitoring**: Set daily time limits on distracting apps
- **Personalized Challenges**: Complete micro-tasks based on your interests (fitness, reading, mindfulness, etc.)
- **Smart Intervention**: When you exceed your time limit, complete a quick challenge to unlock the app temporarily
- **FamilyControls Integration**: Uses Apple's Screen Time API for robust app blocking

## Current Implementation Status

✅ **Complete Onboarding Flow**

- Welcome screen with app introduction
- App selection using FamilyControls app picker (shows real apps from device)
- Interest selection with visual tag grid
- Permissions setup (Screen Time, Shortcuts, Notifications)
- Completion screen

✅ **Basic Dashboard**

- Status tab showing monitored apps with progress bars
- Settings tab for configuration

⏳ **To Be Implemented**

- Challenge generation based on user interests
- Camera-based exercise verification
- DeviceActivity monitoring integration
- Shortcuts automation setup flow
- Persistent data storage

## Project Structure

```
MindfulBreak/
├── MindfulBreakApp.swift          # Main app entry point
├── Models.swift                    # Data models
├── ScreenTimeManager.swift         # Screen Time API wrapper
├── OnboardingCoordinator.swift     # Onboarding navigation
├── Views/
│   ├── WelcomeView.swift
│   ├── AppSelectionView.swift      # Uses FamilyControls picker
│   ├── InterestSelectionView.swift
│   ├── PermissionsView.swift
│   ├── OnboardingCompleteView.swift
│   └── DashboardView.swift
└── Info.plist
```

## Setup Instructions

### Prerequisites

- Xcode 15.0 or later
- iOS 16.0+ device (Screen Time API does NOT work in simulator)
- Apple Developer account (for FamilyControls entitlement)

### Required Capabilities

You must add the following to your Xcode project:

1. **Family Controls Capability**

   - Go to Target > Signing & Capabilities
   - Click "+ Capability"
   - Add "Family Controls"

2. **App Groups** (if needed for shared data)
   - Add "App Groups" capability
   - Create group: `group.com.mindfulbreak.app`

### Entitlements

The app requires the following entitlements in `MindfulBreak.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.family-controls</key>
    <true/>
</dict>
</plist>
```

### Build & Run

1. Open `MindfulBreak.xcodeproj` in Xcode
2. Select a physical iOS device (not simulator)
3. Update the bundle identifier to match your team
4. Add the Family Controls capability
5. Build and run (⌘R)

## How It Works

### Screen Time Integration

The app uses three main frameworks:

1. **FamilyControls**: Authorization and app selection UI
2. **ManagedSettings**: Apply shields/blocks to apps
3. **DeviceActivity**: Monitor app usage and trigger events

### Shortcuts Integration

Users create Personal Automations via the Shortcuts app:

- Trigger: "When [App] is Opened"
- Action: "Open Mindful Break"

When a shielded app is tapped → Shortcut runs → Opens Mindful Break → User completes challenge → App is temporarily unshielded.

## Mock Data

Currently using placeholder data for:

- App names (shows as "App 1", "App 2", etc.)
- Usage statistics (random values)
- Challenge tasks (hardcoded examples)

The FamilyControls app picker will show **real apps** from your device.

## Next Steps

1. Implement proper data persistence (SwiftData/UserDefaults)
2. Add DeviceActivity monitoring schedules
3. Create AI/RAG-based task generation
4. Build camera verification for exercises
5. Add proper app icon and assets
6. Implement analytics and tracking

## Notes

- **Device Only**: Screen Time APIs require a physical device
- **Entitlements**: Family Controls requires special entitlement from Apple
- **Permissions**: Users must grant Screen Time authorization
- **Shortcuts**: Automations must be manually created by users (cannot be programmatically created)

## License

MIT
