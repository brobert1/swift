//
//  AppSelectionView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isPickerPresented = false
    @State private var selectedAppsForPicker = FamilyActivitySelection()
    @State private var monitoredApps: [MonitoredApp] = []

    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Your Apps")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Select the apps you want to manage and set daily limits")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                // App List
                if monitoredApps.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()

                        Image(systemName: "app.badge.checkmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No apps selected")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("Tap the button below to choose apps to monitor")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach($monitoredApps) { $app in
                                AppRowView(app: $app)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100)
                    }
                }

                Spacer()

                // Bottom buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: monitoredApps.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                                .font(.system(size: 20))
                            Text(monitoredApps.isEmpty ? "Select Apps" : "Edit Selection")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    if !monitoredApps.isEmpty {
                        Button(action: onContinue) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .familyActivityPicker(
            isPresented: $isPickerPresented,
            selection: $selectedAppsForPicker
        )
        .onChange(of: selectedAppsForPicker) { newSelection in
            updateMonitoredApps(from: newSelection)
        }
    }

    private func updateMonitoredApps(from selection: FamilyActivitySelection) {
        // Convert FamilyActivitySelection to MonitoredApp array
        var apps: [MonitoredApp] = []

        for token in selection.applicationTokens {
            let appId = token.hashValue.description
            let app = MonitoredApp(
                id: appId,
                token: token,
                timeLimitInMinutes: 60,
                isEnabled: true
            )
            apps.append(app)
        }

        monitoredApps = apps
        screenTimeManager.selectedApps = selection.applicationTokens
    }
}

struct AppRowView: View {
    @Binding var app: MonitoredApp

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Real app icon using Label from FamilyControls
                Label(app.token)
                    .labelStyle(.iconOnly)
                    .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 4) {
                    // Real app name using Label from FamilyControls
                    Label(app.token)
                        .labelStyle(.titleOnly)
                        .font(.system(size: 16, weight: .semibold))

                    Text("\(app.timeLimitInMinutes) min daily")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: $app.isEnabled)
                    .labelsHidden()
            }
            .padding(16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)

            if app.isEnabled {
                VStack(spacing: 12) {
                    Divider()
                        .padding(.horizontal, 16)

                    HStack {
                        Text("Daily Limit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                if app.timeLimitInMinutes > 15 {
                                    app.timeLimitInMinutes -= 15
                                }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(app.timeLimitInMinutes > 15 ? .blue : .gray)
                            }
                            .disabled(app.timeLimitInMinutes <= 15)

                            Text("\(app.timeLimitInMinutes) min")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(minWidth: 70)

                            Button(action: {
                                if app.timeLimitInMinutes < 240 {
                                    app.timeLimitInMinutes += 15
                                }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(app.timeLimitInMinutes < 240 ? .blue : .gray)
                            }
                            .disabled(app.timeLimitInMinutes >= 240)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
        .cornerRadius(12)
    }
}

#Preview {
    AppSelectionView(onContinue: {})
}
