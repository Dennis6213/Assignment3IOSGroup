import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let deck: Deck
    var practiceAll: Bool = false

    @Query private var userProfiles: [UserProfile]

    @State private var dueCards: [Card] = []
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var sessionComplete: Bool = false
    @State private var grades: [Grade] = []
    @State private var failedCards: [Card] = []
    @State private var startTime: Date = Date()
    @State private var isRetryRound: Bool = false

    private var currentCard: Card? {
        guard currentIndex < dueCards.count else { return nil }
        return dueCards[currentIndex]
    }

    private var progress: Double {
        guard !dueCards.isEmpty else { return 1.0 }
        return Double(currentIndex) / Double(dueCards.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if sessionComplete {
                    completionView
                } else if let card = currentCard {
                    studyView(card: card)
                } else {
                    emptyView
                }
            }
            .navigationTitle(deck.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                    }
                }
            }
        }
        .onAppear {
            loadDueCards()
        }
    }

    private func studyView(card: Card) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .tint(.blue)
                Text("Card \(currentIndex + 1) of \(dueCards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            FlipCardView(
                front: card.front,
                back: card.back,
                hint: card.hint,
                isFlipped: $isFlipped
            )

            Spacer()

            if isFlipped {
                gradingButtons(for: card)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Text("Tap the card to reveal the answer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical)
        .animation(.easeInOut(duration: 0.3), value: isFlipped)
    }

    private func gradingButtons(for card: Card) -> some View {
        let previews = SM2Scheduler.previewIntervals(for: card)

        return VStack(spacing: 8) {
            Text("How well did you know this?")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    gradeButton(grade: grade, interval: previews[grade] ?? 1)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    private func gradeButton(grade: Grade, interval: Int) -> some View {
        Button {
            gradeCard(grade)
        } label: {
            VStack(spacing: 4) {
                Text(grade.label)
                    .font(.subheadline.bold())
                Text(intervalText(interval))
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(gradeColor(grade).opacity(0.15))
            .foregroundStyle(gradeColor(grade))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: isRetryRound ? "arrow.trianglehead.2.clockwise.rotate.90" : "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(isRetryRound ? .orange : .green)

            Text(isRetryRound ? "Retry Complete!" : "Session Complete!")
                .font(.largeTitle.bold())

            VStack(spacing: 12) {
                statRow(icon: "rectangle.stack.fill", label: "Cards Reviewed", value: "\(grades.count)")
                statRow(icon: "target", label: "Accuracy", value: accuracyText)
                statRow(icon: "clock", label: "Time", value: elapsedTimeText)

                if !failedCards.isEmpty {
                    Divider()
                    statRow(icon: "exclamationmark.triangle.fill", label: "Needs Review", value: "\(failedCards.count)")
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if !failedCards.isEmpty {
                    Button {
                        retryFailedCards()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Retry Failed Cards (\(failedCards.count))")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.horizontal)

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView {
            Label("No Cards Due", systemImage: "checkmark.circle")
        } description: {
            Text("All cards in this deck are up to date!")
        } actions: {
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }


    private func loadDueCards() {
        if practiceAll {
            dueCards = deck.cards.shuffled()
        } else {
            dueCards = deck.cards
                .filter { $0.dueDate <= Date() }
                .sorted { $0.dueDate < $1.dueDate }
        }
        startTime = Date()
    }

    private func retryFailedCards() {
        dueCards = failedCards.shuffled()
        failedCards = []
        currentIndex = 0
        isFlipped = false
        sessionComplete = false
        grades = []
        startTime = Date()
        isRetryRound = true
    }

    private func gradeCard(_ grade: Grade) {
        guard let card = currentCard else { return }

        let result = SM2Scheduler.schedule(card: card, grade: grade)
        SM2Scheduler.apply(result: result, to: card)

        let log = ReviewLog(grade: grade, card: card)
        card.reviews.append(log)
        modelContext.insert(log)
        try? modelContext.save()

        grades.append(grade)

        if grade == .again {
            if !failedCards.contains(where: { $0.id == card.id }) {
                failedCards.append(card)
            }
        } else {
            failedCards.removeAll { $0.id == card.id }
        }

        if currentIndex + 1 < dueCards.count {
            isFlipped = false
            withAnimation {
                currentIndex += 1
            }
         } else {
            logSessionActivity()
            withAnimation {
                sessionComplete = true
            }
        }
    }

    private func gradeColor(_ grade: Grade) -> Color {
        switch grade {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }

    private func intervalText(_ days: Int) -> String {
        if days == 1 { return "1d" }
        if days < 30 { return "\(days)d" }
        if days < 365 { return "\(days / 30)mo" }
        return "\(days / 365)y"
    }

    private var accuracyText: String {
        guard !grades.isEmpty else { return "—" }
        let correct = grades.filter { $0 != .again }.count
        let pct = Int(Double(correct) / Double(grades.count) * 100)
        return "\(pct)%"
    }

    private var elapsedTimeText: String {
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        return String(format: "%dm %02ds", minutes, seconds)
    }

    private func statRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }

    private func logSessionActivity() {
        let userName = userProfiles.first?.displayName ?? "Me"
        let correct = grades.filter { $0 != .again }.count
        let accuracy = grades.isEmpty ? 0 : Int(Double(correct) / Double(grades.count) * 100)

        let event = ActivityEvent(
            userName: userName,
            eventType: "completed_session",
            detail: "Completed \(grades.count) cards in \"\(deck.name)\" with \(accuracy)% accuracy",
            isCurrentUser: true
        )
        modelContext.insert(event)

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        while true {
            let dayPredicate = checkDate
            let descriptor = FetchDescriptor<ReviewLog>(
                predicate: #Predicate { $0.date >= dayPredicate }
            )
            let count = (try? modelContext.fetchCount(descriptor)) ?? 0
            if count == 0 && !calendar.isDateInToday(checkDate) { break }
            if count > 0 { streak += 1 }
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        if streak > 0 && streak % 7 == 0 {
            let streakEvent = ActivityEvent(
                userName: userName,
                eventType: "streak_milestone",
                detail: "Reached a \(streak)-day study streak! 🔥",
                isCurrentUser: true
            )
            modelContext.insert(streakEvent)
        }

        try? modelContext.save()
    }
}

#Preview {
    StudySessionView(deck: Deck(name: "Preview"))
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self, UserProfile.self, Friend.self, SharedDeck.self, ActivityEvent.self], inMemory: true)
}
