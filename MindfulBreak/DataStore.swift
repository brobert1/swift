//
//  DataStore.swift
//  MindfulBreak
//
//  Production-ready data persistence using UserDefaults and App Groups
//

import Foundation
import FamilyControls
import ManagedSettings

/// Codable wrapper for MonitoredApp
struct MonitoredAppCodable: Codable {
    let id: String
    let token: ApplicationToken
    let timeLimitInMinutes: Int
    let isEnabled: Bool

    init(from app: MonitoredApp) {
        self.id = app.id
        self.token = app.token
        self.timeLimitInMinutes = app.timeLimitInMinutes
        self.isEnabled = app.isEnabled
    }

    func toMonitoredApp() -> MonitoredApp {
        return MonitoredApp(
            id: id,
            token: token,
            timeLimitInMinutes: timeLimitInMinutes,
            isEnabled: isEnabled
        )
    }
}

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

        // Load monitored apps
        if let data = defaults.data(forKey: Keys.monitoredApps),
           let decoded = try? JSONDecoder().decode([MonitoredAppCodable].self, from: data) {
            monitoredApps = decoded.map { $0.toMonitoredApp() }
            print("✅ Loaded \(monitoredApps.count) monitored apps from storage")
        }
    }

    // MARK: - Save Data

    func saveMonitoredApps(_ apps: [MonitoredApp]) {
        monitoredApps = apps
        // Encode apps with ApplicationToken (which is Codable)
        let codableApps = apps.map { MonitoredAppCodable(from: $0) }

        if let encoded = try? JSONEncoder().encode(codableApps) {
            defaults.set(encoded, forKey: Keys.monitoredApps)
            defaults.synchronize()
            print("✅ Saved \(apps.count) monitored apps to storage")
        } else {
            print("❌ Failed to encode monitored apps")
        }
    }

    func saveInterests(_ interests: [String]) {
        userInterests = interests
        defaults.set(interests, forKey: Keys.userInterests)
        defaults.synchronize()

        // Pre-generate AI challenges in background when interests are set
        Task {
            await AIChallengeGenerator.shared.preGenerateChallenges(userInterests: interests, count: 3)
        }
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
