import Foundation
import SwiftData

@Model
final class Friend {
    var id: UUID
    var displayName: String
    var friendCode: String
    var addedAt: Date
    var totalCardsReviewed: Int
    var currentStreak: Int
    var lastActive: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        friendCode: String,
        addedAt: Date = Date(),
        totalCardsReviewed: Int = 0,
        currentStreak: Int = 0,
        lastActive: Date = Date()
    ) {
        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode
        self.addedAt = addedAt
        self.totalCardsReviewed = totalCardsReviewed
        self.currentStreak = currentStreak
        self.lastActive = lastActive
    }
}
