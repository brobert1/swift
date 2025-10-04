//
//  Models.swift
//  MindfulBreak
//
//  Created on 2025-10-04
//

import Foundation
import FamilyControls
import ManagedSettings

struct UserPreferences: Codable {
    var interests: [String] = []
}

struct MonitoredApp: Identifiable, Hashable {
    let id: String // Unique identifier based on token
    let token: ApplicationToken
    var timeLimitInMinutes: Int = 60
    var isEnabled: Bool = true

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MonitoredApp, rhs: MonitoredApp) -> Bool {
        lhs.id == rhs.id
    }
}

enum TaskType: String, Codable {
    case fitness
    case journaling
    case reading
    case mindfulness
    case learning
}

struct ChallengeTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let type: TaskType
    let estimatedMinutes: Int
}
