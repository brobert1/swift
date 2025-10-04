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
//
//  IntentPromptView.swift
//  MindfulBreak
//
//  Screen that asks users why they're opening the app
//

import SwiftUI

struct IntentPromptView: View {
    let appId: String
    let onDismiss: () -> Void

    @State private var userIntent: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))

                // Title
                Text("Why are you opening this app?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Subtitle
                Text("Take a moment to reflect on your intention")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Text field
                VStack(alignment: .leading, spacing: 8) {
                    TextField("", text: $userIntent, prompt: Text("I'm opening this app because...").foregroundColor(.gray))
                        .focused($isTextFieldFocused)
                        .padding()
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .background(Color(white: 0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.3), lineWidth: 1)
                        )

                    if userIntent.count > 0 {
                        Text("\(userIntent.count) characters")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                Spacer()

                // Continue button
                Button(action: {
                    saveIntent()
                    onDismiss()
                }) {
                    Text(userIntent.isEmpty ? "Skip" : "Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(userIntent.isEmpty ? .white : .black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userIntent.isEmpty ? Color(white: 0.25) : Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Auto-focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    private func saveIntent() {
        guard !userIntent.isEmpty else { return }

        // Save the user's intent to App Group storage
        if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
            // Get existing intents for this app
            var intents = defaults.array(forKey: "intents_\(appId)") as? [[String: Any]] ?? []

            // Add new intent with timestamp
            let intentData: [String: Any] = [
                "text": userIntent,
                "timestamp": Date().timeIntervalSince1970
            ]
            intents.append(intentData)

            // Keep only last 20 intents
            if intents.count > 20 {
                intents = Array(intents.suffix(20))
            }

            defaults.set(intents, forKey: "intents_\(appId)")
            defaults.synchronize()

            print("✅ Saved user intent: \(userIntent)")
        }
    }
}

#Preview {
    IntentPromptView(appId: "test", onDismiss: {})
}
