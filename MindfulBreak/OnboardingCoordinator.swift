//
//  OnboardingCoordinator.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case appSelection
    case interestSelection
    case permissions
    case complete
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
                    coordinator.nextStep()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .permissions:
                PermissionsView {
                    coordinator.nextStep()
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case .complete:
                OnboardingCompleteView {
                    withAnimation {
                        coordinator.completeOnboarding()
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: coordinator.currentStep)
        .fullScreenCover(isPresented: $coordinator.isOnboardingComplete) {
            DashboardView()
        }
    }
}

#Preview {
    OnboardingContainerView()
}
