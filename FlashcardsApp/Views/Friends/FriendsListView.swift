import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Friend.displayName) private var friends: [Friend]
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \SharedDeck.sharedAt, order: .reverse) private var sharedDecks: [SharedDeck]

    @State private var showingAddFriend = false
    @State private var showingMyCode = false
    @State private var showingSharedDecks = false
    @State private var selectedTab: FriendsTab = .friends

    enum FriendsTab: String, CaseIterable {
        case friends = "Friends"
        case activity = "Activity"
    }

    private var myProfile: UserProfile? { userProfiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    ForEach(FriendsTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                switch selectedTab {
                case .friends:
                    friendsContent
                case .activity:
                    ActivityFeedView()
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView()
            }
            .sheet(isPresented: $showingMyCode) {
                MyCodeView(profile: myProfile)
            }
            .onAppear {
                ensureProfileExists()
            }
        }
    }

    private var friendsContent: some View {
        List {
            myProfileSection

            if !sharedDecks.isEmpty {
                sharedDecksSection
            }

            if friends.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("No Friends Yet", systemImage: "person.2")
                    } description: {
                        Text("Add friends by sharing your friend code or entering theirs.")
                    }
                }
            } else {
                Section("Friends (\(friends.count))") {
                    ForEach(friends) { friend in
                        FriendRowView(friend: friend)
                    }
                    .onDelete(perform: deleteFriends)
                }
            }
        }
    }

    private var myProfileSection: some View {
        Section("My Profile") {
            if let profile = myProfile {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.displayName)
                            .font(.headline)
                        HStack(spacing: 4) {
                            Text("Code:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(profile.friendCode)
                                .font(.system(.caption, design: .monospaced).bold())
                                .foregroundStyle(.blue)
                        }
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = profile.friendCode
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                }

                Button {
                    showingMyCode = true
                } label: {
                    Label("Share My Friend Code", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var sharedDecksSection: some View {
        Section("Shared With Me (\(sharedDecks.count))") {
            ForEach(sharedDecks) { shared in
                SharedDeckRowView(sharedDeck: shared) {
                    importSharedDeck(shared)
                }
            }
            .onDelete(perform: deleteSharedDecks)
        }
    }

    private func ensureProfileExists() {
        if userProfiles.isEmpty {
            let profile = UserProfile(displayName: "Me")
            modelContext.insert(profile)
            try? modelContext.save()
        }
    }

    private func deleteFriends(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(friends[index])
        }
        try? modelContext.save()
    }

    private func deleteSharedDecks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sharedDecks[index])
        }
        try? modelContext.save()
    }

    private func importSharedDeck(_ shared: SharedDeck) {
        do {
            let importData = try JSONImporter.parse(shared.jsonData)
            let deck = JSONImporter.createDeck(from: importData)
            modelContext.insert(deck)
            modelContext.delete(shared)
            try modelContext.save()
        } catch {
            print("Failed to import shared deck: \(error)")
        }
    }
}

struct FriendRowView: View {
    let friend: Friend

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(avatarColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.displayName)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Label("\(friend.totalCardsReviewed)", systemImage: "checkmark.circle")
                    Label("\(friend.currentStreak)🔥", systemImage: "flame")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(timeAgoText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var avatarColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal]
        let index = abs(friend.displayName.hashValue) % colors.count
        return colors[index]
    }

    private var timeAgoText: String {
        let interval = Date().timeIntervalSince(friend.lastActive)
        if interval < 3600 { return "Now" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

struct SharedDeckRowView: View {
    let sharedDeck: SharedDeck
    let onImport: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(sharedDeck.deckName)
                    .font(.subheadline.weight(.medium))
                Text("\(sharedDeck.cardCount) cards from \(sharedDeck.sharedBy)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Import") {
                onImport()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }
}

#Preview {
    FriendsListView()
        .modelContainer(for: [
            Deck.self, Card.self, ReviewLog.self,
            UserProfile.self, Friend.self, SharedDeck.self,
            ActivityEvent.self
        ], inMemory: true)
}
