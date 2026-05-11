import SwiftUI
import SwiftData

struct ShareDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \Friend.displayName) private var friends: [Friend]

    let deck: Deck
    @State private var selectedFriends: Set<UUID> = []
    @State private var showSuccess = false
    @State private var shareCount = 0

    private var myProfile: UserProfile? { userProfiles.first }

    var body: some View {
        NavigationStack {
            VStack {
                if friends.isEmpty {
                    ContentUnavailableView {
                        Label("No Friends", systemImage: "person.2")
                    } description: {
                        Text("Add friends first to share decks with them.")
                    }
                } else {
                    List {
                        Section {
                            HStack {
                                Image(systemName: "square.stack.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(deck.name)
                                        .font(.headline)
                                    Text("\(deck.totalCount) cards")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Section("Select Friends") {
                            ForEach(friends) { friend in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(.blue)
                                    Text(friend.displayName)
                                    Spacer()
                                    if selectedFriends.contains(friend.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFriends.contains(friend.id) {
                                        selectedFriends.remove(friend.id)
                                    } else {
                                        selectedFriends.insert(friend.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Share Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Share") { shareDeck() }
                        .disabled(selectedFriends.isEmpty)
                        .bold()
                }
            }
            .alert("Deck Shared!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Shared \"\(deck.name)\" with \(shareCount) friend(s).")
            }
        }
    }

    private func shareDeck() {
        guard let jsonData = try? JSONExporter.export(deck: deck) else { return }
        let senderName = myProfile?.displayName ?? "Someone"

        let selectedFriendsList = friends.filter { selectedFriends.contains($0.id) }
        for friend in selectedFriendsList {
            let shared = SharedDeck(
                deckName: deck.name,
                cardCount: deck.totalCount,
                sharedBy: senderName,
                jsonData: jsonData
            )
            modelContext.insert(shared)
        }

        shareCount = selectedFriendsList.count
        try? modelContext.save()
        showSuccess = true
    }
}

#Preview {
    ShareDeckView(deck: Deck(name: "Test Deck"))
        .modelContainer(for: [
            Deck.self, Card.self, ReviewLog.self,
            UserProfile.self, Friend.self, SharedDeck.self
        ], inMemory: true)
}
