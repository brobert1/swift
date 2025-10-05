//
//  AIChallengeModels.swift
//  MindfulBreak
//
//  AI-generated challenge models
//

import Foundation

// MARK: - AI Challenge Models

struct AIChallenge: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let activityType: ActivityType
    let instructions: [String]
    let estimatedSeconds: Int
    let interestCategory: String

    enum ActivityType: String, Codable {
        case fitness = "fitness"
        case breathing = "breathing"
        case reading = "reading"
        case movement = "movement"
        case music = "music"
        case mindfulness = "mindfulness"
        case learning = "learning"
        case creativity = "creativity"
    }

    init(id: UUID = UUID(), title: String, description: String, activityType: ActivityType, instructions: [String], estimatedSeconds: Int, interestCategory: String) {
        self.id = id
        self.title = title
        self.description = description
        self.activityType = activityType
        self.instructions = instructions
        self.estimatedSeconds = estimatedSeconds
        self.interestCategory = interestCategory
    }
}

// MARK: - OpenAI Response Models

struct OpenAIRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let maxTokens: Int?
    let responseFormat: ResponseFormat?

    struct Message: Codable {
        let role: String
        let content: String
    }

    struct ResponseFormat: Codable {
        let type: String
    }

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
}

struct OpenAIResponse: Codable {
    let id: String
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let role: String
            let content: String
        }
    }
}

struct GeneratedChallengeResponse: Codable {
    let title: String
    let description: String
    let activityType: String
    let instructions: [String]
    let estimatedSeconds: Int
    let interestCategory: String
}
