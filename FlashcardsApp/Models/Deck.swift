import Foundation
import SwiftData

@Model
final class Deck {
    var id: UUID
    var name: String
    var deckDescription: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card]

    init(id: UUID = UUID(), name: String, deckDescription: String = "", createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.deckDescription = deckDescription
        self.createdAt = createdAt
        self.cards = []
    }

    var dueCards: [Card] {
        cards.filter { $0.dueDate <= Date() }
    }

    var dueCount: Int {
        dueCards.count
    }

    var totalCount: Int {
        cards.count
    }
}
