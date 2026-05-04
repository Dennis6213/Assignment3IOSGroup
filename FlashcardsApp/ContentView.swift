import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Text("Decks")
                .tabItem {
                    Label("Decks", systemImage: "square.stack")
                }

            Text("Stats")
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }

            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
}
