import Foundation
import SwiftData

enum ActivityEventType: String, Codable, CaseIterable {
    case completedSession  = "completed_session"
    case newDeck           = "new_deck"
    case streakMilestone   = "streak_milestone"
    case masteredCard      = "mastered_card"

    var icon: String {
        switch self {
        case .completedSession: return "checkmark.circle.fill"
        case .newDeck:          return "plus.rectangle.on.folder.fill"
        case .streakMilestone:  return "flame.fill"
        case .masteredCard:     return "star.fill"
        }
    }
}

@Model
final class ActivityEvent {
    var id: UUID
    var userName: String
    var eventType: String
    var detail: String
    var timestamp: Date
    var isCurrentUser: Bool

    init(
        id: UUID = UUID(),
        userName: String,
        type: ActivityEventType,
        detail: String,
        timestamp: Date = Date(),
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.userName = userName
        self.eventType = type.rawValue
        self.detail = detail
        self.timestamp = timestamp
        self.isCurrentUser = isCurrentUser
    }

    var type: ActivityEventType {
        ActivityEventType(rawValue: eventType) ?? .completedSession
    }
}
