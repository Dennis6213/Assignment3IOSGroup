import SwiftUI
import SwiftData

struct ActivityFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityEvent.timestamp, order: .reverse) private var activities: [ActivityEvent]
    @Query private var friends: [Friend]
    @Query private var userProfiles: [UserProfile]

    var body: some View {
        VStack(spacing: 0) {
            if activities.isEmpty {
                ContentUnavailableView {
                    Label("No Activity Yet", systemImage: "bell")
                } description: {
                    Text("Activity will appear here when you or your friends study flashcards.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedActivities, id: \.date) { group in
                            Section {
                                ForEach(group.events) { event in
                                    ActivityRowView(event: event)

                                    if event.id != group.events.last?.id {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            } header: {
                                HStack {
                                    Text(group.label)
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .textCase(.uppercase)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
                                .padding(.bottom, 6)
                            }
                        }
                    }
                }
            }
        }
    }

    private var groupedActivities: [ActivityGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { event in
            calendar.startOfDay(for: event.timestamp)
        }

        return grouped.map { date, events in
            ActivityGroup(date: date, events: events, label: dayLabel(for: date))
        }
        .sorted { $0.date > $1.date }
    }

    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

struct ActivityGroup {
    let date: Date
    let events: [ActivityEvent]
    let label: String
}

struct ActivityRowView: View {
    let event: ActivityEvent

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(colorForEvent.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: event.type.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(colorForEvent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(event.userName)
                        .font(.subheadline.bold())
                        .foregroundStyle(event.isCurrentUser ? .blue : .primary)

                    if event.isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }

                Text(event.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(timeAgo(from: event.timestamp))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var colorForEvent: Color {
        switch event.type {
        case .completedSession: return .green
        case .newDeck:          return .blue
        case .streakMilestone:  return .orange
        case .masteredCard:     return .yellow
        }
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "Just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    ActivityFeedView()
        .modelContainer(for: [
            Deck.self, Card.self, ReviewLog.self,
            UserProfile.self, Friend.self, SharedDeck.self,
            ActivityEvent.self
        ], inMemory: true)
}
