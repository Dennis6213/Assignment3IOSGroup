import XCTest
@testable import FlashcardsApp

final class JSONImporterTests: XCTestCase {

    func testParseValidJSON() throws {
        let json = """
        {
          "deck_name": "Test Deck",
          "description": "A test deck",
          "cards": [
            { "front": "Q1", "back": "A1", "hint": "H1" },
            { "front": "Q2", "back": "A2" }
          ]
        }
        """

        let data = try JSONImporter.parse(json)
        XCTAssertEqual(data.deckName, "Test Deck")
        XCTAssertEqual(data.description, "A test deck")
        XCTAssertEqual(data.cards.count, 2)
        XCTAssertEqual(data.cards[0].front, "Q1")
        XCTAssertEqual(data.cards[0].hint, "H1")
        XCTAssertNil(data.cards[1].hint)
    }

    func testCreateDeckFromImportData() throws {
        let json = """
        {
          "deck_name": "Biology",
          "cards": [
            { "front": "What is DNA?", "back": "Genetic material" }
          ]
        }
        """

        let importData = try JSONImporter.parse(json)
        let deck = JSONImporter.createDeck(from: importData)

        XCTAssertEqual(deck.name, "Biology")
        XCTAssertEqual(deck.cards.count, 1)
        XCTAssertEqual(deck.cards[0].front, "What is DNA?")
        XCTAssertEqual(deck.cards[0].back, "Genetic material")
    }

    func testParseInvalidJSONThrowsError() {
        let json = "not json at all"

        XCTAssertThrowsError(try JSONImporter.parse(json)) { error in
            XCTAssertTrue(error is ImportError)
        }
    }

    func testParseEmptyDeckNameThrows() {
        let json = """
        { "deck_name": "  ", "cards": [{ "front": "Q", "back": "A" }] }
        """

        XCTAssertThrowsError(try JSONImporter.parse(json)) { error in
            guard case ImportError.emptyDeckName = error else {
                XCTFail("Expected emptyDeckName error"); return
            }
        }
    }

    func testParseNoCardsThrows() {
        let json = """
        { "deck_name": "Empty", "cards": [] }
        """

        XCTAssertThrowsError(try JSONImporter.parse(json)) { error in
            guard case ImportError.noCards = error else {
                XCTFail("Expected noCards error"); return
            }
        }
    }

    func testParseEmptyFrontThrows() {
        let json = """
        { "deck_name": "Test", "cards": [{ "front": "", "back": "A" }] }
        """

        XCTAssertThrowsError(try JSONImporter.parse(json)) { error in
            guard case ImportError.invalidCard(let index, _) = error else {
                XCTFail("Expected invalidCard error"); return
            }
            XCTAssertEqual(index, 0)
        }
    }

    func testParseEmptyBackThrows() {
        let json = """
        { "deck_name": "Test", "cards": [{ "front": "Q", "back": "   " }] }
        """

        XCTAssertThrowsError(try JSONImporter.parse(json)) { error in
            guard case ImportError.invalidCard(let index, _) = error else {
                XCTFail("Expected invalidCard error"); return
            }
            XCTAssertEqual(index, 0)
        }
    }

    func testExportProducesValidJSON() throws {
        let deck = Deck(name: "Export Test", deckDescription: "Testing export")
        let card = Card(front: "Question", back: "Answer", hint: "Hint")
        card.deck = deck
        deck.cards.append(card)

        let jsonString = try JSONExporter.export(deck: deck)

        let reimported = try JSONImporter.parse(jsonString)
        XCTAssertEqual(reimported.deckName, "Export Test")
        XCTAssertEqual(reimported.cards.count, 1)
        XCTAssertEqual(reimported.cards[0].front, "Question")
    }
}
