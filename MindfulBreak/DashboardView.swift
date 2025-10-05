//
//  DashboardView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import FamilyControls

struct DashboardView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            StatusView()
                .tabItem {
                    Label("Status", systemImage: "chart.bar.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(1)
        }
    }
}

struct StatusView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared

    // Only show enabled apps in the dashboard
    private var enabledApps: [MonitoredApp] {
        dataStore.monitoredApps.filter { $0.isEnabled }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                VStack(spacing: 8) {
                    Text("Monitored Apps")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("iOS tracks your usage automatically")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                    .padding(.top, 20)

                    // Monitoring Status Card
                    MonitoringStatusCard(
                        isMonitoring: dataStore.isMonitoringActive,
                        isShielded: screenTimeManager.areAppsShielded
                    )
                    .padding(.horizontal, 16)

                    if enabledApps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "shield.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No apps being protected")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)

                            Text("Add apps in Settings to start")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 100)
                    } else {
                        // App cards with countdown timers - only show enabled apps
                        ForEach(enabledApps) { app in
                            AppCountdownCard(app: app)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .background(Color.black)
        }
    }
}

struct AppCountdownCard: View {
    let app: MonitoredApp
    @State private var isShielded: Bool = false
    @State private var showChallenge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Real app icon
                Label(app.token)
                    .labelStyle(.iconOnly)
                    .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    // Real app name
                    Label(app.token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 18, weight: .semibold))

                    HStack(spacing: 4) {
                        Image(systemName: isShielded ? "lock.shield.fill" : "hourglass")
                            .font(.system(size: 12))
                        Text(isShielded ? "Limit Reached" : "Monitoring Active")
                            .font(.system(size: 14))
                            .lineLimit(1)
                    }
                    .foregroundColor(isShielded ? .red : .green)
                }

                Spacer()

                // Daily limit badge
                VStack(spacing: 2) {
                    Text("\(app.timeLimitInMinutes)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("min limit")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Info message
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))

                Text(isShielded ?
                     "iOS is tracking usage. Will shield when limit is reached." :
                     "iOS is tracking usage. Will shield when limit is reached.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.blue.opacity(0.08))
            .cornerRadius(10)

            if isShielded {
                // Minimalist unlock button
                Button(action: {
                    showChallenge = true
                }) {
                    Text("Complete a challenge")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.15))
        .cornerRadius(16)
        .onAppear {
            checkShieldStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh shield status when app comes to foreground
            checkShieldStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Also refresh when app becomes active
            checkShieldStatus()
        }
        .fullScreenCover(isPresented: $showChallenge) {
            ChallengeView(app: app) {
                showChallenge = false
                isShielded = false // Update UI after unlock
            }
        }
    }

    private func checkShieldStatus() {
        if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
            let newShieldState = defaults.bool(forKey: "appShielded_\(app.id)")
            if newShieldState != isShielded {
                print("🔄 Shield status changed for \(app.id): \(newShieldState)")
            }
            isShielded = newShieldState
        }
    }
}

struct SettingsView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared
    @State private var showEditApps = false
    @State private var showEditInterests = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("24/7 Monitoring")
                                .font(.system(size: 16, weight: .medium))
                            Text(dataStore.isMonitoringActive ? "Active" : "Paused")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: .init(
                            get: { dataStore.isMonitoringActive },
                            set: { newValue in
                                if newValue {
                                    screenTimeManager.startMonitoring(for: dataStore.monitoredApps)
                                    dataStore.setMonitoringActive(true)
                                } else {
                                    screenTimeManager.stopMonitoring()
                                    dataStore.setMonitoringActive(false)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Protection")
                } footer: {
                    Text("When enabled, iOS monitors your app usage. Apps will be automatically shielded when you reach your daily limits.")
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Testing Mode")
                                .font(.system(size: 16, weight: .medium))
                            Text(dataStore.isTestingMode ? "1 minute unlock" : "15 minutes unlock")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Toggle("", isOn: .init(
                            get: { dataStore.isTestingMode },
                            set: { newValue in
                                dataStore.setTestingMode(newValue)
                            }
                        ))
                    }

                    Button(action: {
                        screenTimeManager.unshieldApps()
                    }) {
                        HStack {
                            Image(systemName: "lock.open.fill")
                                .foregroundColor(.green)
                            Text("Unshield All Apps")
                            Spacer()
                        }
                    }

                    Button(action: {
                        screenTimeManager.shieldApps(dataStore.monitoredApps)
                    }) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.orange)
                            Text("Shield All Apps")
                            Spacer()
                        }
                    }
                } header: {
                    Text("Developer & Testing")
                } footer: {
                    Text("Testing Mode: When ON, challenges unlock apps for 1 minute (testing). When OFF, they unlock for 15 minutes (production).\n\nUse the shield/unshield buttons to quickly test without toggling protection.")
                }

                Section("Monitored Apps") {
                    Button(action: {
                        showEditApps = true
                    }) {
                        HStack {
                            Image(systemName: "app.badge")
                                .foregroundColor(.purple)
                            Text("Edit your monitored apps")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section("Interests") {
                    Button(action: {
                        showEditInterests = true
                    }) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                            Text("Update your interests")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showEditApps) {
                EditAppsSheet()
            }
            .sheet(isPresented: $showEditInterests) {
                EditInterestsSheet()
            }
        }
    }
}

// MARK: - Monitoring Status Card

struct MonitoringStatusCard: View {
    let isMonitoring: Bool
    let isShielded: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: statusIcon)
                    .font(.system(size: 26))
                    .foregroundColor(statusColor)
            }

            // Status Text
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            // Status Indicator
            Circle()
                .fill(isMonitoring ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.15))
        .cornerRadius(16)
    }

    private var statusColor: Color {
        if isShielded {
            return .orange
        } else if isMonitoring {
            return .green
        } else {
            return .gray
        }
    }

    private var statusIcon: String {
        if isShielded {
            return "shield.lefthalf.filled"
        } else if isMonitoring {
            return "clock.arrow.circlepath"
        } else {
            return "pause.circle"
        }
    }

    private var statusTitle: String {
        if isShielded {
            return "Apps Shielded"
        } else if isMonitoring {
            return "Monitoring Active"
        } else {
            return "Monitoring Paused"
        }
    }

    private var statusMessage: String {
        if isShielded {
            return "Apps are locked - complete challenges to unlock"
        } else if isMonitoring {
            return "Your apps are protected and shielded"
        } else {
            return "Enable protection in Settings to shield apps"
        }
    }
}

#Preview {
    DashboardView()
}

// MARK: - Edit Sheets

struct EditAppsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataStore = DataStore.shared
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                AppSelectionView {
                    // Restart monitoring with updated apps
                    if dataStore.isMonitoringActive {
                        screenTimeManager.stopMonitoring()
                        screenTimeManager.startMonitoring(for: dataStore.monitoredApps)
                    }
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct EditInterestsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataStore = DataStore.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                InterestSelectionView {
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// Preview removed - requires FamilyControls ApplicationToken
