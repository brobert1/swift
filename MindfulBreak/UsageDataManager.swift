//
//  UsageDataManager.swift
//  MindfulBreak
//
//  Real usage data management using DeviceActivity
//

import Foundation
import DeviceActivity
import FamilyControls

@MainActor
class UsageDataManager: ObservableObject {
    static let shared = UsageDataManager()

    @Published var appUsageData: [String: TimeInterval] = [:]

    private let appGroupDefaults: UserDefaults?
    private let appGroupIdentifier = "group.com.developer.mindfullness.shared"

    private init() {
        self.appGroupDefaults = UserDefaults(suiteName: appGroupIdentifier)
        loadUsageData()
    }

    // MARK: - Load Usage Data

    func loadUsageData() {
        guard let defaults = appGroupDefaults else {
            print("⚠️ Could not access App Group UserDefaults")
            return
        }

        // Load usage data written by the extension
        if let usageDict = defaults.dictionary(forKey: "appUsageData") as? [String: TimeInterval] {
            appUsageData = usageDict
            print("📊 Loaded usage data for \(usageDict.count) apps")
        }
    }

    // MARK: - Get Usage for App

    func getUsage(for appId: String) -> TimeInterval {
        return appUsageData[appId] ?? 0
    }

    func getUsageInMinutes(for appId: String) -> Int {
        let seconds = getUsage(for: appId)
        return Int(seconds / 60)
    }

    // MARK: - Save Usage (Called from Extension)

    func saveUsage(_ timeInterval: TimeInterval, for appId: String) {
        guard let defaults = appGroupDefaults else { return }

        appUsageData[appId] = timeInterval
        defaults.set(appUsageData, forKey: "appUsageData")
        defaults.synchronize()

        print("💾 Saved usage: \(Int(timeInterval/60)) min for app \(appId)")
    }

    // MARK: - Reset Daily

    func resetDailyUsage() {
        appUsageData.removeAll()
        appGroupDefaults?.removeObject(forKey: "appUsageData")
        appGroupDefaults?.synchronize()
        print("🔄 Reset daily usage data")
    }
}
