import SwiftUI
import SwiftData

struct AddFriendView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var friendName: String = ""
    @State private var friendCode: String = ""
    @State private var showSuccess = false
    @State private var errorMessage: String?

    private var isValid: Bool {
        !friendName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !friendCode.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Friend's Name", text: $friendName)
                    TextField("Friend Code", text: $friendCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(.body, design: .monospaced))
                } header: {
                    Text("Enter Your Friend's Details")
                } footer: {
                    Text("Ask your friend to share their friend code from the Friends tab.")
                }

                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addFriend() }
                        .disabled(!isValid)
                        .bold()
                }
            }
            .alert("Friend Added!", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("\(friendName) has been added to your friends list.")
            }
        }
    }

    private func addFriend() {
        errorMessage = nil

        let name = friendName.trimmingCharacters(in: .whitespaces)
        let code = friendCode.trimmingCharacters(in: .whitespaces).uppercased()

        guard !name.isEmpty, !code.isEmpty else {
            errorMessage = "Please fill in both fields."
            return
        }

        let descriptor = FetchDescriptor<Friend>(
            predicate: #Predicate { $0.friendCode == code }
        )
        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            errorMessage = "A friend with this code already exists."
            return
        }

        let friend = Friend(
            displayName: name,
            friendCode: code
        )
        modelContext.insert(friend)
        try? modelContext.save()
        showSuccess = true
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: [Friend.self], inMemory: true)
}
