import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var friendCode: String
    var createdAt: Date
    var totalCardsReviewed: Int
    var currentStreak: Int

    init(
        id: UUID = UUID(),
        displayName: String,
        friendCode: String? = nil,
        createdAt: Date = Date(),
        totalCardsReviewed: Int = 0,
        currentStreak: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.friendCode = friendCode ?? String(UUID().uuidString.prefix(8)).uppercased()
        self.createdAt = createdAt
        self.totalCardsReviewed = totalCardsReviewed
        self.currentStreak = currentStreak
    }
}
