import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var friends: [Friend]
    @State private var selectedTab: FriendsTab = .friends

    enum FriendsTab: String, CaseIterable {
        case friends = "Friends"
        case activity = "Activity"
    }

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
        }
    }

    private var friendsContent: some View {
        Group {
            if friends.isEmpty {
                ContentUnavailableView {
                    Label("No Friends Yet", systemImage: "person.2")
                } description: {
                    Text("Connect with friends to see their activity and compete on leaderboards.")
                }
            } else {
                List {
                    ForEach(friends) { friend in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(friend.displayName)
                                .font(.subheadline.bold())
                            if let lastActive = friend.lastActiveDate {
                                Text("Active \(lastActive, style: .relative) ago")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
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
