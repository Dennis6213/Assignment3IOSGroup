import SwiftUI

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    let card: Card?

    @State private var front: String = ""
    @State private var back: String = ""
    @State private var hint: String = ""
    @State private var showHint: Bool = false
    @State private var saveError: String?

    private var isEditing: Bool { card != nil }

    private var isValid: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextEditor(text: $front)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if front.isEmpty {
                                Text("Question or prompt...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Back") {
                    TextEditor(text: $back)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if back.isEmpty {
                                Text("Answer...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    DisclosureGroup("Hint (optional)", isExpanded: $showHint) {
                        TextField("Add a hint...", text: $hint)
                    }
                }

                if isEditing {
                    Section("Card Info") {
                        LabeledContent("Interval", value: "\(card?.interval ?? 0) days")
                        LabeledContent("Ease Factor", value: String(format: "%.2f", card?.easeFactor ?? 2.5))
                        LabeledContent("Repetitions", value: "\(card?.repetitions ?? 0)")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Card" : "New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .disabled(!isValid)
                        .bold()
                }
            }
            .alert("Save Failed", isPresented: .init(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .onAppear {
                if let card {
                    front = card.front
                    back = card.back
                    hint = card.hint ?? ""
                    showHint = card.hint != nil && !card.hint!.isEmpty
                }
            }
        }
    }

    private func saveCard() {
        let trimmedFront = front.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBack = back.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHint = hint.trimmingCharacters(in: .whitespacesAndNewlines)

        if let card {
            card.front = trimmedFront
            card.back = trimmedBack
            card.hint = trimmedHint.isEmpty ? nil : trimmedHint
        } else {
            let newCard = Card(
                front: trimmedFront,
                back: trimmedBack,
                hint: trimmedHint.isEmpty ? nil : trimmedHint
            )
            newCard.deck = deck
            deck.cards.append(newCard)
            modelContext.insert(newCard)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}

#Preview("New Card") {
    CardEditorView(deck: Deck(name: "Test"), card: nil)
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}

#Preview("Edit Card") {
    CardEditorView(
        deck: Deck(name: "Test"),
        card: Card(front: "What is Swift?", back: "A programming language", hint: "Apple made it")
    )
    .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
