//
//  ShieldActionExtension.swift
//  MindfulBreakMonitor
//
//  Handles shield button taps - opens challenge
//

import Foundation
import ManagedSettings
import DeviceActivity

class ShieldActionExtension: ShieldActionDelegate {

    let appGroupDefaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared")

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {

        switch action {
        case .primaryButtonPressed:
            print("🎯 [SHIELD] User tapped 'Start Challenge' button")

            // Save that challenge should be shown
            appGroupDefaults?.set(true, forKey: "shouldShowChallenge")
            appGroupDefaults?.set(Date(), forKey: "challengeRequestTime")
            appGroupDefaults?.synchronize()

            // Just close the shield - the main app will check for this flag
            completionHandler(.close)

        case .secondaryButtonPressed:
            completionHandler(.defer)

        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.defer)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.defer)
    }
}
