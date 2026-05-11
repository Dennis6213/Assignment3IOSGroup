import SwiftUI
import SwiftData

struct AIGenerateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var numberOfCards = 10
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var generatedDeck: Deck?
    @State private var showSuccess = false
    @State private var showSettings = false

    @AppStorage("azure_endpoint") private var savedEndpoint = ""
    @AppStorage("azure_api_key") private var savedApiKey = ""
    @AppStorage("azure_deployment") private var savedDeployment = ""
    @AppStorage("azure_api_version") private var savedApiVersion = "2024-10-21"

    private var isConfigured: Bool {
        !savedEndpoint.isEmpty && !savedApiKey.isEmpty && !savedDeployment.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection

                    if !isConfigured {
                        configurationNeededSection
                    } else {
                        topicInputSection
                        cardCountSection
                        generateButton
                    }

                    if let errorMessage {
                        errorSection(errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("AI Generate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if isConfigured {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                AzureSettingsView()
            }
            .alert("Flashcards Generated!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                if let deck = generatedDeck {
                    Text("Created deck \"\(deck.name)\" with \(deck.totalCount) cards.")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 44))
                .foregroundStyle(.purple.gradient)

            Text("AI Flashcard Generator")
                .font(.title2.bold())

            Text("Describe a topic and let Azure OpenAI create study flashcards for you automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var configurationNeededSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.icloud")
                .font(.system(size: 36))
                .foregroundStyle(.orange)

            Text("Azure OpenAI Not Configured")
                .font(.headline)

            Text("Connect your Azure OpenAI service to start generating flashcards with AI.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showSettings = true
            } label: {
                Label("Configure Azure OpenAI", systemImage: "gear")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var topicInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What do you want to study?")
                .font(.headline)

            TextField("e.g. Photosynthesis, World War II, Python basics...", text: $topic, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)

            Text("Be specific for better results. For example: \"Key concepts in cellular biology for AP Bio\" instead of just \"biology\".")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var cardCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Number of cards")
                    .font(.headline)
                Spacer()
                Text("\(numberOfCards)")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.purple)
            }

            Slider(value: Binding(
                get: { Double(numberOfCards) },
                set: { numberOfCards = Int($0) }
            ), in: 5...30, step: 5)
            .tint(.purple)

            HStack {
                Text("5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("30")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var generateButton: some View {
        Button {
            Task { await generate() }
        } label: {
            HStack(spacing: 8) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Generating..." : "Generate Flashcards")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.purple)
        .disabled(topic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
    }

    private func errorSection(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.caption)
                .foregroundStyle(.red)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func generate() async {
        errorMessage = nil
        isGenerating = true
        defer { isGenerating = false }

        let config = AzureOpenAIConfig(
            endpoint: savedEndpoint,
            apiKey: savedApiKey,
            deploymentName: savedDeployment,
            apiVersion: savedApiVersion
        )

        guard config.isValid else {
            errorMessage = AIServiceError.notConfigured.errorDescription
            return
        }

        let service = AzureOpenAIService(config: config)

        do {
            let importData = try await service.generateFlashcards(
                topic: topic.trimmingCharacters(in: .whitespacesAndNewlines),
                numberOfCards: numberOfCards
            )
            let deck = JSONImporter.createDeck(from: importData)
            modelContext.insert(deck)
            try modelContext.save()

            generatedDeck = deck
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AzureSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("azure_endpoint") private var endpoint = ""
    @AppStorage("azure_api_key") private var apiKey = ""
    @AppStorage("azure_deployment") private var deployment = ""
    @AppStorage("azure_api_version") private var apiVersion = "2024-10-21"

    @State private var showApiKey = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Azure OpenAI Configuration", systemImage: "cloud.fill")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text("Enter your Azure OpenAI resource details to enable AI-powered flashcard generation.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("API Endpoint") {
                    TextField("https://your-resource.openai.azure.com", text: $endpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section("API Key") {
                    HStack {
                        if showApiKey {
                            TextField("Enter your API key", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        } else {
                            SecureField("Enter your API key", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        Button {
                            showApiKey.toggle()
                        } label: {
                            Image(systemName: showApiKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Deployment Name") {
                    TextField("e.g. gpt-4o, gpt-35-turbo", text: $deployment)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("API Version") {
                    TextField("e.g. 2024-10-21", text: $apiVersion)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(isValid ? .green : .gray)
                        Text(isValid ? "Configuration looks good" : "All fields are required")
                            .font(.subheadline)
                            .foregroundStyle(isValid ? .primary : .secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        endpoint = ""
                        apiKey = ""
                        deployment = ""
                        apiVersion = "2024-10-21"
                    } label: {
                        Label("Clear Configuration", systemImage: "trash")
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Azure Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var isValid: Bool {
        !endpoint.trimmingCharacters(in: .whitespaces).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty &&
        !deployment.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

#Preview {
    AIGenerateView()
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
