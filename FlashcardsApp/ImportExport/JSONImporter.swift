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


enum JSONImporter {

    static func parse(_ jsonString: String) throws -> FlashcardImportData {
        guard let data = jsonString.data(using: .utf8) else {
            throw ImportError.invalidJSON("Could not read text as UTF-8.")
        }

        let decoder = JSONDecoder()
        let importData: FlashcardImportData

        do {
            importData = try decoder.decode(FlashcardImportData.self, from: data)
        } catch let decodingError {
            throw ImportError.invalidJSON(decodingError.localizedDescription)
        }

        guard !importData.deckName.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ImportError.emptyDeckName
        }

        guard !importData.cards.isEmpty else {
            throw ImportError.noCards
        }

        for (index, card) in importData.cards.enumerated() {
            if card.front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ImportError.invalidCard(index: index, reason: "Front text is empty.")
            }
            if card.back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ImportError.invalidCard(index: index, reason: "Back text is empty.")
            }
        }

        return importData
    }

    static func createDeck(from importData: FlashcardImportData) -> Deck {
        let deck = Deck(
            name: importData.deckName.trimmingCharacters(in: .whitespaces),
            deckDescription: importData.description?.trimmingCharacters(in: .whitespaces) ?? ""
        )

        for cardData in importData.cards {
            let card = Card(
                front: cardData.front.trimmingCharacters(in: .whitespacesAndNewlines),
                back: cardData.back.trimmingCharacters(in: .whitespacesAndNewlines),
                hint: cardData.hint?.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            card.deck = deck
            deck.cards.append(card)
        }

        return deck
    }
}


enum JSONExporter {

    static func export(deck: Deck) throws -> String {
        let exportData = FlashcardExportData(
            deckName: deck.name,
            description: deck.deckDescription,
            cards: deck.cards.map { card in
                FlashcardExportCard(
                    front: card.front,
                    back: card.back,
                    hint: card.hint
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)

        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidJSON("Could not encode to UTF-8.")
        }

        return jsonString
    }
}
