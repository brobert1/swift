import Foundation

struct Config {
    static var openAIAPIKey: String {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            print("Found env key: \(envKey.prefix(10))...")
            return envKey
        }
        print("No env key found")
        return ""
    }
    
    static var isOpenAIConfigured: Bool {
        let key = openAIAPIKey
        print("API Key configured: \(!key.isEmpty), length: \(key.count)")
        return !key.isEmpty
    }
}

print("Testing config...")
print("Is configured: \(Config.isOpenAIConfigured)")
