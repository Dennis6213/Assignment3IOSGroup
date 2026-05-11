import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DeckListView()
                .tabItem {
                    Label("Decks", systemImage: "square.stack")
                }

            StatsDashboardView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct SettingsView: View {
    @State private var showingImport = false

    var body: some View {
        NavigationStack {
            List {
                Section("Flashcards") {
                    Button {
                        showingImport = true
                    } label: {
                        Label("Import from JSON", systemImage: "square.and.arrow.down")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Built with", value: "SwiftUI + SwiftData")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingImport) {
                JSONImportView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
