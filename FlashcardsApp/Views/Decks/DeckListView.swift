import SwiftUI
import SwiftData

struct DeckListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Deck.createdAt, order: .reverse) private var decks: [Deck]
    @State private var showingAddDeck = false
    @State private var newDeckName = ""
    @State private var newDeckDescription = ""
    @State private var createError: String?

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    emptyState
                } else {
                    deckList
                }
            }
            .navigationTitle("My Decks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDeck = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("New Deck", isPresented: $showingAddDeck) {
                TextField("Deck name", text: $newDeckName)
                TextField("Description (optional)", text: $newDeckDescription)
                Button("Cancel", role: .cancel) {
                    newDeckName = ""
                    newDeckDescription = ""
                }
                Button("Create") {
                    createDeck()
                }
                .disabled(newDeckName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .alert("Couldn't Create Deck", isPresented: .init(
                get: { createError != nil },
                set: { if !$0 { createError = nil } }
            )) {
                Button("OK", role: .cancel) { createError = nil }
            } message: {
                Text(createError ?? "")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Decks", systemImage: "square.stack")
        } description: {
            Text("Create a deck to start studying, or import flashcards from JSON.")
        } actions: {
            Button("Create Deck") {
                showingAddDeck = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var deckList: some View {
        List {
            ForEach(decks) { deck in
                NavigationLink(value: deck) {
                    DeckRowView(deck: deck)
                }
            }
            .onDelete(perform: deleteDecks)
        }
        .navigationDestination(for: Deck.self) { deck in
            DeckDetailView(deck: deck)
        }
    }

    private func createDeck() {
        let name = newDeckName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        if decks.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            createError = "A deck named \"\(name)\" already exists. Choose a different name."
            return
        }

        let deck = Deck(name: name, deckDescription: newDeckDescription.trimmingCharacters(in: .whitespaces))
        modelContext.insert(deck)

        do {
            try modelContext.save()
            newDeckName = ""
            newDeckDescription = ""
        } catch {
            createError = error.localizedDescription
        }
    }

    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(decks[index])
        }
        try? modelContext.save()
    }
}


struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        HStack {
            Image(systemName: "square.stack.fill")
                .font(.title2)
                .foregroundStyle(deck.dueCount > 0 ? .blue : .secondary)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.headline)

                Text("\(deck.dueCount) due / \(deck.totalCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if deck.dueCount > 0 {
                Text("\(deck.dueCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    DeckListView()
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
