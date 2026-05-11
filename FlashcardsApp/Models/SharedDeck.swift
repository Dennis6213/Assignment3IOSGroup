import Foundation
import SwiftData

@Model
final class SharedDeck {
    var id: UUID
    var deckName: String
    var cardCount: Int
    var sharedBy: String
    var sharedAt: Date
    var jsonData: String

    init(
        id: UUID = UUID(),
        deckName: String,
        cardCount: Int,
        sharedBy: String,
        sharedAt: Date = Date(),
        jsonData: String
    ) {
        self.id = id
        self.deckName = deckName
        self.cardCount = cardCount
        self.sharedBy = sharedBy
        self.sharedAt = sharedAt
        self.jsonData = jsonData
    }
}
