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

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct SettingsView: View {
    @State private var showingImport = false
    @State private var showingAIGenerate = false
    @State private var showingAzureSettings = false
    @State private var remindersEnabled = false
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    var body: some View {
        NavigationStack {
            List {
                Section("Flashcards") {
                    Button {
                        showingAIGenerate = true
                    } label: {
                        Label("Generate with AI", systemImage: "sparkles")
                    }
                    .tint(.purple)

                    Button {
                        showingImport = true
                    } label: {
                        Label("Import from JSON", systemImage: "square.and.arrow.down")
                    }
                }

                Section("AI Configuration") {
                    Button {
                        showingAzureSettings = true
                    } label: {
                        Label("Azure OpenAI Settings", systemImage: "cloud.fill")
                    }
                }

                Section("Reminders") {
                    Toggle(isOn: $remindersEnabled) {
                        Label("Daily Reminder", systemImage: "bell.fill")
                    }
                    .onChange(of: remindersEnabled) { _, enabled in
                        if enabled {
                            Task {
                                let granted = await ReminderScheduler.requestPermission()
                                if granted {
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
                                    ReminderScheduler.scheduleDailyReminder(
                                        hour: components.hour ?? 9,
                                        minute: components.minute ?? 0
                                    )
                                } else {
                                    remindersEnabled = false
                                }
                            }
                        } else {
                            ReminderScheduler.cancelReminders()
                        }
                    }

                    if remindersEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newTime in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newTime)
                                ReminderScheduler.scheduleDailyReminder(
                                    hour: components.hour ?? 9,
                                    minute: components.minute ?? 0
                                )
                            }
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
            .sheet(isPresented: $showingAIGenerate) {
                AIGenerateView()
            }
            .sheet(isPresented: $showingAzureSettings) {
                AzureSettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
