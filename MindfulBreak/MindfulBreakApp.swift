//
//  MindfulBreakApp.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import UserNotifications

@main
struct MindfulBreakApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showChallenge = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    DashboardView()
                } else {
                    OnboardingContainerView()
                }

                if showChallenge {
                    ChallengeView {
                        showChallenge = false
                        clearChallengeRequest()
                    }
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onAppear {
                checkForChallengeRequest()
                appDelegate.showChallengeHandler = { self.showChallenge = true }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkForChallengeRequest()
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")

        if url.scheme == "mindfulbreak" && url.host == "challenge" {
            print("✅ Opening challenge screen")
            showChallenge = true
        }
    }

    private func checkForChallengeRequest() {
        if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
            if defaults.bool(forKey: "shouldShowChallenge") {
                print("🎯 Challenge requested from shield - opening challenge screen")
                showChallenge = true
            }
        }
    }

    private func clearChallengeRequest() {
        if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
            defaults.set(false, forKey: "shouldShowChallenge")
            defaults.synchronize()
        }
    }
}

// AppDelegate to handle notification taps
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var showChallengeHandler: (() -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📬 Notification tapped!")

        if response.notification.request.content.categoryIdentifier == "CHALLENGE_UNLOCK" {
            print("✅ Opening challenge screen from notification")
            DispatchQueue.main.async {
                self.showChallengeHandler?()
            }
        }

        completionHandler()
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
