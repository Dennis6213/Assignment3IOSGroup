import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var deck: Deck
    @State private var showingAddCard = false
    @State private var showingStudySession = false
    @State private var showingPracticeAll = false
    @State private var editingCard: Card?

    var sortedCards: [Card] {
        deck.cards.sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        List {
            if deck.dueCount > 0 {
                Section {
                    Button {
                        showingStudySession = true
                    } label: {
                        HStack {
                            Image(systemName: "brain")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Study Now")
                                    .font(.headline)
                                Text("\(deck.dueCount) cards due")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }

            if !deck.cards.isEmpty {
                Section {
                    Button {
                        showingPracticeAll = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text("Practice All")
                                    .font(.headline)
                                Text("Review all \(deck.totalCount) cards regardless of schedule")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(.primary)
                }
            }

            Section {
                if deck.cards.isEmpty {
                    ContentUnavailableView {
                        Label("No Cards", systemImage: "rectangle.on.rectangle")
                    } description: {
                        Text("Add flashcards manually or import from JSON.")
                    }
                } else {
                    ForEach(sortedCards) { card in
                        CardRowView(card: card)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCard = card
                            }
                    }
                    .onDelete(perform: deleteCards)
                }
            } header: {
                HStack {
                    Text("Cards (\(deck.totalCount))")
                    Spacer()
                }
            }
        }
        .navigationTitle(deck.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddCard) {
            CardEditorView(deck: deck, card: nil)
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(deck: deck, card: card)
        }
        .fullScreenCover(isPresented: $showingStudySession) {
            StudySessionView(deck: deck)
        }
        .fullScreenCover(isPresented: $showingPracticeAll) {
            StudySessionView(deck: deck, practiceAll: true)
        }
    }

    private func deleteCards(at offsets: IndexSet) {
        let sorted = sortedCards
        for index in offsets {
            let card = sorted[index]
            modelContext.delete(card)
        }
        try? modelContext.save()
    }
}


struct CardRowView: View {
    let card: Card

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.front)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(2)

                Text(card.back)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            statusLabel
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: some View {
        Group {
            if card.isNew {
                Text("New")
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            } else if card.isDue {
                Text("Due")
                    .font(.caption2.bold())
                    .foregroundStyle(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))
            } else {
                Text(dueDateText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dueDateText: String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: card.dueDate).day ?? 0
        if days <= 0 { return "Due" }
        if days == 1 { return "1d" }
        return "\(days)d"
    }
}

#Preview {
    NavigationStack {
        DeckDetailView(deck: Deck(name: "Preview Deck"))
    }
    .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
