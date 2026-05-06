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
