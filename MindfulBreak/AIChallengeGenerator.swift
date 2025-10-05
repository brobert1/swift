//
//  AIChallengeGenerator.swift
//  MindfulBreak
//
//  OpenAI-powered challenge generator
//

import Foundation

@MainActor
class AIChallengeGenerator: ObservableObject {
    static let shared = AIChallengeGenerator()

    private let apiKey: String
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Cost-effective model

    // Cache for generated challenges
    @Published var cachedChallenges: [AIChallenge] = []
    private let maxCachedChallenges = 10

    private init() {
        // Load API key from Config
        self.apiKey = Config.openAIAPIKey
        loadCachedChallenges()
    }

    // MARK: - Main Challenge Generation

    func generateChallenge(userInterests: [String], recentChallenges: [String] = []) async throws -> AIChallenge {
        // Check if we have cached challenges first (works even without API key)
        if let cachedChallenge = getCachedChallenge(avoiding: recentChallenges, matchingInterests: userInterests) {
            print("✅ Using cached AI challenge: \(cachedChallenge.title)")
            return cachedChallenge
        }

        // If no cache, we need API key to generate new ones
        guard !apiKey.isEmpty else {
            print("❌ No cached challenges and API key not configured")
            throw ChallengeGeneratorError.missingAPIKey
        }

        // Generate new challenge from OpenAI
        print("🌐 Calling OpenAI API to generate new challenge...")
        let prompt = buildPrompt(interests: userInterests, recentChallenges: recentChallenges)
        let challenge = try await callOpenAI(prompt: prompt, interests: userInterests)

        // Cache the challenge
        cacheChallenge(challenge)

        return challenge
    }

    // MARK: - Prompt Engineering

    private func buildPrompt(interests: [String], recentChallenges: [String]) -> String {
        let interestsString = interests.isEmpty ? "general mindfulness" : interests.joined(separator: ", ")
        let avoidString = recentChallenges.isEmpty ? "" : "\n\nAvoid these recent challenge types: \(recentChallenges.joined(separator: ", "))"

        return """
        You are a mindfulness challenge creator for a screen time management app. Generate ONE unique, actionable challenge that MUST match the user's interests.

        USER INTERESTS: \(interestsString)

        IMPORTANT: You MUST choose a challenge category that matches one of the user's interests above. If the user selected "Fitness", generate a fitness challenge. If they selected "Reading", generate a reading challenge, etc.

        CHALLENGE CATEGORIES & EXAMPLES:

        **Fitness**: Physical activities that take 20-60 seconds
        - "Do 10 pushups right now"
        - "Walk 100 steps away from your device"
        - "Hold a plank position for 30 seconds"
        - "Do 5 jumping jacks"
        - "Stretch your arms overhead for 20 seconds"

        **Reading**: Quick reading prompts
        - "Read one page of a physical book nearby"
        - "Find and read a poem (30 seconds)"
        - "Read an article headline and summary"

        **Music**: Musical engagement
        - "Hum or sing your favorite song for 30 seconds"
        - "Listen to one full song before continuing"
        - "Play a musical instrument for 1 minute"
        - "Identify 3 sounds in your environment"

        **Mindfulness**: Meditation and awareness
        - "Close your eyes and focus on your breath for 30 seconds"
        - "Name 5 things you can see, 4 you can touch, 3 you can hear"
        - "Practice box breathing (4-4-4-4) for 3 cycles"

        **Learning**: Educational micro-tasks
        - "Learn one new word in a foreign language"
        - "Watch a 60-second educational video"
        - "Read about a historical fact"

        **Art/Creativity**: Creative exercises
        - "Draw a quick sketch for 60 seconds"
        - "Write 3 lines of poetry"
        - "Take a creative photo of something nearby"

        **Nature**: Nature connection
        - "Look outside and identify 3 natural elements"
        - "Water a plant or observe nature for 30 seconds"
        - "Step outside for fresh air (30 seconds)"

        **Cooking**: Food-related activities
        - "Drink a full glass of water mindfully"
        - "Prepare a healthy snack"
        - "Smell 3 different herbs or spices"
        \(avoidString)

        REQUIREMENTS:
        1. CRITICAL: The activityType MUST match one of the user's interests listed above (e.g., if user selected "Fitness", activityType must be "fitness")
        2. Make it SPECIFIC and ACTIONABLE (e.g., "10 pushups", not "do some exercise")
        3. Duration: 20-60 seconds for quick tasks, up to 5 minutes for reading/music
        4. Provide 3-5 clear step-by-step instructions
        5. Title should be motivating and clear (5-8 words)
        6. Description should explain the benefit (2-3 sentences)
        7. The interestCategory in the JSON must exactly match one of: Fitness, Reading, Music, Mindfulness, Learning, Art, Nature, Cooking

        Return ONLY valid JSON in this exact format:
        {
          "title": "Do 10 Pushups Right Now",
          "description": "Physical movement helps reset your mind and reduces the urge to mindlessly scroll. A quick burst of exercise releases endorphins and improves focus.",
          "activityType": "fitness",
          "instructions": [
            "Find a clear space on the floor",
            "Get into pushup position",
            "Complete 10 pushups at your own pace",
            "Stand up and take a deep breath"
          ],
          "estimatedSeconds": 45,
          "interestCategory": "Fitness"
        }
        """
    }

    // MARK: - OpenAI API Call

    private func callOpenAI(prompt: String, interests: [String]) async throws -> AIChallenge {
        guard !apiKey.isEmpty else {
            throw ChallengeGeneratorError.missingAPIKey
        }

        let request = OpenAIRequest(
            model: model,
            messages: [
                OpenAIRequest.Message(role: "system", content: "You are a mindfulness challenge creator. Always respond with valid JSON only."),
                OpenAIRequest.Message(role: "user", content: prompt)
            ],
            temperature: 0.8, // Creative but focused
            maxTokens: 500,
            responseFormat: OpenAIRequest.ResponseFormat(type: "json_object")
        )

        var urlRequest = URLRequest(url: URL(string: apiURL)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChallengeGeneratorError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ OpenAI API Error (\(httpResponse.statusCode)): \(errorMessage)")
            throw ChallengeGeneratorError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let content = openAIResponse.choices.first?.message.content else {
            throw ChallengeGeneratorError.noContent
        }

        // Parse the JSON response
        let generatedData = try JSONDecoder().decode(GeneratedChallengeResponse.self, from: content.data(using: .utf8)!)

        // Convert to AIChallenge
        let activityType = AIChallenge.ActivityType(rawValue: generatedData.activityType.lowercased()) ?? .mindfulness

        return AIChallenge(
            title: generatedData.title,
            description: generatedData.description,
            activityType: activityType,
            instructions: generatedData.instructions,
            estimatedSeconds: generatedData.estimatedSeconds,
            interestCategory: generatedData.interestCategory
        )
    }

    // MARK: - Background Challenge Pre-generation

    func preGenerateChallenges(userInterests: [String], count: Int = 5) async {
        print("🔄 Pre-generating \(count) AI challenges in background...")

        for i in 0..<count {
            do {
                let challenge = try await generateChallenge(userInterests: userInterests)
                print("✅ Pre-generated challenge \(i + 1)/\(count): \(challenge.title)")
            } catch {
                print("❌ Failed to pre-generate challenge \(i + 1): \(error)")
            }
        }
    }

    // MARK: - Caching

    private func cacheChallenge(_ challenge: AIChallenge) {
        cachedChallenges.append(challenge)

        // Keep only the most recent challenges
        if cachedChallenges.count > maxCachedChallenges {
            cachedChallenges.removeFirst()
        }

        saveCachedChallenges()
    }

    private func getCachedChallenge(avoiding recentTitles: [String], matchingInterests userInterests: [String]) -> AIChallenge? {
        // Filter out recently shown challenges AND ensure they match user interests
        let available = cachedChallenges.filter { challenge in
            // Must not be recently shown
            guard !recentTitles.contains(challenge.title) else { return false }

            // Must match at least one of the user's interests
            let challengeCategory = challenge.interestCategory.lowercased()
            let matchesInterests = userInterests.contains { interest in
                interest.lowercased() == challengeCategory
            }

            return matchesInterests
        }

        if let challenge = available.randomElement() {
            print("   ✅ Found cached challenge matching interests: \(challenge.interestCategory)")
            // Remove from cache so it's not shown again immediately
            cachedChallenges.removeAll { $0.id == challenge.id }
            saveCachedChallenges()
            return challenge
        }

        print("   ⚠️ No cached challenges match user interests: \(userInterests.joined(separator: ", "))")
        return nil
    }

    private func saveCachedChallenges() {
        if let encoded = try? JSONEncoder().encode(cachedChallenges) {
            UserDefaults.standard.set(encoded, forKey: "cachedAIChallenges")
        }
    }

    private func loadCachedChallenges() {
        if let data = UserDefaults.standard.data(forKey: "cachedAIChallenges"),
           let decoded = try? JSONDecoder().decode([AIChallenge].self, from: data) {
            cachedChallenges = decoded
            print("✅ Loaded \(cachedChallenges.count) cached AI challenges")
        }
    }

    // MARK: - Public Cache Management

    func clearCache() {
        cachedChallenges.removeAll()
        UserDefaults.standard.removeObject(forKey: "cachedAIChallenges")
        print("🗑️ Cleared all cached AI challenges from memory and storage")
    }
}

// MARK: - Errors

enum ChallengeGeneratorError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String)
    case noContent
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing. Please configure your API key."
        case .invalidResponse:
            return "Invalid response from OpenAI API"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .noContent:
            return "No content received from OpenAI"
        case .invalidJSON:
            return "Failed to parse challenge JSON"
        }
    }
}
