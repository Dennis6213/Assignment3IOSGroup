import Foundation
import SwiftData

final class SwiftDataDeckRepository: DeckRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAllDecks() throws -> [Deck] {
        let descriptor = FetchDescriptor<Deck>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func addDeck(_ deck: Deck) throws {
        modelContext.insert(deck)
        try save()
    }

    func deleteDeck(_ deck: Deck) throws {
        modelContext.delete(deck)
        try save()
    }

    func addCard(_ card: Card, to deck: Deck) throws {
        card.deck = deck
        deck.cards.append(card)
        modelContext.insert(card)
        try save()
    }

    func deleteCard(_ card: Card) throws {
        modelContext.delete(card)
        try save()
    }

    func fetchDueCards(for deck: Deck) -> [Card] {
        let now = Date()
        return deck.cards
            .filter { $0.dueDate <= now }
            .sorted { $0.dueDate < $1.dueDate }
    }

    func logReview(card: Card, grade: Grade) throws {
        let result = SM2Scheduler.schedule(card: card, grade: grade)
        SM2Scheduler.apply(result: result, to: card)

        let log = ReviewLog(grade: grade, card: card)
        card.reviews.append(log)
        modelContext.insert(log)
        try save()
    }

    func fetchReviewLogs(since date: Date) throws -> [ReviewLog] {
        let descriptor = FetchDescriptor<ReviewLog>(
            predicate: #Predicate { $0.date >= date },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func save() throws {
        try modelContext.save()
    }
}
