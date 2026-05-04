import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var front: String
    var back: String
    var hint: String?

    var interval: Int
    var easeFactor: Double
    var repetitions: Int
    var dueDate: Date

    var deck: Deck?
    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviews: [ReviewLog]

    init(
        id: UUID = UUID(),
        front: String,
        back: String,
        hint: String? = nil,
        interval: Int = 0,
        easeFactor: Double = 2.5,
        repetitions: Int = 0,
        dueDate: Date = Date()
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.hint = hint
        self.interval = interval
        self.easeFactor = easeFactor
        self.repetitions = repetitions
        self.dueDate = dueDate
        self.reviews = []
    }

    var isNew: Bool {
        repetitions == 0 && interval == 0
    }

    var isDue: Bool {
        dueDate <= Date()
    }
}
