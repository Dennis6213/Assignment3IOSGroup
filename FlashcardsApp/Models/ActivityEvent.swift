import Foundation
import SwiftData

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
        eventType: String,
        detail: String,
        timestamp: Date = Date(),
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.userName = userName
        self.eventType = eventType
        self.detail = detail
        self.timestamp = timestamp
        self.isCurrentUser = isCurrentUser
    }

    var icon: String {
        switch eventType {
        case "completed_session": return "checkmark.circle.fill"
        case "new_deck": return "plus.rectangle.on.folder.fill"
        case "streak_milestone": return "flame.fill"
        case "mastered_card": return "star.fill"
        default: return "bell.fill"
        }
    }

    var iconColor: String {
        switch eventType {
        case "completed_session": return "green"
        case "new_deck": return "blue"
        case "streak_milestone": return "orange"
        case "mastered_card": return "yellow"
        default: return "gray"
        }
    }
}
