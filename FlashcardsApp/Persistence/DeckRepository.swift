import Foundation

protocol DeckRepository {
    func fetchAllDecks() throws -> [Deck]
    func addDeck(_ deck: Deck) throws
    func deleteDeck(_ deck: Deck) throws

    func addCard(_ card: Card, to deck: Deck) throws
    func deleteCard(_ card: Card) throws
    func fetchDueCards(for deck: Deck) -> [Card]

    func logReview(card: Card, grade: Grade) throws
    func fetchReviewLogs(since date: Date) throws -> [ReviewLog]

    func save() throws
}
