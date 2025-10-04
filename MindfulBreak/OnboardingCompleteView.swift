//
//  OnboardingCompleteView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

struct OnboardingCompleteView: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.6), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Success Animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 140, height: 140)

                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 120, height: 120)

                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)

                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.green)
                    }
                }

                VStack(spacing: 16) {
                    Text("You're All Set!")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)

                    Text("Mindful Break is now active and ready to help you build healthier digital habits")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 20) {
                    infoRow(icon: "shield.fill", text: "Your selected apps are now being monitored")
                    infoRow(icon: "sparkles", text: "Personalized challenges are ready")
                    infoRow(icon: "bell.fill", text: "You'll get notified when limits are reached")
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: onFinish) {
                    Text("Finish")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 32)

            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

#Preview {
    OnboardingCompleteView(onFinish: {})
}
