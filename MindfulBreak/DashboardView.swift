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
    @StateObject private var usageManager = UsageDataManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Today's Usage")
                            .font(.system(size: 28, weight: .bold))

                        Text("Track your progress")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Monitoring Status Card
                    MonitoringStatusCard(
                        isMonitoring: dataStore.isMonitoringActive,
                        isShielded: screenTimeManager.areAppsShielded
                    )

                    if dataStore.monitoredApps.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No apps being monitored")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Your tracked apps will appear here")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        // App cards with real usage data
                        ForEach(dataStore.monitoredApps) { app in
                            AppUsageCard(
                                app: app,
                                usedMinutes: usageManager.getUsageInMinutes(for: app.id)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct AppUsageCard: View {
    let app: MonitoredApp
    let usedMinutes: Int

    var progress: Double {
        Double(usedMinutes) / Double(app.timeLimitInMinutes)
    }

    var progressColor: Color {
        if progress < 0.5 { return .green }
        if progress < 0.8 { return .orange }
        return .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Real app icon
                Label(app.token)
                    .labelStyle(.iconOnly)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    // Real app name
                    Label(app.token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 18, weight: .semibold))

                    Text("\(usedMinutes) of \(app.timeLimitInMinutes) min used")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(progressColor)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressColor)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct SettingsView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared
    @State private var extensionLogs: [String] = []

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
                    Text("When enabled, apps will be automatically shielded when you reach your daily time limits.")
                }

                Section {
                    HStack {
                        Text("Extension Status")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Circle()
                            .fill(extensionLogs.isEmpty ? Color.red : Color.green)
                            .frame(width: 12, height: 12)
                        Text(extensionLogs.isEmpty ? "Not Running" : "Active")
                            .font(.system(size: 14))
                            .foregroundColor(extensionLogs.isEmpty ? .red : .green)
                    }

                    if !extensionLogs.isEmpty {
                        DisclosureGroup("Extension Logs (\(extensionLogs.count))") {
                            ForEach(extensionLogs.reversed(), id: \.self) { log in
                                Text(log)
                                    .font(.system(size: 12).monospaced())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(action: loadExtensionLogs) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Extension Status")
                        }
                    }
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Check if the DeviceActivityMonitor extension is running. Logs appear when monitoring events occur.")
                }

                Section("Monitored Apps") {
                    Text("Edit your monitored apps")
                        .foregroundColor(.blue)
                }

                Section("Interests") {
                    Text("Update your interests")
                        .foregroundColor(.blue)
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
            .onAppear {
                loadExtensionLogs()
            }
        }
    }

    private func loadExtensionLogs() {
        if let appGroupDefaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared"),
           let logs = appGroupDefaults.array(forKey: "extensionLogs") as? [String] {
            extensionLogs = logs
        } else {
            extensionLogs = []
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
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
            }

            // Status Text
            VStack(alignment: .leading, spacing: 4) {
                Text(statusTitle)
                    .font(.system(size: 18, weight: .semibold))

                Text(statusMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Indicator
            Circle()
                .fill(isMonitoring ? Color.green : Color.gray)
                .frame(width: 12, height: 12)
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
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
            return "Time limit reached - complete a challenge to unlock"
        } else if isMonitoring {
            return "Tracking your app usage 24/7"
        } else {
            return "Enable monitoring in Settings to start tracking"
        }
    }
}

#Preview {
    DashboardView()
}
