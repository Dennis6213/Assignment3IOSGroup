import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query private var friends: [Friend]
    @Query private var userProfiles: [UserProfile]
    @Query(sort: \ReviewLog.date, order: .reverse) private var allReviews: [ReviewLog]
    @Query private var allDecks: [Deck]

    @State private var selectedMetric: LeaderboardMetric = .cardsReviewed

    private var myProfile: UserProfile? { userProfiles.first }

    enum LeaderboardMetric: String, CaseIterable {
        case cardsReviewed = "Cards Reviewed"
        case streak = "Streak"
        case mastered = "Mastered"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Metric", selection: $selectedMetric) {
                ForEach(LeaderboardMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 12) {
                    if rankedEntries.count >= 3 {
                        podiumView
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(rankedEntries.enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRowView(
                                rank: index + 1,
                                entry: entry,
                                isCurrentUser: entry.isMe
                            )

                            if index < rankedEntries.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
    }

    private var podiumView: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if rankedEntries.count >= 2 {
                podiumColumn(entry: rankedEntries[1], rank: 2, height: 80, color: .gray)
            }
            if rankedEntries.count >= 1 {
                podiumColumn(entry: rankedEntries[0], rank: 1, height: 110, color: .yellow)
            }
            if rankedEntries.count >= 3 {
                podiumColumn(entry: rankedEntries[2], rank: 3, height: 60, color: .orange)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8)
    }

    private func podiumColumn(entry: LeaderboardEntry, rank: Int, height: CGFloat, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(entry.isMe ? Color.blue : avatarColor(for: entry.name))
                    .frame(width: 44, height: 44)

                Text(String(entry.name.prefix(1)).uppercased())
                    .font(.headline.bold())
                    .foregroundStyle(.white)
            }

            Text(entry.name)
                .font(.caption.bold())
                .lineLimit(1)

            Text("\(entry.value)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack {
                Text(rankEmoji(rank))
                    .font(.title2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(color.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
    }

    private var rankedEntries: [LeaderboardEntry] {
        var entries: [LeaderboardEntry] = []

        let myStats = computeMyStats()
        entries.append(LeaderboardEntry(
            id: "me",
            name: myProfile?.displayName ?? "Me",
            cardsReviewed: myStats.cardsReviewed,
            streak: myStats.streak,
            mastered: myStats.mastered,
            isMe: true
        ))

        for friend in friends {
            entries.append(LeaderboardEntry(
                id: friend.id.uuidString,
                name: friend.displayName,
                cardsReviewed: friend.totalCardsReviewed,
                streak: friend.currentStreak,
                mastered: 0,
                isMe: false
            ))
        }

        return entries.sorted { entryValue($0) > entryValue($1) }
    }

    private func entryValue(_ entry: LeaderboardEntry) -> Int {
        switch selectedMetric {
        case .cardsReviewed: return entry.cardsReviewed
        case .streak: return entry.streak
        case .mastered: return entry.mastered
        }
    }

    private func computeMyStats() -> (cardsReviewed: Int, streak: Int, mastered: Int) {
        (
            cardsReviewed: allReviews.count,
            streak: StudyStatsService.currentStreak(from: allReviews),
            mastered: StudyStatsService.masteredCount(from: allDecks)
        )
    }

    private func rankEmoji(_ rank: Int) -> String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "\(rank)"
        }
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [.purple, .green, .orange, .pink, .teal, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let cardsReviewed: Int
    let streak: Int
    let mastered: Int
    let isMe: Bool

    var value: Int { cardsReviewed }
}

struct LeaderboardRowView: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(rankText)
                .font(.headline)
                .frame(width: 36)

            ZStack {
                Circle()
                    .fill(isCurrentUser ? Color.blue : avatarColor)
                    .frame(width: 36, height: 36)

                Text(String(entry.name.prefix(1)).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.name)
                        .font(.subheadline.weight(.medium))
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            Text("\(entry.cardsReviewed)")
                .font(.subheadline.bold())
                .foregroundStyle(isCurrentUser ? .blue : .primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isCurrentUser ? Color.blue.opacity(0.05) : Color.clear)
    }

    private var rankText: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(rank)"
        }
    }

    private var avatarColor: Color {
        let colors: [Color] = [.purple, .green, .orange, .pink, .teal, .indigo]
        let index = abs(entry.name.hashValue) % colors.count
        return colors[index]
    }
}

#Preview {
    LeaderboardView()
        .modelContainer(for: [
            Deck.self, Card.self, ReviewLog.self,
            UserProfile.self, Friend.self, SharedDeck.self
        ], inMemory: true)
}
