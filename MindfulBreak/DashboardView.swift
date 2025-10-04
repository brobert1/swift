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

//
//  ChallengeView.swift
//  MindfulBreak
//
//  Challenge screen shown when user wants to unlock a shielded app
//

import SwiftUI

// Challenge types enum
enum ChallengeType: Int, CaseIterable {
    case breathing = 0
    case gratitude = 1
    case eyeRest = 2
    case intention = 3
    case movement = 4
    case reading = 5
    
    var title: String {
        switch self {
        case .breathing: return "Deep Breathing"
        case .gratitude: return "Gratitude Moment"
        case .eyeRest: return "Eye Rest"
        case .intention: return "Set Your Intention"
        case .movement: return "Movement Break"
        case .reading: return "Mindful Reading"
        }
    }
    
    var icon: String {
        switch self {
        case .breathing: return "wind"
        case .gratitude: return "heart.fill"
        case .eyeRest: return "eye.fill"
        case .intention: return "lightbulb.fill"
        case .movement: return "figure.walk"
        case .reading: return "book.fill"
        }
    }
    
    var description: String {
        switch self {
        case .breathing: return "Follow the breathing pattern to center yourself"
        case .gratitude: return "Reflect on what you're grateful for today"
        case .eyeRest: return "Give your eyes a break from the screen"
        case .intention: return "Consider why you want to use this app"
        case .movement: return "Stretch and move your body"
        case .reading: return "Read and reflect on this mindful message"
        }
    }
}

struct ChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @StateObject private var dataStore = DataStore.shared
    @State private var showSuccess = false
    @State private var selectedChallenge: ChallengeType
    
    let app: MonitoredApp
    let onComplete: () -> Void
    
    init(app: MonitoredApp, onComplete: @escaping () -> Void) {
        self.app = app
        self.onComplete = onComplete
        
        // Select random challenge, avoiding the last one shown
        let lastChallenge = UserDefaults.standard.integer(forKey: "lastChallengeIndex")
        var randomChallenge: ChallengeType
        
        repeat {
            randomChallenge = ChallengeType.allCases.randomElement() ?? .breathing
        } while randomChallenge.rawValue == lastChallenge && ChallengeType.allCases.count > 1
        
        _selectedChallenge = State(initialValue: randomChallenge)
        
        // Save for next time
        UserDefaults.standard.set(randomChallenge.rawValue, forKey: "lastChallengeIndex")
    }
    
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
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: selectedChallenge.icon)
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
                    }
                    
                    Text(selectedChallenge.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(selectedChallenge.description)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)
                
                // Challenge content
                Group {
                    switch selectedChallenge {
                    case .breathing:
                        BreathingChallengeView(onComplete: completeChallenge)
                    case .gratitude:
                        GratitudeChallengeView(onComplete: completeChallenge)
                    case .eyeRest:
                        EyeRestChallengeView(onComplete: completeChallenge)
                    case .intention:
                        IntentionChallengeView(onComplete: completeChallenge)
                    case .movement:
                        MovementChallengeView(onComplete: completeChallenge)
                    case .reading:
                        ReadingChallengeView(onComplete: completeChallenge)
                    }
                }
            }
            
            if showSuccess {
                SuccessOverlay(unlockTime: unlockTimeDisplay)
            }
        }
    }
    
    private func completeChallenge() {
        print("✅ Challenge completed! Unlocking for \(unlockTimeDisplay)...")

        // Show success animation
        showSuccess = true

        // Unshield apps temporarily
        screenTimeManager.unshieldApps()

        // IMPORTANT: Clear the shield status in UserDefaults so UI updates
        if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
            defaults.set(false, forKey: "appShielded_\(app.id)")
            defaults.synchronize()
            print("🔓 Cleared shield status for \(app.id)")
        }

        // Schedule re-shield after the app's time limit (in seconds)
        let unlockSeconds = TimeInterval(app.timeLimitInMinutes * 60)
        print("⏱️ Will re-shield in \(unlockSeconds) seconds (\(unlockTimeDisplay))")

        DispatchQueue.main.asyncAfter(deadline: .now() + unlockSeconds) {
            print("⏱️ \(self.unlockTimeDisplay) expired - re-shielding apps")

            // Re-shield only this specific app
            if let defaults = UserDefaults(suiteName: "group.com.developer.mindfullness.shared") {
                defaults.set(true, forKey: "appShielded_\(self.app.id)")
                defaults.synchronize()
            }

            screenTimeManager.shieldApps([self.app])
        }

        // Dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onComplete()
            dismiss()
        }
    }
}

// MARK: - Breathing Challenge

struct BreathingChallengeView: View {
    @State private var breathingPhase: BreathingPhase = .inhale
    @State private var cyclesCompleted = 0
    @State private var scale: CGFloat = 0.7
    @State private var isComplete = false
    
    let totalCycles = 5
    let onComplete: () -> Void
    
    enum BreathingPhase {
        case inhale, hold, exhale
        
        var instruction: String {
            switch self {
            case .inhale: return "Breathe In"
            case .hold: return "Hold"
            case .exhale: return "Breathe Out"
            }
        }
        
        var duration: Double {
            return 4.0
        }
        
        var next: BreathingPhase {
            switch self {
            case .inhale: return .hold
            case .hold: return .exhale
            case .exhale: return .inhale
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Breathing circle animation
            ZStack {
                Circle()
                    .fill(Color(red: 0.55, green: 0.5, blue: 0.7).opacity(0.3))
                    .frame(width: 250, height: 250)
                    .scaleEffect(scale)
                
                VStack(spacing: 12) {
                    Text(breathingPhase.instruction)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(cyclesCompleted + 1) / \(totalCycles)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            Text("Focus on your breath and let go of distractions")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onComplete) {
                Text(isComplete ? "Continue" : "Breathing...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isComplete ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isComplete ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                    .cornerRadius(16)
            }
            .disabled(!isComplete)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            startBreathingCycle()
        }
    }
    
    private func startBreathingCycle() {
        animateBreathing()
    }
    
    private func animateBreathing() {
        let targetScale: CGFloat = breathingPhase == .inhale ? 1.0 : (breathingPhase == .hold ? 1.0 : 0.7)
        
        withAnimation(.easeInOut(duration: breathingPhase.duration)) {
            scale = targetScale
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + breathingPhase.duration) {
            if breathingPhase == .exhale {
                cyclesCompleted += 1
                if cyclesCompleted >= totalCycles {
                    isComplete = true
                    return
                }
            }
            
            breathingPhase = breathingPhase.next
            animateBreathing()
        }
    }
}

// MARK: - Gratitude Challenge

struct GratitudeChallengeView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Take a moment to reflect...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text(gratitudeText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(6)

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .frame(maxHeight: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            Button(action: onComplete) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private var gratitudeText: String {
        """
        Research shows that practicing gratitude can significantly improve mental health, reduce stress, and increase overall happiness.
        
        Before you return to your app, take a moment to think about:
        
        • Three things you're grateful for today
        • One person who made you smile recently
        • A small moment of joy you might have overlooked
        
        Studies from positive psychology demonstrate that regularly acknowledging what we're thankful for can:
        
        - Improve sleep quality
        - Strengthen relationships
        - Increase resilience to stress
        - Boost overall life satisfaction
        
        This brief pause helps shift your mindset from mindless scrolling to mindful appreciation. By taking a moment to reflect on the good in your life, you're training your brain to notice positive experiences more often.
        
        The simple act of pausing and reflecting can make your phone usage more intentional and less automatic.
        """
    }
}

// MARK: - Eye Rest Challenge

struct EyeRestChallengeView: View {
    @State private var timeRemaining = 20
    @State private var isComplete = false
    
    let onComplete: () -> Void
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color(white: 0.2), lineWidth: 20)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: CGFloat(20 - timeRemaining) / 20)
                    .stroke(
                        Color(red: 0.55, green: 0.5, blue: 0.7),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 8) {
                    Text("\(timeRemaining)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                    Text("seconds")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            
            VStack(spacing: 16) {
                Text("Look away from your screen")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Focus on something 20 feet away to rest your eyes")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text(isComplete ? "Continue" : "Resting...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isComplete ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isComplete ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                    .cornerRadius(16)
            }
            .disabled(!isComplete)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                isComplete = true
            }
        }
    }
}

// MARK: - Intention Challenge

struct IntentionChallengeView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Before you continue...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text(intentionText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(6)

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .frame(maxHeight: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            Button(action: onComplete) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private var intentionText: String {
        """
        Ask yourself these questions:
        
        Why am I opening this app right now?
        
        • Am I looking for something specific?
        • Am I bored or avoiding something?
        • Is this the best use of my time?
        • Will this make me feel better or worse?
        
        Research shows that we pick up our phones over 50 times per day, often without conscious thought. This automatic behavior can lead to:
        
        - Lost productivity
        - Increased anxiety
        - Reduced focus
        - Less meaningful connections
        
        By pausing to set an intention, you're breaking the autopilot cycle. You're choosing to use your phone mindfully rather than mindlessly.
        
        Set a clear intention:
        
        "I'm opening this app to [specific purpose] for [specific time], and then I'll [what comes next]."
        
        This simple practice helps you stay in control of your technology use, rather than letting it control you.
        """
    }
}

// MARK: - Movement Challenge

struct MovementChallengeView: View {
    @State private var currentStep = 0
    @State private var timeRemaining = 5
    @State private var isComplete = false
    
    let onComplete: () -> Void
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    let movementSteps = [
        ("Stand up and stretch", "figure.stand"),
        ("Roll your shoulders 5 times", "figure.arms.open"),
        ("Shake out your hands", "hand.raised.fill"),
        ("Take 3 deep breaths", "wind"),
        ("Smile! You did it!", "face.smiling")
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Current movement icon
            Image(systemName: movementSteps[currentStep].1)
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
                .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                Text(movementSteps[currentStep].0)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text("Step \(currentStep + 1) of \(movementSteps.count)")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            
            // Timer
            if !isComplete {
                ZStack {
                    Circle()
                        .stroke(Color(white: 0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(5 - timeRemaining) / 5)
                        .stroke(
                            Color(red: 0.55, green: 0.5, blue: 0.7),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(timeRemaining)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            Button(action: onComplete) {
                Text(isComplete ? "Continue" : "Moving...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isComplete ? .black : .gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isComplete ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                    .cornerRadius(16)
            }
            .disabled(!isComplete)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onReceive(timer) { _ in
            if !isComplete && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 && currentStep < movementSteps.count - 1 {
                currentStep += 1
                timeRemaining = 5
            } else if timeRemaining == 0 && currentStep == movementSteps.count - 1 {
                isComplete = true
            }
        }
    }
}

// MARK: - Reading Challenge

struct ReadingChallengeView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("The Power of Presence")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    Text(readingText)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .lineSpacing(6)

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
            .frame(maxHeight: .infinity)
            .background(Color(white: 0.1))
            .cornerRadius(20)
            .padding(.horizontal, 20)

            Button(action: onComplete) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                    .cornerRadius(16)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }

    private var readingText: String {
        """
        In our hyperconnected world, we've lost something precious: the ability to be fully present. Every notification, every scroll, every swipe pulls us away from the moment we're in.
        
        Research from MIT's Human Dynamics Laboratory shows that constant digital interruptions fragment our attention, making it harder to focus, think deeply, and connect authentically with others.
        
        The cost of distraction:
        
        • It takes an average of 23 minutes to regain focus after an interruption
        • Multitasking reduces productivity by up to 40%
        • Constant connectivity increases stress hormones
        • Digital overload impairs memory formation
        
        But here's the good news: awareness is the first step to change. By taking this pause, you're practicing something revolutionary—conscious choice.
        
        Every time you complete one of these challenges, you're strengthening your ability to:
        
        - Resist impulsive behavior
        - Make intentional decisions
        - Stay present in your life
        - Control your attention
        
        The small act of pausing before mindless scrolling builds the mental muscle you need to reclaim your time and attention.
        
        You are not addicted to your phone—you're responding to carefully designed systems meant to capture your attention. Understanding this gives you power.
        
        This moment of reflection isn't a barrier—it's a gift. A chance to choose what matters.
        
        Use your time wisely. Real life is happening right now, beyond the screen.
        """
    }
}

// MARK: - Success Overlay

struct SuccessOverlay: View {
    let unlockTime: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
                
                Text("Challenge Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Unlocked for \(unlockTime)")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(white: 0.15))
            )
        }
    }
}

// MARK: - Helper Keys

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

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
