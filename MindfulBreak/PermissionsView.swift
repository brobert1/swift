//
//  PermissionsView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import FamilyControls

struct PermissionsView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isRequestingAuth = false
    @State private var showError = false
    @State private var errorMessage = ""

    var selectedApps: [MonitoredApp]
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Final Setup")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Complete these steps to activate Mindful Break")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Checklist
                ScrollView {
                    VStack(spacing: 16) {
                        // Step 1: Screen Time
                        PermissionCard(
                            icon: "hourglass",
                            title: "Enable Screen Time",
                            description: "Grant permission to monitor and manage apps",
                            isCompleted: screenTimeManager.isAuthorized,
                            buttonText: screenTimeManager.isAuthorized ? "Granted" : "Enable",
                            isLoading: isRequestingAuth
                        ) {
                            requestScreenTimeAuth()
                        }

                        // Step 2: Shortcuts Automation
                        ShortcutsSetupCard(apps: selectedApps)

                        // Step 3: Notifications
                        NotificationPermissionCard()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }

                Spacer()

                // Continue button
                Button(action: onContinue) {
                    Text("Complete Setup")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(allPermissionsGranted ? Color.green : Color.gray)
                        .cornerRadius(12)
                }
                .disabled(!allPermissionsGranted)
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var allPermissionsGranted: Bool {
        screenTimeManager.isAuthorized
    }

    private func requestScreenTimeAuth() {
        isRequestingAuth = true
        Task {
            do {
                try await screenTimeManager.requestAuthorization()
            } catch {
                errorMessage = "Failed to authorize Screen Time: \(error.localizedDescription)"
                showError = true
            }
            isRequestingAuth = false
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isCompleted: Bool
    let buttonText: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.system(size: 24))
                        .foregroundColor(isCompleted ? .white : .blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if !isCompleted {
                Button(action: action) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        } else {
                            Text(buttonText)
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct ShortcutsSetupCard: View {
    let apps: [MonitoredApp]
    @State private var completedApps: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.orange.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: isCompleted ? "checkmark" : "link")
                        .font(.system(size: 24))
                        .foregroundColor(isCompleted ? .white : .orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Up Automations")
                        .font(.system(size: 18, weight: .semibold))

                    Text("Create shortcuts for each monitored app")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            if !isCompleted {
                VStack(spacing: 8) {
                    Text("Tap 'Set Up' for each app to create an automation in Shortcuts")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)

                    ForEach(apps) { app in
                        HStack {
                            // Use FamilyControls Label to show app name
                            Label(app.token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 15))

                            Spacer()

                            if completedApps.contains(app.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Button("Set Up") {
                                    openShortcuts(for: app)
                                    // Mock completion for now
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        completedApps.insert(app.id)
                                    }
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.orange)
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Color(uiColor: .tertiarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var isCompleted: Bool {
        completedApps.count == apps.count && !apps.isEmpty
    }

    private func openShortcuts(for app: MonitoredApp) {
        // This will open the Shortcuts app
        // In production, you'd construct a more specific URL
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

struct NotificationPermissionCard: View {
    @State private var isAuthorized = false
    @State private var isChecking = false

    var body: some View {
        PermissionCard(
            icon: "bell.fill",
            title: "Enable Notifications",
            description: "Get reminders and completion alerts",
            isCompleted: isAuthorized,
            buttonText: "Enable",
            isLoading: isChecking
        ) {
            requestNotificationAuth()
        }
        .onAppear {
            checkNotificationStatus()
        }
    }

    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestNotificationAuth() {
        isChecking = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                isAuthorized = granted
                isChecking = false
            }
        }
    }
}

#Preview {
    PermissionsView(
        selectedApps: [],
        onContinue: {}
    )
}
