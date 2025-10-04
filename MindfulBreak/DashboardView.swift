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

                    // Monitoring Control Card
                    MonitoringControlCard(
                        isMonitoring: dataStore.isMonitoringActive,
                        isShielded: screenTimeManager.areAppsShielded,
                        onStartMonitoring: {
                            screenTimeManager.startMonitoring(for: dataStore.monitoredApps)
                            dataStore.setMonitoringActive(true)
                        },
                        onStopMonitoring: {
                            screenTimeManager.stopMonitoring()
                            dataStore.setMonitoringActive(false)
                        },
                        onToggleShield: {
                            screenTimeManager.toggleShield(for: dataStore.monitoredApps)
                        }
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
                        // App cards
                        ForEach(dataStore.monitoredApps) { app in
                            AppUsageCard(app: app)
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
    @State private var usedMinutes: Int = Int.random(in: 0...60)

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
    var body: some View {
        NavigationStack {
            List {
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
        }
    }
}

// MARK: - Monitoring Control Card

struct MonitoringControlCard: View {
    let isMonitoring: Bool
    let isShielded: Bool
    let onStartMonitoring: () -> Void
    let onStopMonitoring: () -> Void
    let onToggleShield: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Protection Status")
                        .font(.system(size: 18, weight: .semibold))

                    Text(statusText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Circle()
                    .fill(isMonitoring ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
            }

            Divider()

            // Monitoring Toggle
            HStack {
                Text("Active Monitoring")
                    .font(.system(size: 16))

                Spacer()

                Button(action: isMonitoring ? onStopMonitoring : onStartMonitoring) {
                    Text(isMonitoring ? "Stop" : "Start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(isMonitoring ? Color.red : Color.green)
                        .cornerRadius(8)
                }
            }

            // Manual Shield Toggle (for testing)
            HStack {
                Text("Shield Apps Now")
                    .font(.system(size: 16))

                Spacer()

                Button(action: onToggleShield) {
                    Text(isShielded ? "Unshield" : "Shield")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(isShielded ? Color.orange : Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal, 16)
    }

    private var statusText: String {
        if isMonitoring && isShielded {
            return "Monitoring active, apps shielded"
        } else if isMonitoring {
            return "Monitoring active"
        } else if isShielded {
            return "Apps shielded, monitoring inactive"
        } else {
            return "Protection inactive"
        }
    }
}

#Preview {
    DashboardView()
}
