//
//  ShieldActionExtension.swift
//  MindfulBreakMonitor
//
//  Handles shield button taps - opens challenge
//

import Foundation
import ManagedSettings
import DeviceActivity
import UserNotifications

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
            
            // Send notification about challenge availability
            sendChallengeNotification()

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
    
    // MARK: - Notification Helper
    
    private func sendChallengeNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "⏰ Time's Up!"
        content.body = "Complete a challenge to unlock more time"
        content.sound = .default
        content.categoryIdentifier = "CHALLENGE_UNLOCK"
        content.userInfo = ["type": "shield_tapped"]
        
        // Use unique identifier with timestamp to ensure notification always appears
        let uniqueIdentifier = "shield_challenge_\(Date().timeIntervalSince1970)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: uniqueIdentifier,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ [SHIELD] Failed to send notification: \(error)")
            } else {
                print("📬 [SHIELD] Challenge notification sent!")
            }
        }
    }
}
