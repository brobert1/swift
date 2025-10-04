//
//  DataStore.swift
//  MindfulBreak
//
//  Production-ready data persistence using UserDefaults and App Groups
//

import Foundation
import FamilyControls

/// Manages persistent storage for monitored apps and user preferences
@MainActor
class DataStore: ObservableObject {
    static let shared = DataStore()

    // App Group identifier for sharing data between app and extension
    private let appGroupIdentifier = "group.com.developer.mindfullness.shared"

    private let defaults: UserDefaults

    // Keys for UserDefaults
    private enum Keys {
        static let monitoredApps = "monitoredApps"
        static let userInterests = "userInterests"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isMonitoringActive = "isMonitoringActive"
    }

    @Published var monitoredApps: [MonitoredApp] = []
    @Published var userInterests: [String] = []
    @Published var isMonitoringActive: Bool = false

    private init() {
        // Use App Group UserDefaults for sharing with extension
        if let groupDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            self.defaults = groupDefaults
        } else {
            // Fallback to standard UserDefaults
            print("⚠️ Could not access App Group, using standard UserDefaults")
            self.defaults = UserDefaults.standard
        }

        loadData()
    }

    // MARK: - Load Data

    private func loadData() {
        // Load monitoring state
        isMonitoringActive = defaults.bool(forKey: Keys.isMonitoringActive)

        // Load interests
        if let interests = defaults.array(forKey: Keys.userInterests) as? [String] {
            userInterests = interests
        }

        // Note: MonitoredApps with ApplicationToken cannot be easily serialized
        // In production, you'd store app identifiers and recreate tokens
        // For now, we'll manage them in memory during app session
    }

    // MARK: - Save Data

    func saveMonitoredApps(_ apps: [MonitoredApp]) {
        monitoredApps = apps
        // Store app metadata (without tokens, as they can't be serialized)
        let appData = apps.map { [
            "id": $0.id,
            "timeLimitInMinutes": $0.timeLimitInMinutes,
            "isEnabled": $0.isEnabled
        ] as [String : Any] }
        defaults.set(appData, forKey: Keys.monitoredApps)
        defaults.synchronize()
    }

    func saveInterests(_ interests: [String]) {
        userInterests = interests
        defaults.set(interests, forKey: Keys.userInterests)
        defaults.synchronize()
    }

    func setMonitoringActive(_ active: Bool) {
        isMonitoringActive = active
        defaults.set(active, forKey: Keys.isMonitoringActive)
        defaults.synchronize()
    }

    func completeOnboarding() {
        defaults.set(true, forKey: Keys.hasCompletedOnboarding)
        defaults.synchronize()
    }

    // MARK: - Helper Methods

    func getEnabledApps() -> [MonitoredApp] {
        return monitoredApps.filter { $0.isEnabled }
    }
}
