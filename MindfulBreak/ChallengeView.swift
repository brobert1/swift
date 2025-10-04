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

    let onComplete: () -> Void

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

                    Text("Read the entire text below to unlock 1 minute of access")
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
                SuccessOverlay()
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
        print("✅ Challenge completed! Unlocking for 1 minute...")

        // Show success animation
        showSuccess = true

        // Unshield apps temporarily
        screenTimeManager.unshieldApps()

        // Schedule re-shield after 1 minute (for testing)
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            print("⏱️ 1 minute expired - re-shielding apps")
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

                Text("Unlocked for 1 minute")
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

#Preview {
    ChallengeView(onComplete: {})
}
