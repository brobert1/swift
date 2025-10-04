//
//  ScreenTimeManager.swift
//  MindfulBreak
//
//  Production-ready Screen Time management with DeviceActivity monitoring
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

@MainActor
class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var isAuthorized = false
    @Published var selectedApps: Set<ApplicationToken> = []
    @Published var areAppsShielded = false
    @Published var activeSchedules: [DeviceActivityName] = []

    private let center = AuthorizationCenter.shared
    private let store = ManagedSettingsStore()
    private let activityCenter = DeviceActivityCenter()

    // Activity names for tracking different monitoring sessions
    private let dailyActivityName = DeviceActivityName("dailyMonitoring")

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        switch center.authorizationStatus {
        case .approved:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func requestAuthorization() async throws {
        try await center.requestAuthorization(for: .individual)
        checkAuthorizationStatus()
    }

    // MARK: - App Shielding

    /// Immediately shield (block) the selected apps
    func shieldApps(_ apps: [MonitoredApp]) {
        let enabledApps = apps.filter { $0.isEnabled }
        let tokens = Set(enabledApps.map { $0.token })

        // Apply shields to the apps
        store.shield.applications = tokens
        areAppsShielded = true

        print("✅ Shielded \(tokens.count) apps")
    }

    /// Remove shields from all apps
    func unshieldApps() {
        store.shield.applications = nil
        areAppsShielded = false

        print("✅ Removed shields from all apps")
    }

    /// Toggle shield state for apps
    func toggleShield(for apps: [MonitoredApp]) {
        if areAppsShielded {
            unshieldApps()
        } else {
            shieldApps(apps)
        }
    }

    // MARK: - DeviceActivity Monitoring (Production)

    /// Start monitoring apps with time limits
    func startMonitoring(for apps: [MonitoredApp]) {
        guard isAuthorized else {
            print("❌ Cannot start monitoring: Not authorized")
            return
        }

        let enabledApps = apps.filter { $0.isEnabled }
        guard !enabledApps.isEmpty else {
            print("⚠️ No enabled apps to monitor")
            return
        }

        // Stop any existing monitoring first
        stopMonitoring()

        // Create a DAILY schedule (midnight to midnight)
        // This tracks usage for the entire day
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Create threshold events for each app
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for app in enabledApps {
            // Main limit event - fires when daily limit is reached
            let limitEventName = DeviceActivityEvent.Name("limit_\(app.id)")

            // TESTING: Use 30 seconds for faster testing
            let limitEvent = DeviceActivityEvent(
                applications: [app.token],
                threshold: DateComponents(second: 30)
            )
            events[limitEventName] = limitEvent

            print("🧪 TESTING MODE: Using 30-second limit instead of \(app.timeLimitInMinutes) minutes")

            // Create early reminders to prompt user about their intention
            // DeviceActivity may not support sub-minute thresholds reliably
            // So we'll use both seconds and minutes to ensure it works
            if app.timeLimitInMinutes > 0 {
                // Try 30 seconds first (might work on newer iOS)
                let earlyReminder30s = DeviceActivityEvent.Name("earlyReminder_\(app.id)_30s")
                let event30s = DeviceActivityEvent(
                    applications: [app.token],
                    threshold: DateComponents(second: 30)
                )
                events[earlyReminder30s] = event30s
                print("   📱 Registered 30-second reminder: \(earlyReminder30s.rawValue)")

                // Also add 1-minute reminder as fallback
                if app.timeLimitInMinutes > 1 {
                    let earlyReminder1m = DeviceActivityEvent.Name("earlyReminder_\(app.id)_1m")
                    let event1m = DeviceActivityEvent(
                        applications: [app.token],
                        threshold: DateComponents(minute: 1)
                    )
                    events[earlyReminder1m] = event1m
                    print("   📱 Registered 1-minute reminder: \(earlyReminder1m.rawValue)")
                }
            }

            print("📊 Monitoring: \(app.timeLimitInMinutes) min daily limit")
            print("   Total events registered: \(events.count)")
        }

        // Start monitoring
        do {
            try activityCenter.startMonitoring(dailyActivityName, during: schedule, events: events)
            activeSchedules.append(dailyActivityName)

            print("✅ DeviceActivity monitoring ACTIVE")
            print("   📱 iOS will track real usage")
            print("   🛡️  Apps will shield when limits are reached")

        } catch {
            print("❌ Failed to start monitoring: \(error.localizedDescription)")
        }
    }

    /// Stop all monitoring
    func stopMonitoring() {
        activityCenter.stopMonitoring([dailyActivityName])
        activeSchedules.removeAll()
        unshieldApps()
        print("✅ Stopped all monitoring")
    }

    // MARK: - Shield Configuration

    /// Configure shield appearance and behavior
    func configureShield() {
        // Customize the shield appearance
        store.shield.applicationCategories = .all(except: Set())

        // You can customize shield labels, colors, etc.
        // This appears when user tries to open a blocked app
    }

    // MARK: - Helper Methods

    /// Check if monitoring is currently active
    func isMonitoringActive() -> Bool {
        return !activeSchedules.isEmpty
    }
}
