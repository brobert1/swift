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
    @State private var showIntentPrompt = false
    @State private var promptAppId: String?
    @State private var userIntent: String = ""

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    DashboardView()
                        .id(promptAppId) // Force refresh when prompt changes
                } else {
                    OnboardingContainerView()
                }

                // Intent prompt overlay - using sheet for better presentation
                if showIntentPrompt, let appId = promptAppId {
                    IntentPromptView(appId: appId) {
                        showIntentPrompt = false
                        promptAppId = nil
                    }
                    .transition(.move(edge: .bottom))
                    .zIndex(999) // Ensure it's on top
                }
            }
            .onAppear {
                appDelegate.showIntentPromptHandler = { appId in
                    print("🎯 [APP] Handler called with appId: \(appId)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.promptAppId = appId
                        withAnimation {
                            self.showIntentPrompt = true
                        }
                    }
                }
            }
        }
    }
}

// AppDelegate to handle notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var showIntentPromptHandler: ((String) -> Void)?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📬 [APPDELEGATE] Notification tapped!")
        print("   Category: \(response.notification.request.content.categoryIdentifier)")

        let userInfo = response.notification.request.content.userInfo
        print("   UserInfo: \(userInfo)")

        if let type = userInfo["type"] as? String,
           let appId = userInfo["appId"] as? String {

            print("   Type: \(type), AppId: \(appId)")

            if type == "reminder" {
                // Show intent prompt when user taps reminder notification
                print("⏰ [APPDELEGATE] Calling showIntentPromptHandler for app: \(appId)")
                print("   Handler exists: \(showIntentPromptHandler != nil)")
                DispatchQueue.main.async {
                    self.showIntentPromptHandler?(appId)
                    print("   Handler called!")
                }
            }
        } else {
            print("   ❌ Could not extract type or appId from userInfo")
        }

        completionHandler()
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
