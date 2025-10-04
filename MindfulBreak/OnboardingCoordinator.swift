//
//  OnboardingCoordinator.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import UserNotifications

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case appSelection
    case interestSelection
}

class OnboardingCoordinator: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedApps: [MonitoredApp] = []
    @Published var isOnboardingComplete = false

    func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }
        currentStep = nextIndex
    }

    func previousStep() {
        guard currentStep.rawValue > 0,
              let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = prevIndex
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        // Save to UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

struct OnboardingContainerView: View {
    @StateObject private var coordinator = OnboardingCoordinator()

    var body: some View {
        ZStack {
            switch coordinator.currentStep {
            case .welcome:
                WelcomeView {
                    coordinator.nextStep()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .appSelection:
                AppSelectionView {
                    coordinator.nextStep()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .interestSelection:
                InterestSelectionView {
                    // Request notification permissions
                    requestNotificationPermissions()
                    
                    // Enable monitoring
                    enableMonitoring()
                    
                    // Complete onboarding
                    coordinator.completeOnboarding()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
        .fullScreenCover(isPresented: $coordinator.isOnboardingComplete) {
            DashboardView()
        }
    }
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permissions granted")
                } else {
                    print("⚠️ Notification permissions denied")
                }
            }
        }
    }
    
    private func enableMonitoring() {
        let screenTimeManager = ScreenTimeManager.shared
        let dataStore = DataStore.shared
        
        guard screenTimeManager.isAuthorized else {
            print("⚠️ Screen Time not authorized")
            return
        }
        
        // Start DeviceActivity monitoring with thresholds
        screenTimeManager.startMonitoring(for: dataStore.monitoredApps)
        dataStore.setMonitoringActive(true)
        
        print("✅ Started monitoring \(dataStore.monitoredApps.count) apps")
    }
}

#Preview {
    OnboardingContainerView()
}
