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
    @StateObject private var dataStore = DataStore.shared
    @State private var isPickerPresented = false
    @State private var selectedAppsForPicker = FamilyActivitySelection()
    @State private var monitoredApps: [MonitoredApp] = []
    @State private var isRequestingAuth = false
    @State private var showAuthError = false

    var onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose Your Apps")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Select the apps you want to manage and set daily limits")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
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
                            .foregroundColor(.gray)

                        Text("Tap the button below to choose apps to monitor")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(monitoredApps.indices, id: \.self) { index in
                                AppRowView(app: $monitoredApps[index])
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
                        requestAuthAndShowPicker()
                    }) {
                        HStack {
                            if isRequestingAuth {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                Text("Requesting Access...")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: monitoredApps.isEmpty ? "plus.circle.fill" : "pencil.circle.fill")
                                    .font(.system(size: 20))
                                Text(monitoredApps.isEmpty ? "Select Apps" : "Edit Selection")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(monitoredApps.isEmpty ? .black : .white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(monitoredApps.isEmpty ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color(white: 0.25))
                        .cornerRadius(12)
                    }
                    .disabled(isRequestingAuth)

                    if !monitoredApps.isEmpty {
                        Button(action: {
                            // Save monitored apps to persistent storage
                            dataStore.saveMonitoredApps(monitoredApps)
                            onContinue()
                        }) {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.55, green: 0.5, blue: 0.7))
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
        .onChange(of: isPickerPresented) { isPresented in
            // Only update when picker is dismissed (goes from true to false)
            if !isPresented {
                updateMonitoredApps(from: selectedAppsForPicker)
            }
        }
        .alert("Authorization Required", isPresented: $showAuthError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please grant Screen Time access to select apps")
        }
    }

    private func requestAuthAndShowPicker() {
        // Check if already authorized
        if screenTimeManager.isAuthorized {
            // Pre-populate the picker with currently selected apps
            var selection = FamilyActivitySelection()
            selection.applicationTokens = Set(monitoredApps.map { $0.token })
            selectedAppsForPicker = selection
            isPickerPresented = true
            return
        }

        // Request authorization first
        isRequestingAuth = true
        Task {
            do {
                try await screenTimeManager.requestAuthorization()
                // Authorization successful, show picker
                await MainActor.run {
                    isRequestingAuth = false
                    if screenTimeManager.isAuthorized {
                        // Pre-populate the picker with currently selected apps
                        var selection = FamilyActivitySelection()
                        selection.applicationTokens = Set(monitoredApps.map { $0.token })
                        selectedAppsForPicker = selection
                        isPickerPresented = true
                    } else {
                        showAuthError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isRequestingAuth = false
                    showAuthError = true
                }
            }
        }
    }

    private func updateMonitoredApps(from selection: FamilyActivitySelection) {
        // Create a stable identifier for each token by encoding it
        func tokenIdentifier(_ token: some Encodable) -> String? {
            guard let data = try? JSONEncoder().encode(token) else { return nil }
            return data.base64EncodedString()
        }
        
        // Build a map of existing apps by their token identifier
        var existingAppsById: [String: MonitoredApp] = [:]
        for app in monitoredApps {
            if let identifier = tokenIdentifier(app.token) {
                existingAppsById[identifier] = app
            }
        }
        
        // Build new array, preserving existing apps and their settings
        var apps: [MonitoredApp] = []
        
        for token in selection.applicationTokens {
            guard let identifier = tokenIdentifier(token) else { continue }
            
            if let existingApp = existingAppsById[identifier] {
                // Keep existing app with its settings (time limit, enabled state, etc.)
                apps.append(existingApp)
            } else {
                // Create new app for newly selected token
                // Use the token identifier as the ID for consistency
                let app = MonitoredApp(
                    id: identifier,
                    token: token,
                    timeLimitInMinutes: 1, // Default: 1 min for testing (change to 25 for production)
                    isEnabled: true
                )
                apps.append(app)
            }
        }

        monitoredApps = apps
        screenTimeManager.selectedApps = selection.applicationTokens
    }
}

struct AppRowView: View {
    @Binding var app: MonitoredApp

    // Available time limits in minutes
    let timeLimitOptions = [1, 15, 30, 45, 60, 120, 300, 600, 1440] // 1min, 15min, 30min, 45min, 1h, 2h, 5h, 10h, 24h

    var timeLimitDisplay: String {
        if app.timeLimitInMinutes < 60 {
            return "\(app.timeLimitInMinutes) min"
        } else if app.timeLimitInMinutes < 1440 {
            let hours = app.timeLimitInMinutes / 60
            return "\(hours)h"
        } else {
            return "24h"
        }
    }

    var currentIndex: Int {
        timeLimitOptions.firstIndex(of: app.timeLimitInMinutes) ?? 1
    }

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

                    Text("\(timeLimitDisplay) daily")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Toggle("", isOn: $app.isEnabled)
                    .labelsHidden()
                    .onChange(of: app.isEnabled) { newValue in
                        print("Toggle changed to: \(newValue)")
                    }
            }
            .padding(16)

            if app.isEnabled {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))

                    HStack {
                        Text("Daily Limit")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                let newIndex = max(0, currentIndex - 1)
                                app.timeLimitInMinutes = timeLimitOptions[newIndex]
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(currentIndex > 0 ? Color(red: 0.55, green: 0.5, blue: 0.7) : .gray)
                            }
                            .disabled(currentIndex <= 0)
                            .buttonStyle(.plain)

                            Text(timeLimitDisplay)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(minWidth: 70)

                            Button(action: {
                                let newIndex = min(timeLimitOptions.count - 1, currentIndex + 1)
                                app.timeLimitInMinutes = timeLimitOptions[newIndex]
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(currentIndex < timeLimitOptions.count - 1 ? Color(red: 0.55, green: 0.5, blue: 0.7) : .gray)
                            }
                            .disabled(currentIndex >= timeLimitOptions.count - 1)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(white: 0.15))
        .cornerRadius(12)
    }
}

#Preview {
    AppSelectionView(onContinue: {})
}
