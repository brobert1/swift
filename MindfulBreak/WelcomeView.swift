//
//  WelcomeView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App Icon/Logo
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                VStack(spacing: 16) {
                    Text("Mindful Break")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Turn mindless scrolling into mindful action")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                VStack(spacing: 16) {
                    featureRow(icon: "hourglass", text: "Set limits on distracting apps")
                    featureRow(icon: "figure.walk", text: "Complete personalized challenges")
                    featureRow(icon: "sparkles", text: "Build healthier digital habits")
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
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

    private func featureRow(icon: String, text: String) -> some View {
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
    WelcomeView(onContinue: {})
}
