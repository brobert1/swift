//
//  DynamicChallengeView.swift
//  MindfulBreak
//
//  View for rendering AI-generated challenges
//

import SwiftUI

struct DynamicChallengeView: View {
    let challenge: AIChallenge
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var timeRemaining: Int
    @State private var isComplete = false
    @State private var hasStarted = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(challenge: AIChallenge, onComplete: @escaping () -> Void) {
        self.challenge = challenge
        self.onComplete = onComplete
        _timeRemaining = State(initialValue: challenge.estimatedSeconds)
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Activity Icon
            activityIcon
                .font(.system(size: 80))
                .foregroundColor(Color(red: 0.55, green: 0.5, blue: 0.7))
                .padding(.bottom, 20)

            // Instructions
            VStack(spacing: 16) {
                if challenge.instructions.count > 1 {
                    // Multi-step challenge
                    Text(challenge.instructions[min(currentStep, challenge.instructions.count - 1)])
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .animation(.easeInOut, value: currentStep)

                    if currentStep < challenge.instructions.count {
                        Text("Step \(currentStep + 1) of \(challenge.instructions.count)")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                } else {
                    // Single instruction
                    Text(challenge.instructions.first ?? "Complete this challenge")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }

            // Timer (only show if not complete and has started)
            if !isComplete && hasStarted {
                timerView
            }

            // Start button or progress indicator
            if !hasStarted {
                VStack(spacing: 12) {
                    Text(challenge.description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button(action: startChallenge) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Challenge")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            // Complete button (bottom)
            if hasStarted {
                Button(action: onComplete) {
                    Text(isComplete ? "Continue" : "Completing...")
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
        }
        .onReceive(timer) { _ in
            handleTimerTick()
        }
    }

    // MARK: - Subviews

    private var activityIcon: some View {
        Image(systemName: iconName)
    }

    private var iconName: String {
        switch challenge.activityType {
        case .fitness:
            return "figure.run"
        case .breathing:
            return "wind"
        case .reading:
            return "book.fill"
        case .movement:
            return "figure.walk"
        case .music:
            return "music.note"
        case .mindfulness:
            return "leaf.fill"
        case .learning:
            return "graduationcap.fill"
        case .creativity:
            return "paintbrush.fill"
        }
    }

    private var timerView: some View {
        ZStack {
            Circle()
                .stroke(Color(white: 0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color(red: 0.55, green: 0.5, blue: 0.7),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            VStack(spacing: 4) {
                Text("\(timeRemaining)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("sec")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }

    private var progress: CGFloat {
        let total = Double(challenge.estimatedSeconds)
        let remaining = Double(timeRemaining)
        return CGFloat((total - remaining) / total)
    }

    // MARK: - Actions

    private func startChallenge() {
        hasStarted = true
    }

    private func handleTimerTick() {
        guard hasStarted && !isComplete else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
        }

        // Handle multi-step challenges
        if challenge.instructions.count > 1 {
            let stepDuration = challenge.estimatedSeconds / challenge.instructions.count
            let completedSteps = (challenge.estimatedSeconds - timeRemaining) / stepDuration

            if completedSteps > currentStep && currentStep < challenge.instructions.count - 1 {
                currentStep = completedSteps
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }

        // Mark complete when time is up
        if timeRemaining == 0 && !isComplete {
            isComplete = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Preview

#Preview {
    DynamicChallengeView(
        challenge: AIChallenge(
            title: "Do 10 Pushups",
            description: "Physical activity helps reset your mind and break the scrolling habit.",
            activityType: .fitness,
            instructions: [
                "Find a clear space",
                "Get into position",
                "Complete 10 pushups",
                "Stand and breathe"
            ],
            estimatedSeconds: 45,
            interestCategory: "Fitness"
        ),
        onComplete: {}
    )
    .background(Color.black)
}
