import Foundation
import SwiftData

enum SampleDeckLoader {

    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Deck>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        guard let url = Bundle.main.url(forResource: "sample_decks", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let deckArray = try? JSONDecoder().decode([FlashcardImportData].self, from: data) else {
            print("Could not load sample decks JSON")
            return
        }

        for importData in deckArray {
            let deck = JSONImporter.createDeck(from: importData)
            modelContext.insert(deck)
        }

        try? modelContext.save()
        print("Seeded \(deckArray.count) sample deck(s)")
    }
}
