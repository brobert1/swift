//
//  ChallengeView.swift
//  MindfulBreak
//
//  Challenge screen shown when user wants to unlock a shielded app
//

import SwiftUI
import UserNotifications

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
    @StateObject private var aiGenerator = AIChallengeGenerator.shared
    @State private var showSuccess = false
    @State private var selectedChallenge: ChallengeType?
    @State private var aiChallenge: AIChallenge?
    @State private var isLoadingAIChallenge = true
    @State private var useAIChallenge = true // Toggle for AI vs hardcoded

    let app: MonitoredApp
    let onComplete: () -> Void

    init(app: MonitoredApp, onComplete: @escaping () -> Void) {
        self.app = app
        self.onComplete = onComplete
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

            if isLoadingAIChallenge {
                // Loading state
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color(red: 0.55, green: 0.5, blue: 0.7))

                    Text("Generating your personalized challenge...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                .onAppear {
                    print("🔄 VIEW: Showing loading state")
                }
            } else if let aiChallenge = aiChallenge, useAIChallenge {
                // AI-generated challenge
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text(aiChallenge.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 24)

                    // AI Challenge content
                    DynamicChallengeView(challenge: aiChallenge, onComplete: completeChallenge)
                }
                .onAppear {
                    print("✨ VIEW: Showing AI challenge: \(aiChallenge.title)")
                }
            } else if let selectedChallenge = selectedChallenge {
                // Fallback to hardcoded challenges
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
                .onAppear {
                    print("⚠️ VIEW: Showing hardcoded challenge: \(selectedChallenge.title)")
                }
            } else {
                Text("No challenge available")
                    .foregroundColor(.white)
                    .onAppear {
                        print("❌ VIEW: No challenge to show!")
                        print("   aiChallenge: \(aiChallenge?.title ?? "nil")")
                        print("   useAIChallenge: \(useAIChallenge)")
                        print("   selectedChallenge: \(selectedChallenge?.title ?? "nil")")
                        print("   isLoadingAIChallenge: \(isLoadingAIChallenge)")
                    }
            }

            if showSuccess {
                SuccessOverlay(unlockTime: unlockTimeDisplay)
            }
        }
        .task {
            print("⏰ .task modifier called - loading challenge")
            await loadChallenge()
        }
        .onAppear {
            print("👁️ ChallengeView appeared")
            print("   Initial state - aiChallenge: \(aiChallenge?.title ?? "nil")")
            print("   Initial state - useAIChallenge: \(useAIChallenge)")
            print("   Initial state - isLoadingAIChallenge: \(isLoadingAIChallenge)")
        }
    }

    private func loadChallenge() async {
        print("🚀 loadChallenge() started")
        // Get recent challenge titles to avoid repetition
        let recentTitles = getRecentChallengeTitles()

        do {
            // Try to generate AI challenge (will use cache if available, even without API key)
            print("🤖 Attempting to load AI challenge...")
            print("   User interests: \(dataStore.userInterests)")
            print("   API configured: \(Config.isOpenAIConfigured)")

            let challenge = try await aiGenerator.generateChallenge(
                userInterests: dataStore.userInterests,
                recentChallenges: recentTitles
            )

            print("📦 Received AI challenge: \(challenge.title)")
            print("   Type: \(challenge.activityType)")
            print("   Instructions: \(challenge.instructions.count)")

            await MainActor.run {
                print("🎯 Setting aiChallenge and useAIChallenge = true")
                self.aiChallenge = challenge
                self.useAIChallenge = true
                self.isLoadingAIChallenge = false

                // Save challenge title to recent history
                saveRecentChallengeTitle(challenge.title)

                print("   aiChallenge is now: \(self.aiChallenge?.title ?? "nil")")
                print("   useAIChallenge is now: \(self.useAIChallenge)")
                print("   isLoadingAIChallenge is now: \(self.isLoadingAIChallenge)")
            }

            print("✅ AI Challenge loaded: \(challenge.title)")
        } catch {
            print("❌ Failed to generate AI challenge: \(error.localizedDescription)")
            print("   Error details: \(error)")

            // Fallback to hardcoded challenge
            await MainActor.run {
                self.selectedChallenge = selectFallbackChallenge()
                self.useAIChallenge = false
                self.isLoadingAIChallenge = false
            }
        }
    }

    private func selectFallbackChallenge() -> ChallengeType {
        // Select random challenge, avoiding the last one shown
        if let lastChallengeRaw = UserDefaults.standard.object(forKey: "lastChallengeIndex") as? Int,
           let lastChallenge = ChallengeType(rawValue: lastChallengeRaw) {
            let availableChallenges = ChallengeType.allCases.filter { $0 != lastChallenge }
            let randomChallenge = availableChallenges.randomElement() ?? .breathing
            UserDefaults.standard.set(randomChallenge.rawValue, forKey: "lastChallengeIndex")
            return randomChallenge
        } else {
            let randomChallenge = ChallengeType.allCases.randomElement() ?? .breathing
            UserDefaults.standard.set(randomChallenge.rawValue, forKey: "lastChallengeIndex")
            return randomChallenge
        }
    }

    private func getRecentChallengeTitles() -> [String] {
        if let titles = UserDefaults.standard.array(forKey: "recentChallengeTitles") as? [String] {
            return Array(titles.prefix(3)) // Last 3 challenges
        }
        return []
    }

    private func saveRecentChallengeTitle(_ title: String) {
        var titles = getRecentChallengeTitles()
        titles.insert(title, at: 0)
        titles = Array(titles.prefix(5)) // Keep last 5
        UserDefaults.standard.set(titles, forKey: "recentChallengeTitles")
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

            self.screenTimeManager.shieldApps([self.app])
            
            // Send notification that time is up again
            self.sendTimesUpNotification()
        }

        // Dismiss after showing success
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            onComplete()
            dismiss()
        }
    }

    private func sendTimesUpNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "⏰ Time's Up!"
        content.body = "You've reached your daily limit. Tap to complete a challenge and unlock more time."
        content.sound = .default
        content.userInfo = ["appId": app.id, "type": "limit"]

        // Use unique identifier with timestamp
        let uniqueIdentifier = "limit_reached_\(app.id)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: uniqueIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to send time's up notification: \(error)")
            } else {
                print("📬 Time's up notification sent!")
            }
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
    @State private var hasScrolledToBottom = false
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    let onComplete: () -> Void
    
    var isScrolledToBottom: Bool {
        let bottomThreshold: CGFloat = 50
        return (contentHeight - scrollViewHeight) <= bottomThreshold || contentHeight <= scrollViewHeight
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
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
                        
                        HStack {
                            Spacer()
                            Image(systemName: hasScrolledToBottom ? "checkmark.circle.fill" : "arrow.down.circle")
                                .font(.system(size: 40))
                                .foregroundColor(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : .gray)
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
                .background(Color(white: 0.1))
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
                .onChange(of: isScrolledToBottom) { scrolledToBottom in
                    if scrolledToBottom && !hasScrolledToBottom {
                        hasScrolledToBottom = true
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
            
            Button(action: onComplete) {
                HStack {
                    if hasScrolledToBottom {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue")
                    } else {
                        Image(systemName: "arrow.down.circle")
                        Text("Scroll to Continue")
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(hasScrolledToBottom ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                .cornerRadius(16)
            }
            .disabled(!hasScrolledToBottom)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private func checkIfScrolledToBottom() {
        if contentHeight <= scrollViewHeight {
            hasScrolledToBottom = true
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
    @State private var hasScrolledToBottom = false
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    let onComplete: () -> Void
    
    var isScrolledToBottom: Bool {
        let bottomThreshold: CGFloat = 50
        return (contentHeight - scrollViewHeight) <= bottomThreshold || contentHeight <= scrollViewHeight
    }
    
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
                    
                    HStack {
                        Spacer()
                        Image(systemName: hasScrolledToBottom ? "checkmark.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : .gray)
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
            .background(Color(white: 0.1))
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
            .onChange(of: isScrolledToBottom) { scrolledToBottom in
                if scrolledToBottom && !hasScrolledToBottom {
                    hasScrolledToBottom = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            
            Button(action: onComplete) {
                HStack {
                    if hasScrolledToBottom {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue")
                    } else {
                        Image(systemName: "arrow.down.circle")
                        Text("Scroll to Continue")
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(hasScrolledToBottom ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                .cornerRadius(16)
            }
            .disabled(!hasScrolledToBottom)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private func checkIfScrolledToBottom() {
        if contentHeight <= scrollViewHeight {
            hasScrolledToBottom = true
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
    @State private var hasScrolledToBottom = false
    @State private var contentHeight: CGFloat = 0
    @State private var scrollViewHeight: CGFloat = 0
    
    let onComplete: () -> Void
    
    var isScrolledToBottom: Bool {
        let bottomThreshold: CGFloat = 50
        return (contentHeight - scrollViewHeight) <= bottomThreshold || contentHeight <= scrollViewHeight
    }
    
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
                    
                    HStack {
                        Spacer()
                        Image(systemName: hasScrolledToBottom ? "checkmark.circle.fill" : "arrow.down.circle")
                            .font(.system(size: 40))
                            .foregroundColor(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : .gray)
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
            .background(Color(white: 0.1))
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
            .onChange(of: isScrolledToBottom) { scrolledToBottom in
                if scrolledToBottom && !hasScrolledToBottom {
                    hasScrolledToBottom = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
            
            Button(action: onComplete) {
                HStack {
                    if hasScrolledToBottom {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Continue")
                    } else {
                        Image(systemName: "arrow.down.circle")
                        Text("Scroll to Continue")
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(hasScrolledToBottom ? .black : .gray)
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasScrolledToBottom ? Color(red: 0.55, green: 0.5, blue: 0.7) : Color.gray.opacity(0.3))
                .cornerRadius(16)
            }
            .disabled(!hasScrolledToBottom)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
    }
    
    private func checkIfScrolledToBottom() {
        if contentHeight <= scrollViewHeight {
            hasScrolledToBottom = true
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
