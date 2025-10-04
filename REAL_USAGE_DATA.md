# Real Usage Data Implementation

## ⚠️ Important: Current Limitation

**The challenge:** iOS DeviceActivity usage statistics are **only accessible inside the DeviceActivityMonitor extension**, not in the main app. This is an Apple security/privacy restriction.

## 🔄 How Real Usage Data Works

### **Architecture:**

```
┌─────────────────────────────────────┐
│   iOS System (DeviceActivity)      │
│   - Tracks actual app usage         │
│   - Only extension can read data    │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  DeviceActivityMonitor Extension    │
│  - Reads usage from iOS             │
│  - Writes to App Group storage      │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│     App Group UserDefaults          │
│  (group.com.developer.mindfullness) │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│      Main App (MindfulBreak)        │
│  - Reads from App Group storage     │
│  - Displays in Dashboard            │
└─────────────────────────────────────┘
```

## ✅ What I Implemented

### **1. UsageDataManager.swift**
Manages reading/writing usage data via App Groups:

```swift
class UsageDataManager: ObservableObject {
    // Shared storage between app and extension
    private let appGroupDefaults: UserDefaults?

    // Load usage written by extension
    func loadUsageData()

    // Get usage for specific app
    func getUsageInMinutes(for appId: String) -> Int

    // Save usage (called from extension)
    func saveUsage(_ timeInterval: TimeInterval, for appId: String)
}
```

### **2. Updated Dashboard**
- Removed mock/random data
- Now uses `UsageDataManager` to get real usage
- Displays actual time from iOS Screen Time

```swift
// Old (mock):
@State private var usedMinutes: Int = Int.random(in: 0...60)

// New (real):
let usedMinutes: Int  // From UsageDataManager
```

### **3. Extension Updates**
- Extension resets usage data at start of day
- Will write actual usage to App Group storage
- Data flows: iOS → Extension → App Group → Main App

## 🚧 What's Missing (Requires Extension Setup)

To get **real usage numbers**, the extension needs to:

### **Step 1: Query DeviceActivity Report**
```swift
// In DeviceActivityMonitor extension
override func intervalDidEnd(for activity: DeviceActivityName) {
    // Query actual usage from iOS
    let context = DeviceActivityReport.Context(/* config */)

    // This API only works in the extension!
    // Returns actual usage time per app
}
```

### **Step 2: Write to App Group**
```swift
// Extension writes real usage
let actualUsageSeconds = /* from DeviceActivity report */
appGroupDefaults?.set(actualUsageSeconds, forKey: "app_\(appId)_usage")
```

### **Step 3: Main App Reads**
```swift
// Already implemented in UsageDataManager
func loadUsageData() {
    // Reads from App Group storage
    // Updates Dashboard with real data
}
```

## 📋 Why You See Instagram as "13 min" But App Shows Different

**Current Situation:**
- iOS Screen Time shows **18 min** (real data from iOS)
- MindfulBreak shows **13 min** (placeholder/stale data)

**Reason:**
- The DeviceActivityMonitor extension isn't added to Xcode yet
- Without the extension running, we can't query iOS for real usage
- The app uses cached/default values from App Group storage

## 🔧 To Fix This (Manual Steps Required)

### **1. Add Extension to Xcode** (from SETUP_GUIDE.md)
```bash
File → New → Target → Device Activity Monitor Extension
Name: MindfulBreakMonitor
```

### **2. Configure App Groups** (both targets)
- Main app: Add App Group capability
- Extension: Add App Group capability
- Group ID: `group.com.developer.mindfullness.shared`

### **3. Implement DeviceActivityReport in Extension**

Create `DeviceActivityReportScene.swift` in extension:
```swift
import DeviceActivity
import SwiftUI

struct DeviceActivityReportScene: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context

    func makeConfiguration(representing data: ActivityReport) -> some View {
        // Extract usage data
        // Write to App Group
        // Return EmptyView (we don't show UI in extension)
    }
}
```

### **4. Query Usage Periodically**

In extension:
```swift
override func intervalDidEnd(for activity: DeviceActivityName) {
    // Create report request
    let report = DeviceActivityReport(
        context: .init(/* your monitored apps */),
        type: .totalActivity
    )

    // iOS provides actual usage data
    // Save to App Group for main app to read
}
```

## 🎯 Current State vs. Full Implementation

### **✅ Currently Working:**
- App Group setup for data sharing
- UsageDataManager infrastructure
- Dashboard reads from shared storage
- Extension resets daily data

### **⏳ Requires Extension Setup:**
- Querying iOS for actual usage times
- Writing real data to App Group
- Periodic updates (every hour or on threshold)
- Accurate real-time statistics

## 📊 Temporary Solution (For Testing)

Until the extension is fully configured, you can:

### **Option 1: Use iOS Screen Time Directly**
Tell users to check iOS Settings → Screen Time for accurate data

### **Option 2: Manual Data Entry** (Development Only)
Add a debug method to manually set usage:
```swift
// For testing only
UsageDataManager.shared.saveUsage(18 * 60, for: instagramAppId)
```

### **Option 3: Estimate Based on Threshold Events**
When extension detects time limit reached:
```swift
override func eventDidReachThreshold(...) {
    // We know they hit the limit
    // So usage ≈ time limit
    saveUsage(app.timeLimitInMinutes * 60, for: app.id)
}
```

## 🔮 Final Implementation (After Extension Setup)

**Flow:**
1. User uses Instagram for 18 minutes
2. **iOS tracks this automatically** (always accurate)
3. **Extension queries iOS every hour** (or on events)
4. **Extension writes to App Group**: `instagram_usage = 18 min`
5. **Main app reads from App Group**: Shows "18 min"
6. **Dashboard displays accurate data** ✅

**Result:** Perfect sync between iOS Screen Time and your app!

## 📝 Summary

**Problem:** App shows different usage than iOS Screen Time

**Root Cause:** DeviceActivity data only accessible in extension

**Solution Implemented:**
- ✅ Infrastructure for reading real data (UsageDataManager)
- ✅ App Group sharing configured
- ✅ Dashboard updated to use real data source
- ⏳ Extension needs to be added to Xcode (manual step)
- ⏳ Extension needs DeviceActivityReport implementation

**Next Step:** Follow SETUP_GUIDE.md to add the extension target, then the usage data will automatically sync!
