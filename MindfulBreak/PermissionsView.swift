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
    @StateObject private var dataStore = DataStore.shared
    @State private var isRequestingAuth = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var monitoringEnabled = false

    var onContinue: () -> Void

    // Get apps from DataStore instead of coordinator
    private var selectedApps: [MonitoredApp] {
        dataStore.monitoredApps
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Final Setup")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Enable notifications to get notified when apps are blocked")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                Spacer()

                // Notification Permission
                VStack(spacing: 16) {
                    NotificationPermissionCard()
                }
                .padding(.horizontal, 16)

                Spacer()

                // Continue button
                Button(action: {
                    enableMonitoring()
                    onContinue()
                }) {
                    Text("Complete Setup")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Auto-enable monitoring when view appears
            if screenTimeManager.isAuthorized && !monitoringEnabled {
                enableMonitoring()
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private var allPermissionsGranted: Bool {
        screenTimeManager.isAuthorized && monitoringEnabled
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

    private func enableMonitoring() {
        guard screenTimeManager.isAuthorized else {
            errorMessage = "Please enable Screen Time first"
            showError = true
            return
        }

        // Start DeviceActivity monitoring with thresholds
        // This monitors REAL iOS usage and shields apps when limits are reached
        screenTimeManager.startMonitoring(for: selectedApps)
        dataStore.setMonitoringActive(true)
        monitoringEnabled = true

        print("✅ Started monitoring \(selectedApps.count) apps with DeviceActivity")
        print("   Apps will be shielded when they reach their daily limits")
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
                        .fill(isCompleted ? Color.green : Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.3))
                        .frame(width: 50, height: 50)

                    Image(systemName: isCompleted ? "checkmark" : icon)
                        .font(.system(size: 24))
                        .foregroundColor(isCompleted ? .white : Color(red: 0.55, green: 0.5, blue: 0.7))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
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
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                    .cornerRadius(10)
                }
                .disabled(isLoading)
            }
        }
        .padding(20)
        .background(Color(white: 0.15))
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
                        .fill(isCompleted ? Color.green : Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.3))
                        .frame(width: 50, height: 50)

                    Image(systemName: isCompleted ? "checkmark" : "link")
                        .font(.system(size: 24))
                        .foregroundColor(isCompleted ? .white : Color(red: 0.55, green: 0.5, blue: 0.7))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Up Automations")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Create shortcuts for each monitored app")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            if !isCompleted {
                VStack(spacing: 8) {
                    Text("Tap 'Set Up' for each app to create an automation in Shortcuts")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
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
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                                .cornerRadius(8)
                            }
                        }
                        .padding(12)
                        .background(Color(white: 0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(white: 0.15))
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

struct MonitoringPermissionCard: View {
    let isEnabled: Bool
    let onEnable: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? Color.green : Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.3))
                        .frame(width: 50, height: 50)

                    Image(systemName: isEnabled ? "checkmark" : "clock.arrow.circlepath")
                        .font(.system(size: 24))
                        .foregroundColor(isEnabled ? .white : Color(red: 0.55, green: 0.5, blue: 0.7))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Activate Monitoring")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Start 24/7 tracking of your selected apps")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            if !isEnabled {
                Text("Neura will monitor your app usage and automatically shield apps when you reach your daily limits. You can always adjust settings later.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.bottom, 8)

                Button(action: onEnable) {
                    Text("Enable Monitoring")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(10)
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("24/7 monitoring is active")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(white: 0.15))
        .cornerRadius(16)
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
    PermissionsView(onContinue: {})
}
