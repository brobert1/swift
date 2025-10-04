//
//  UsageDataManager.swift
//  MindfulBreak
//
//  Real usage data management - tracks app usage every 1 minute
//

import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings
import UIKit

@MainActor
class UsageDataManager: ObservableObject {
    static let shared = UsageDataManager()

    @Published var appUsageData: [String: Int] = [:] // appId -> minutes used today

    private let appGroupDefaults: UserDefaults?
    private let appGroupIdentifier = "group.com.developer.mindfullness.shared"
    private var updateTimer: Timer?
    private var monitoredApps: [MonitoredApp] = []

    // Track when each app was last opened
    private var appStartTimes: [String: Date] = [:]
    private var todaysTotalUsage: [String: TimeInterval] = [:] // appId -> seconds

    private init() {
        self.appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier)
        loadTodaysUsage()
        startBackgroundMonitoring()
    }

    // MARK: - Start/Stop Monitoring

    func startTracking(for apps: [MonitoredApp]) {
        monitoredApps = apps
        print("📊 Started tracking \(apps.count) apps")

        // Start 1-minute timer to check usage
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateUsageFromSystem()
            }
        }

        // Do initial update immediately
        updateUsageFromSystem()
    }

    func stopTracking() {
        updateTimer?.invalidate()
        updateTimer = nil
        print("⏹️ Stopped usage tracking")
    }

    // MARK: - Update Usage from System

    private func updateUsageFromSystem() {
        // Get usage data from App Group (written by extension)
        guard let defaults = appGroupDefaults else { return }

        var shouldShield: [MonitoredApp] = []

        // Update ongoing sessions (apps currently open)
        let now = Date()
        for (appId, startTime) in appStartTimes {
            let sessionDuration = now.timeIntervalSince(startTime)
            let totalUsage = (todaysTotalUsage[appId] ?? 0) + sessionDuration
            appUsageData[appId] = Int(totalUsage / 60)
        }

        // Check if any monitored app's usage was updated by the extension
        for app in monitoredApps {
            let minutes = appUsageData[app.id] ?? 0

            // Also check extension-written usage
            if let usage = defaults.object(forKey: "usage_\(app.id)") as? TimeInterval {
                let extMinutes = Int(usage / 60)
                if extMinutes > minutes {
                    appUsageData[app.id] = extMinutes
                    todaysTotalUsage[app.id] = usage
                }
            }

            let finalMinutes = appUsageData[app.id] ?? 0
            if finalMinutes > 0 {
                print("📊 \(app.id): \(finalMinutes)/\(app.timeLimitInMinutes) min")
            }

            // Check if limit reached
            if finalMinutes >= app.timeLimitInMinutes && app.isEnabled {
                shouldShield.append(app)
            }
        }

        // Shield apps that reached their limit
        if !shouldShield.isEmpty {
            shieldApps(shouldShield)
        }

        // Trigger UI update
        objectWillChange.send()
    }

    private func shieldApps(_ apps: [MonitoredApp]) {
        let tokens = Set(apps.map { $0.token })

        // Apply shields using ManagedSettingsStore
        let store = ManagedSettingsStore()
        store.shield.applications = tokens

        print("🛡️ SHIELDING \(apps.count) apps NOW!")

        // Save shield state to App Group
        appGroupDefaults?.set(true, forKey: "appsAreShielded")
        appGroupDefaults?.set(Date(), forKey: "lastShieldTime")
        appGroupDefaults?.synchronize()

        // Also notify ScreenTimeManager
        Task { @MainActor in
            ScreenTimeManager.shared.areAppsShielded = true
        }
    }

    // MARK: - App Launch/Close Tracking

    func recordAppLaunched(_ appId: String) {
        appStartTimes[appId] = Date()
        saveToAppGroup()
        print("🚀 App launched: \(appId)")
    }

    func recordAppClosed(_ appId: String) {
        guard let startTime = appStartTimes[appId] else { return }

        let sessionDuration = Date().timeIntervalSince(startTime)
        todaysTotalUsage[appId, default: 0] += sessionDuration
        appUsageData[appId] = Int(todaysTotalUsage[appId, default: 0] / 60)

        appStartTimes.removeValue(forKey: appId)
        saveToAppGroup()

        print("⏱️ App closed: \(appId), session: \(Int(sessionDuration/60)) min, total: \(appUsageData[appId] ?? 0) min")
    }

    // MARK: - Get Usage for App

    func getUsage(for appId: String) -> TimeInterval {
        return todaysTotalUsage[appId] ?? 0
    }

    func getUsageInMinutes(for appId: String) -> Int {
        return appUsageData[appId] ?? 0
    }

    // MARK: - Persistence

    private func saveToAppGroup() {
        guard let defaults = appGroupDefaults else { return }

        // Save total usage in seconds
        defaults.set(todaysTotalUsage, forKey: "todaysTotalUsage")

        // Save current session start times
        let startTimesDict = appStartTimes.mapValues { $0.timeIntervalSince1970 }
        defaults.set(startTimesDict, forKey: "appStartTimes")

        defaults.synchronize()
    }

    private func loadTodaysUsage() {
        guard let defaults = appGroupDefaults else { return }

        // Check if we need to reset (new day)
        let lastResetDate = defaults.object(forKey: "lastResetDate") as? Date ?? Date.distantPast
        let calendar = Calendar.current

        if !calendar.isDateInToday(lastResetDate) {
            // New day - reset everything
            resetDailyUsage()
            defaults.set(Date(), forKey: "lastResetDate")
            defaults.synchronize()
            return
        }

        // Load existing usage
        if let usage = defaults.dictionary(forKey: "todaysTotalUsage") as? [String: TimeInterval] {
            todaysTotalUsage = usage
            appUsageData = usage.mapValues { Int($0 / 60) }
            print("📊 Loaded usage data for \(usage.count) apps")
        }

        // Load session start times
        if let times = defaults.dictionary(forKey: "appStartTimes") as? [String: TimeInterval] {
            appStartTimes = times.mapValues { Date(timeIntervalSince1970: $0) }
        }
    }

    private func resetDailyUsage() {
        todaysTotalUsage.removeAll()
        appUsageData.removeAll()
        appStartTimes.removeAll()

        appGroupDefaults?.removeObject(forKey: "todaysTotalUsage")
        appGroupDefaults?.removeObject(forKey: "appStartTimes")
        appGroupDefaults?.synchronize()

        print("🔄 Reset daily usage data")
    }

    // MARK: - Background Monitoring

    private func startBackgroundMonitoring() {
        // Register for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        // Save current state when app goes to background
        saveToAppGroup()
    }

    @objc private func appWillEnterForeground() {
        // Reload and update when app comes back
        loadTodaysUsage()
        updateUsageFromSystem()
    }

    deinit {
        updateTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
