//
//  Config.swift
//  MindfulBreak
//
//  Configuration for API keys and settings
//

import Foundation

struct Config {
    /// OpenAI API Key
    /// Get your API key from: https://platform.openai.com/api-keys
    /// IMPORTANT: Never commit your actual API key to version control
    static var openAIAPIKey: String {
        // Option 1: Load from environment variable (recommended for development)
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }

        // Option 2: Load from a local config file (add Config.plist to .gitignore)
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let config = NSDictionary(contentsOfFile: path),
           let apiKey = config["OPENAI_API_KEY"] as? String {
            return apiKey
        }

        // Option 3: Hardcode for testing (REMOVE BEFORE PRODUCTION)
        // return "sk-proj-your-api-key-here"

        return ""
    }

    /// Check if OpenAI API is configured
    static var isOpenAIConfigured: Bool {
        return !openAIAPIKey.isEmpty
    }
}
