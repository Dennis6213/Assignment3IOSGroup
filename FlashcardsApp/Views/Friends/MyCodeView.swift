import SwiftUI

struct MyCodeView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile?

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text(profile?.displayName ?? "Me")
                    .font(.title2.bold())

                VStack(spacing: 8) {
                    Text("MY FRIEND CODE")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .tracking(2)

                    Text(profile?.friendCode ?? "--------")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                Text("Share this code with friends so they can add you!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                HStack(spacing: 16) {
                    Button {
                        if let code = profile?.friendCode {
                            UIPasteboard.general.string = code
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    ShareLink(item: "Add me on Flashcards! My friend code is: \(profile?.friendCode ?? "")") {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("My Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    MyCodeView(profile: UserProfile(displayName: "Dennis", friendCode: "A1B2C3D4"))
}
