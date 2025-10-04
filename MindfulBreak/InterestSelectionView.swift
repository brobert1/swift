//
//  InterestSelectionView.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import SwiftUI

struct InterestSelectionView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var selectedInterests: Set<String> = []

    var onContinue: () -> Void

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
                // Header
                VStack(spacing: 8) {
                    Text("Personalize Your Challenges")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Text("What are you into? We'll tailor your tasks to your interests")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)

                // Interest Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(interests) { interest in
                            InterestCard(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest.name)
                            ) {
                                toggleInterest(interest.name)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }

                Spacer()

                // Continue button
                VStack(spacing: 8) {
                    if !selectedInterests.isEmpty {
                        Text("\(selectedInterests.count) interest\(selectedInterests.count == 1 ? "" : "s") selected")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        // Save interests to DataStore
                        dataStore.saveInterests(Array(selectedInterests))
                        onContinue()
                    }) {
                        Text("Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedInterests.isEmpty ? Color.gray.opacity(0.3) : Color(red: 0.55, green: 0.5, blue: 0.7))
                            .cornerRadius(12)
                    }
                    .disabled(selectedInterests.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            // Load existing interests when editing
            if !dataStore.userInterests.isEmpty {
                selectedInterests = Set(dataStore.userInterests)
            }
        }
    }

    private func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            selectedInterests.remove(interest)
        } else {
            selectedInterests.insert(interest)
        }
    }
}

struct InterestCard: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? interest.color : Color(uiColor: .tertiarySystemFill))
                        .frame(width: 70, height: 70)

                    Image(systemName: interest.icon)
                        .font(.system(size: 32))
                        .foregroundColor(isSelected ? .white : .secondary)
                }

                Text(interest.name)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? interest.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InterestSelectionView(onContinue: {})
}
