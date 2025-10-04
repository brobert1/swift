//
//  DeviceActivityMonitorExtension.swift
//  MindfulBreakMonitor
//
//  Created by Vlad Parau on 04.10.2025.
//

import DeviceActivity
import FamilyControls
import ManagedSettings
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()
    let appGroupDefaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("✅ [EXTENSION] Monitoring started for: \(activity)")

        // Reset shields at start of day
        store.shield.applications = nil

        // Reset usage data
        appGroupDefaults?.removeObject(forKey: "appUsageData")
        appGroupDefaults?.synchronize()

        // Log to verify extension is running
        logExtensionEvent("intervalDidStart")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("✅ [EXTENSION] Monitoring ended for: \(activity)")
        logExtensionEvent("intervalDidEnd")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        print("🛡️ [EXTENSION] Time limit reached for: \(event.rawValue)")

        // The event already contains the app tokens that exceeded the limit
        // iOS will automatically shield them, but we can also do it explicitly

        logExtensionEvent("eventDidReachThreshold: \(event.rawValue)")

        // Update app group to notify main app
        appGroupDefaults?.set(true, forKey: "appsAreShielded")
        appGroupDefaults?.set(Date(), forKey: "lastShieldTime")
        appGroupDefaults?.synchronize()
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)

        print("⚠️ [EXTENSION] Interval will start warning: \(activity)")
        logExtensionEvent("intervalWillStartWarning")
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)

        print("⚠️ [EXTENSION] Interval will end warning: \(activity)")
        logExtensionEvent("intervalWillEndWarning")
    }

    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)

        print("⏰ [EXTENSION] Warning: 5 min left for: \(event.rawValue)")
        logExtensionEvent("eventWillReachThresholdWarning: \(event.rawValue)")

        // TODO: Send local notification
        // "You have 5 minutes left on Instagram"
    }

    // MARK: - Helper Methods

    private func logExtensionEvent(_ event: String) {
        // Write to App Group so main app can verify extension is running
        var logs = appGroupDefaults?.array(forKey: "extensionLogs") as? [String] ?? []
        let timestamp = ISO8601DateFormatter().string(from: Date())
        logs.append("[\(timestamp)] \(event)")

        // Keep only last 20 logs
        if logs.count > 20 {
            logs.removeFirst(logs.count - 20)
        }

        appGroupDefaults?.set(logs, forKey: "extensionLogs")
        appGroupDefaults?.synchronize()
    }
}
