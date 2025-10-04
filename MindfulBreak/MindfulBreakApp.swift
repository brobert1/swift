//
//  MindfulBreakApp.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import UserNotifications
import FamilyControls

@main
struct MindfulBreakApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var showIntentPrompt = false
    @State private var showChallenge = false
    @State private var promptAppId: String?
    @State private var challengeAppId: String?
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
                    print("🎯 [APP] Intent prompt handler called with appId: \(appId)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.promptAppId = appId
                        withAnimation {
                            self.showIntentPrompt = true
                        }
                    }
                }
                
                appDelegate.showChallengeHandler = { appId in
                    print("🎯 [APP] Challenge handler called with appId: \(appId)")
                    DispatchQueue.main.async {
                        self.challengeAppId = appId
                        self.showChallenge = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showChallenge) {
                if let appId = challengeAppId,
                   let app = DataStore.shared.monitoredApps.first(where: { $0.id == appId }) {
                    ChallengeView(app: app) {
                        showChallenge = false
                        challengeAppId = nil
                    }
                }
            }
        }
    }
}

// AppDelegate to handle notifications
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var showIntentPromptHandler: ((String) -> Void)?
    var showChallengeHandler: ((String) -> Void)?

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

        if let type = userInfo["type"] as? String {
            print("   Type: \(type)")

            if type == "reminder", let appId = userInfo["appId"] as? String {
                // Show intent prompt when user taps reminder notification
                print("⏰ [APPDELEGATE] Calling showIntentPromptHandler for app: \(appId)")
                DispatchQueue.main.async {
                    self.showIntentPromptHandler?(appId)
                }
            } else if type == "limit" || type == "shield_tapped" {
                // Show challenge when user taps time's up notification
                print("🎯 [APPDELEGATE] Calling showChallengeHandler")
                
                // Try to get appId from userInfo, or find first shielded app
                var targetAppId: String?
                if let appId = userInfo["appId"] as? String {
                    targetAppId = appId
                } else {
                    // Find first shielded app
                    if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared"),
                       let monitoredAppsData = defaults.data(forKey: "monitoredApps"),
                       let apps = try? JSONDecoder().decode([MonitoredAppCodable].self, from: monitoredAppsData) {
                        targetAppId = apps.first(where: { 
                            defaults.bool(forKey: "appShielded_\($0.id)")
                        })?.id
                    }
                }
                
                if let appId = targetAppId {
                    print("   AppId: \(appId)")
                    DispatchQueue.main.async {
                        self.showChallengeHandler?(appId)
                    }
                } else {
                    print("   ❌ No shielded app found")
                }
            }
        } else {
            print("   ❌ Could not extract type from userInfo")
        }

        completionHandler()
    }
    
    // Helper struct to decode monitored apps
    private struct MonitoredAppCodable: Codable {
        let id: String
        let token: ApplicationToken
        let timeLimitInMinutes: Int
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
