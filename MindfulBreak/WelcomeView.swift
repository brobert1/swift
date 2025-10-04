//
//  WelcomeView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void
    
    @State private var scrollOffset: CGFloat = 0
    
    let interests = [
        Interest(name: "Fitness", icon: "figure.run", color: .orange),
        Interest(name: "Reading", icon: "book.fill", color: .blue),
        Interest(name: "Music", icon: "music.note", color: .purple),
        Interest(name: "Mindfulness", icon: "leaf.fill", color: .green),
        Interest(name: "Learning", icon: "graduationcap.fill", color: .red),
        Interest(name: "Art", icon: "paintbrush.fill", color: .pink),
        Interest(name: "Cooking", icon: "fork.knife", color: .yellow),
        Interest(name: "Nature", icon: "tree.fill", color: .mint),
    ]

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 16) {
                    // App Icon/Logo
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)

                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)

                    Text("Neura")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Turn mindless scrolling into mindful action")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)

                // Infinitely Scrolling Interest Cards
                InfiniteScrollingInterests(interests: interests)
                    .frame(maxHeight: .infinity)
                
                // Get Started Button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.55, green: 0.5, blue: 0.7))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .padding(.top, 20)
            }
        }
    }
}

struct InfiniteScrollingInterests: View {
    let interests: [Interest]
    @State private var offset: CGFloat = 0
    
    // Split interests into two rows for horizontal scrolling
    var topRowInterests: [Interest] {
        stride(from: 0, to: interests.count, by: 2).map { interests[$0] }
    }
    
    var bottomRowInterests: [Interest] {
        stride(from: 1, to: interests.count, by: 2).map { interests[$0] }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row - scrolling left to right
            HorizontalScrollingRow(interests: topRowInterests, direction: 1)
            
            // Bottom row - scrolling left to right
            HorizontalScrollingRow(interests: bottomRowInterests, direction: 1)
        }
        .padding(.horizontal, 20)
    }
}

struct HorizontalScrollingRow: View {
    let interests: [Interest]
    let direction: CGFloat // 1 for left-to-right, -1 for right-to-left
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Triple the content for seamless infinite scroll
                    ForEach(0..<3) { _ in
                        ForEach(interests) { interest in
                            AnimatedInterestCard(interest: interest)
                                .frame(width: geometry.size.width * 0.4)
                        }
                    }
                }
                .offset(x: offset)
            }
            .disabled(true) // Disable user interaction
            .onAppear {
                startInfiniteScroll(containerWidth: geometry.size.width)
            }
        }
        .frame(height: 140)
    }
    
    private func startInfiniteScroll(containerWidth: CGFloat) {
        let cardWidth = containerWidth * 0.4
        let spacing: CGFloat = 12
        let singleSetWidth = CGFloat(interests.count) * (cardWidth + spacing)
        
        // Start from 0 and move left (negative x) for left-to-right scroll effect
        withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
            offset = -singleSetWidth * direction
        }
    }
}

struct AnimatedInterestCard: View {
    let interest: Interest
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(interest.color.opacity(0.9))
                    .frame(width: 60, height: 60)

                Image(systemName: interest.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)

            Text(interest.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(Double.random(in: 0...1))
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    WelcomeView(onContinue: {})
}
