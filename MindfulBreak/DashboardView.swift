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
                        Text("Monitored Apps")
                            .font(.system(size: 28, weight: .bold))

                        Text("iOS tracks your usage automatically")
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
                            Image(systemName: "shield.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No apps being protected")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.secondary)

                            Text("Add apps in Settings to start")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        // App cards with countdown timers
                        ForEach(dataStore.monitoredApps) { app in
                            AppCountdownCard(app: app)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

struct AppCountdownCard: View {
    let app: MonitoredApp
    @State private var isShielded: Bool = false
    @State private var showChallenge: Bool = false

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

                    HStack(spacing: 4) {
                        Image(systemName: isShielded ? "lock.shield.fill" : "hourglass")
                            .font(.system(size: 12))
                        Text(isShielded ? "Limit Reached - Shielded" : "Monitoring Active")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(isShielded ? .red : .green)
                }

                Spacer()

                // Daily limit
                VStack(spacing: 4) {
                    Text("\(app.timeLimitInMinutes)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    Text("min limit")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            // Info message
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))

                Text(isShielded ?
                     "App is blocked. Complete a challenge to unlock." :
                     "iOS is tracking usage. Will shield when limit is reached.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            if isShielded {
                // Unlock button - shows challenge
                Button(action: {
                    showChallenge = true
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Complete Challenge to Unlock")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .onAppear {
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
            isShielded = defaults.bool(forKey: "appShielded_\(app.id)")
        }
    }
}

struct SettingsView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared

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
                    Text("Testing")
                } footer: {
                    Text("Use these buttons to quickly test shielding/unshielding without toggling protection.")
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

// Add ChallengeView here temporarily until it's added to the project
// Will be moved to separate file later
//
//  ChallengeView.swift
//  MindfulBreak
//
//  Challenge screen shown when user wants to unlock a shielded app
//

import SwiftUI

struct ChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared

    @State private var scrollOffset: CGFloat = 0
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    @State private var hasScrolledToBottom = false
    @State private var showSuccess = false

    let app: MonitoredApp
    let onComplete: () -> Void

    var unlockTimeDisplay: String {
        if app.timeLimitInMinutes < 60 {
            return "\(app.timeLimitInMinutes) minute\(app.timeLimitInMinutes > 1 ? "s" : "")"
        } else if app.timeLimitInMinutes < 1440 {
            let hours = app.timeLimitInMinutes / 60
            return "\(hours) hour\(hours > 1 ? "s" : "")"
        } else {
            return "24 hours"
        }
    }

    var isScrolledToBottom: Bool {
        let bottomThreshold: CGFloat = 50
        return (contentHeight - scrollViewHeight - scrollOffset) <= bottomThreshold
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)

                    Text("Unlock Challenge")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Read the entire text below to unlock \(unlockTimeDisplay) of access")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)

                // Scrollable content
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Why Mindful Usage Matters")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(mindfulnessText)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.95))
                                .lineSpacing(6)

                            Spacer(minLength: 40)

                            // Bottom marker
                            HStack {
                                Spacer()
                                Image(systemName: hasScrolledToBottom ? "checkmark.circle.fill" : "arrow.down.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(hasScrolledToBottom ? .green : .white.opacity(0.5))
                                    .id("bottom")
                                Spacer()
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(24)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ContentHeightKey.self,
                                    value: geo.size.height
                                )
                            }
                        )
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(20)
                    .padding(.horizontal, 20)
                    .background(
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollViewHeightKey.self,
                                value: geo.size.height
                            )
                        }
                    )
                    .onPreferenceChange(ContentHeightKey.self) { height in
                        contentHeight = height
                        checkIfScrolledToBottom()
                    }
                    .onPreferenceChange(ScrollViewHeightKey.self) { height in
                        scrollViewHeight = height
                        checkIfScrolledToBottom()
                    }
                    .onAppear {
                        // Monitor scroll position
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: isScrolledToBottom) { scrolledToBottom in
                        if scrolledToBottom && !hasScrolledToBottom {
                            hasScrolledToBottom = true
                            // Haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    }
                }

                // Complete button
                Button(action: completeChallenge) {
                    HStack {
                        if hasScrolledToBottom {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Unlock Now")
                        } else {
                            Image(systemName: "arrow.down.circle")
                            Text("Scroll to Bottom First")
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(hasScrolledToBottom ? Color.green : Color.gray)
                    .cornerRadius(16)
                }
                .disabled(!hasScrolledToBottom)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }

            if showSuccess {
                SuccessOverlay(unlockTime: unlockTimeDisplay)
            }
        }
    }

    private func checkIfScrolledToBottom() {
        // Auto-detect if content is already fully visible
        if contentHeight <= scrollViewHeight {
            hasScrolledToBottom = true
        }
    }

    private func completeChallenge() {
        print("✅ Challenge completed! Unlocking for \(unlockTimeDisplay)...")

        // Show success animation
        showSuccess = true

        // Unshield apps temporarily
        screenTimeManager.unshieldApps()

        // Schedule re-shield after the app's time limit (in seconds)
        let unlockSeconds = TimeInterval(app.timeLimitInMinutes * 60)
        DispatchQueue.main.asyncAfter(deadline: .now() + unlockSeconds) {
            print("⏱️ \(self.unlockTimeDisplay) expired - re-shielding apps")
            screenTimeManager.shieldApps(dataStore.monitoredApps)
        }

        // Dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onComplete()
            dismiss()
        }
    }

    private var mindfulnessText: String {
        """
        Taking breaks from social media and other distracting apps is essential for your mental well-being and productivity.

        Studies have shown that excessive screen time can lead to:

        • Decreased attention span and focus
        • Disrupted sleep patterns
        • Increased anxiety and stress
        • Reduced face-to-face social interactions
        • Lower overall life satisfaction

        The Science Behind Digital Wellness:

        Research from Stanford University indicates that constant notifications and app-checking behavior create a dopamine feedback loop that can be addictive. Each time you check your phone, your brain releases small amounts of dopamine, reinforcing the behavior.

        Benefits of Mindful App Usage:

        1. Improved Mental Clarity: Taking regular breaks from social media allows your brain to reset and process information more effectively.

        2. Better Sleep Quality: Reducing screen time, especially before bed, helps regulate your circadian rhythm and improve sleep quality.

        3. Enhanced Productivity: Focused work sessions without constant digital interruptions can improve your output by up to 40%.

        4. Stronger Relationships: More time away from screens means more quality time with friends, family, and yourself.

        5. Reduced Anxiety: Studies show that limiting social media use can significantly decrease feelings of anxiety and FOMO (fear of missing out).

        Remember: This challenge isn't about punishment—it's about helping you build healthier digital habits. By unlocking this app for just 1 minute of extra use, you're practicing mindful decision-making.

        Use this time wisely, and remember that real life happens outside the screen.

        You've reached the end! Great job taking the time to read this.
        """
    }
}

struct SuccessOverlay: View {
    let unlockTime: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)

                Text("Challenge Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Unlocked for \(unlockTime)")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.2))
            )
        }
    }
}

// Helper preference keys for measuring scroll
struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ScrollViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preview removed - requires FamilyControls ApplicationToken
