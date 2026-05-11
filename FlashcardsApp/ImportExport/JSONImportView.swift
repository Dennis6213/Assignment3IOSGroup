import SwiftUI
import SwiftData

struct JSONImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var jsonInput: String = ""
    @State private var errorMessage: String?
    @State private var importedDeck: Deck?
    @State private var showSuccess = false
    @State private var showCopiedToast = false

    private static let llmPrompt = """
    Please generate me a JSON document in this format:

    {
      "deck_name": "Your Deck Name Here",
      "description": "A short description of the deck",
      "cards": [
        {
          "front": "Question or prompt text",
          "back": "Answer or explanation text",
          "hint": "Optional hint to help recall"
        }
      ]
    }

    Rules:
    - "deck_name" is required and must not be empty.
    - "description" is optional.
    - "cards" must contain at least one card.
    - Each card must have a non-empty "front" and "back".
    - "hint" is optional and can be omitted.
    - Return ONLY the raw JSON — no markdown, no code fences, no explanation.
    """

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                schemaInfoSection
                jsonInputSection

                if let errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal)
                }

                Button {
                    importJSON()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Flashcards")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(jsonInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Import JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Paste") {
                        if let clipboard = UIPasteboard.general.string {
                            jsonInput = clipboard
                        }
                    }
                }
            }
            .alert("Import Successful!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                if let deck = importedDeck {
                    Text("Created deck \"\(deck.name)\" with \(deck.totalCount) cards.")
                }
            }
        }
    }

    private var schemaInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("Generate with AI")
                    .font(.subheadline.bold())
            }

            Text("Copy this prompt and paste it into ChatGPT, Claude, or any LLM to generate flashcards:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(Self.llmPrompt)
                .font(.system(.caption2, design: .monospaced))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    Button {
                        UIPasteboard.general.string = Self.llmPrompt
                        withAnimation { showCopiedToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showCopiedToast = false }
                        }
                    } label: {
                        Label(showCopiedToast ? "Copied!" : "Copy Prompt", systemImage: showCopiedToast ? "checkmark" : "doc.on.doc")
                            .font(.caption2.bold())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(showCopiedToast ? Color.green : Color.purple)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .padding(8)
                }

            Text("Then paste the JSON output below and tap Import.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var jsonInputSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("JSON Input")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            TextEditor(text: $jsonInput)
                .font(.system(.caption, design: .monospaced))
                .frame(minHeight: 200)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if jsonInput.isEmpty {
                        Text("Paste your JSON here...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .padding(8)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding(.horizontal)
    }

    private func importJSON() {
        errorMessage = nil

        do {
            let importData = try JSONImporter.parse(jsonInput)
            let deck = JSONImporter.createDeck(from: importData)

            modelContext.insert(deck)
            try modelContext.save()

            importedDeck = deck
            showSuccess = true
        } catch let error as ImportError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Unexpected error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    JSONImportView()
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
