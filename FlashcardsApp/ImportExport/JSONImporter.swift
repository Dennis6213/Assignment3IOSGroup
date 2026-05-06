import Foundation


struct FlashcardImportData: Codable {
    let deckName: String
    let description: String?
    let cards: [FlashcardImportCard]

    enum CodingKeys: String, CodingKey {
        case deckName = "deck_name"
        case description
        case cards
    }
}

struct FlashcardImportCard: Codable {
    let front: String
    let back: String
    let hint: String?
}


struct FlashcardExportData: Codable {
    let deckName: String
    let description: String
    let cards: [FlashcardExportCard]

    enum CodingKeys: String, CodingKey {
        case deckName = "deck_name"
        case description
        case cards
    }
}

struct FlashcardExportCard: Codable {
    let front: String
    let back: String
    let hint: String?
}


enum ImportError: LocalizedError {
    case invalidJSON(String)
    case emptyDeckName
    case noCards
    case invalidCard(index: Int, reason: String)
    case duplicateDeckName(String)

    var errorDescription: String? {
        switch self {
        case .invalidJSON(let detail):
            return "Invalid JSON: \(detail)"
        case .emptyDeckName:
            return "Deck name cannot be empty."
        case .noCards:
            return "The import file contains no cards."
        case .invalidCard(let index, let reason):
            return "Card \(index + 1) is invalid: \(reason)"
        case .duplicateDeckName(let name):
            return "A deck named \"\(name)\" already exists."
        }
    }
}
