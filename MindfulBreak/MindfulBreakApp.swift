//
//  MindfulBreakApp.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

@main
struct MindfulBreakApp: App {
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingContainerView()
            }
        }
    }
}
