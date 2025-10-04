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
