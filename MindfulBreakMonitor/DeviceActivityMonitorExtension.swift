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
import UserNotifications

class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    let store = ManagedSettingsStore()
    let appGroupDefaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared")

    // Track app usage times
    private var appUsageTimes: [String: TimeInterval] = [:]

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        print("✅ [EXTENSION] Monitoring started for: \(activity)")

        // Reset shields at start of day
        store.shield.applications = nil

        // Reset today's usage data at start of new day
        resetDailyUsage()

        // Log to verify extension is running
        logExtensionEvent("intervalDidStart - New day started")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        print("✅ [EXTENSION] Monitoring ended for: \(activity)")
        logExtensionEvent("intervalDidEnd")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        let eventName = event.rawValue

        print("🔔 [EXTENSION] Event triggered: \(eventName)")
        logExtensionEvent("Event: \(eventName)")

        // Check if this is an early reminder, regular reminder, or limit event
        if eventName.starts(with: "earlyReminder_") {
            handleReminderEvent(eventName: eventName)
        } else if eventName.starts(with: "reminder_") {
            handleReminderEvent(eventName: eventName)
        } else if eventName.starts(with: "limit_") {
            handleLimitEvent(eventName: eventName)
        } else {
            print("⚠️ [EXTENSION] Unknown event type: \(eventName)")
        }
    }

    private func handleReminderEvent(eventName: String) {
        // Check if this is the early reminder (triggered after 10 seconds)
        if eventName.starts(with: "earlyReminder_") {
            let appId = eventName.replacingOccurrences(of: "earlyReminder_", with: "")
            handleEarlyReminder(appId: appId)
            return
        }

        // Parse: reminder_<appId>_<interval>
        let components = eventName.split(separator: "_")
        guard components.count >= 3,
              let interval = Int(components[2]) else {
            print("❌ [EXTENSION] Invalid reminder event format: \(eventName)")
            return
        }

        let appId = components[1..<components.count-1].joined(separator: "_")

        print("⏰ [EXTENSION] REMINDER - \(interval) min used")
        print("   App ID: \(appId)")

        logExtensionEvent("⏰ Reminder sent: \(appId) at \(interval) min")

        // Load monitored apps to get remaining time
        if let monitoredAppsData = appGroupDefaults?.data(forKey: "monitoredApps"),
           let apps = try? JSONDecoder().decode([MonitoredAppCodable].self, from: monitoredAppsData),
           let app = apps.first(where: { $0.id == appId }) {

            let remainingMinutes = app.timeLimitInMinutes - interval

            // Send reminder notification
            sendReminderNotification(appId: appId, usedMinutes: interval, remainingMinutes: remainingMinutes)

            // Save that user should be prompted when they open the app
            appGroupDefaults?.set(true, forKey: "shouldPromptUser_\(appId)")
            appGroupDefaults?.set(Date(), forKey: "lastPromptTime_\(appId)")
            appGroupDefaults?.synchronize()
        }
    }

    private func handleEarlyReminder(appId: String) {
        print("🎯 [EXTENSION] EARLY REMINDER - App just opened!")
        print("   App ID: \(appId)")

        logExtensionEvent("🎯 Early reminder (10s): \(appId)")

        // Load monitored apps to get remaining time
        if let monitoredAppsData = appGroupDefaults?.data(forKey: "monitoredApps"),
           let apps = try? JSONDecoder().decode([MonitoredAppCodable].self, from: monitoredAppsData),
           let app = apps.first(where: { $0.id == appId }) {

            let remainingMinutes = app.timeLimitInMinutes

            // Send immediate notification prompting user
            sendIntentPromptNotification(appId: appId, remainingMinutes: remainingMinutes)

            // Save that user should be prompted
            appGroupDefaults?.set(true, forKey: "shouldPromptUser_\(appId)")
            appGroupDefaults?.set(Date(), forKey: "lastPromptTime_\(appId)")
            appGroupDefaults?.synchronize()
        }
    }

    private func handleLimitEvent(eventName: String) {
        let appId = eventName.replacingOccurrences(of: "limit_", with: "")

        print("🚨 [EXTENSION] LIMIT REACHED!")
        print("   App ID: \(appId)")
        print("   Event: \(eventName)")

        logExtensionEvent("🛡️ LIMIT REACHED - Shielding app: \(appId)")

        // Load monitored apps to get the token
        if let monitoredAppsData = appGroupDefaults?.data(forKey: "monitoredApps"),
           let apps = try? JSONDecoder().decode([MonitoredAppCodable].self, from: monitoredAppsData) {

            if let app = apps.first(where: { $0.id == appId }) {
                // SHIELD THIS APP IMMEDIATELY
                store.shield.applications = Set([app.token])

                // Save that this app is shielded
                appGroupDefaults?.set(true, forKey: "appShielded_\(appId)")
                appGroupDefaults?.set(Date(), forKey: "appShieldedTime_\(appId)")

                print("✅ [EXTENSION] SHIELDED app successfully!")
                logExtensionEvent("✅ App shielded: \(appId)")

                // Send notification to user
                sendLimitReachedNotification(appId: appId)
            } else {
                print("❌ [EXTENSION] Could not find app with ID: \(appId)")
                logExtensionEvent("❌ App not found: \(appId)")
            }
        } else {
            print("❌ [EXTENSION] Could not load monitored apps data")
            logExtensionEvent("❌ Failed to load monitored apps")
        }

        // Notify main app
        appGroupDefaults?.set(true, forKey: "appsAreShielded")
        appGroupDefaults?.set(Date(), forKey: "lastShieldTime")
        appGroupDefaults?.synchronize()
    }

    private func sendIntentPromptNotification(appId: String, remainingMinutes: Int) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "💭 Why are you opening this app?"
        content.body = "You have \(remainingMinutes) minutes left today. Tap to reflect on your intention."
        content.sound = .default
        content.categoryIdentifier = "APP_REMINDER"
        content.userInfo = ["appId": appId, "type": "reminder"]

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "intent_prompt_\(appId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ [EXTENSION] Failed to send intent prompt: \(error)")
            } else {
                print("📬 [EXTENSION] Intent prompt notification sent!")
            }
        }
    }

    private func sendReminderNotification(appId: String, usedMinutes: Int, remainingMinutes: Int) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "⏰ Time Check!"
        content.body = "You have \(remainingMinutes) minutes left today! Don't forget to fulfill your goals."
        content.sound = .default
        content.categoryIdentifier = "APP_REMINDER"
        content.userInfo = ["appId": appId, "type": "reminder"]

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder_\(appId)_\(usedMinutes)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ [EXTENSION] Failed to send reminder: \(error)")
            } else {
                print("📬 [EXTENSION] Reminder notification sent!")
            }
        }
    }

    private func sendLimitReachedNotification(appId: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "⏰ Time's Up!"
        content.body = "You've reached your daily limit. Tap to complete a challenge and unlock more time."
        content.sound = .default
        content.categoryIdentifier = "CHALLENGE_UNLOCK"
        content.userInfo = ["appId": appId, "type": "limit"]

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "limit_reached_\(appId)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ [EXTENSION] Failed to send notification: \(error)")
            } else {
                print("📬 [EXTENSION] Notification sent!")
            }
        }
    }

    // Helper struct to decode monitored apps
    private struct MonitoredAppCodable: Codable {
        let id: String
        let token: ApplicationToken
        let timeLimitInMinutes: Int
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

    private func resetDailyUsage() {
        // Reset all usage counters for new day
        guard let defaults = appGroupDefaults else { return }

        // Load monitored apps to know what to reset
        if let monitoredAppsData = defaults.data(forKey: "monitoredApps"),
           let apps = try? JSONDecoder().decode([MonitoredAppCodable].self, from: monitoredAppsData) {

            for app in apps {
                defaults.removeObject(forKey: "usage_\(app.id)")
            }
        }

        // Reset global usage tracking
        defaults.removeObject(forKey: "todaysTotalUsage")
        defaults.removeObject(forKey: "appStartTimes")
        defaults.set(Date(), forKey: "lastResetDate")
        defaults.synchronize()

        print("🔄 [EXTENSION] Reset daily usage data")
    }
}
