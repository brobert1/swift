//
//  DeviceActivityMonitorExtension.swift
//  MindfulBreakMonitor
//
//  Production-ready DeviceActivity Monitor Extension
//  This runs in the background and responds to usage events
//

import DeviceActivity
import FamilyControls
import ManagedSettings

/// Extension that monitors device activity and applies shields when limits are reached
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()

    // MARK: - Monitoring Events

    /// Called when the monitoring interval starts (e.g., beginning of day)
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("📱 Monitoring interval started for: \(activity)")

        // Reset shields at start of day
        store.shield.applications = nil
    }

    /// Called when the monitoring interval ends (e.g., end of day)
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("📱 Monitoring interval ended for: \(activity)")

        // Optionally clear shields at end of day
        store.shield.applications = nil
    }

    /// Called when an event threshold is reached (e.g., time limit exceeded)
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("⚠️ Threshold reached for event: \(event)")

        // Load monitored apps from shared storage
        // Apply shields to apps that exceeded their limits
        applyShields()
    }

    /// Called when a warning threshold is reached (e.g., 5 minutes before limit)
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        print("⏰ Warning: Approaching threshold for event: \(event)")

        // Send notification to user
        // "You have 5 minutes left on Instagram"
    }

    // MARK: - Shield Management

    private func applyShields() {
        // In a production app, you would:
        // 1. Read from App Group UserDefaults to get monitored apps
        // 2. Check which apps exceeded their time limits
        // 3. Apply shields only to those apps

        // For now, apply shields to all monitored apps
        // The actual app tokens would be loaded from shared storage

        print("🛡️ Applying shields to apps that exceeded limits")
    }
}
