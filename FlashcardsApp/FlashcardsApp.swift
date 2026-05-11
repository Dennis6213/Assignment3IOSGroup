import SwiftUI
import SwiftData

@main
struct FlashcardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                }
        }
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self, UserProfile.self, Friend.self, SharedDeck.self])
    }
}
