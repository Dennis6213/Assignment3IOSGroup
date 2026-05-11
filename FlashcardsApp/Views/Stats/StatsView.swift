import SwiftUI
import SwiftData
import Charts

struct StatsDashboardView: View {
    @Query(sort: \ReviewLog.date, order: .reverse) private var allReviews: [ReviewLog]
    @Query private var allDecks: [Deck]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statTiles

                    if !dailyReviewData.isEmpty {
                        reviewsChart
                    }

                    if !allReviews.isEmpty {
                        gradeDistribution
                    }
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(
                icon: "checkmark.circle.fill",
                label: "Today",
                value: "\(reviewsToday)",
                color: .blue
            )
            StatTile(
                icon: "flame.fill",
                label: "Streak",
                value: "\(currentStreak)🔥",
                color: .orange
            )
            StatTile(
                icon: "brain",
                label: "Mastered",
                value: "\(masteredCount)",
                color: .green
            )
        }
    }

    private var reviewsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reviews per Day")
                .font(.headline)

            Chart(dailyReviewData, id: \.date) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: .day),
                    y: .value("Reviews", entry.count)
                )
                .foregroundStyle(.blue.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var gradeDistribution: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Grade Distribution")
                .font(.headline)

            Chart(gradeData, id: \.grade) { entry in
                SectorMark(
                    angle: .value("Count", entry.count),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(entry.color)
                .annotation(position: .overlay) {
                    if entry.count > 0 {
                        Text("\(entry.count)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(height: 200)

            HStack(spacing: 16) {
                ForEach(Grade.allCases, id: \.self) { grade in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(gradeColor(grade))
                            .frame(width: 8, height: 8)
                        Text(grade.label)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }


    private var reviewsToday: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allReviews.filter { $0.date >= startOfDay }.count
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        let todayReviews = allReviews.filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
        if todayReviews.isEmpty {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        while true {
            let dayReviews = allReviews.filter { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if dayReviews.isEmpty { break }
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }

        return streak
    }

    private var masteredCount: Int {
        allDecks.flatMap(\.cards).filter { $0.interval >= 21 }.count
    }

    private var dailyReviewData: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentReviews = allReviews.filter { $0.date >= thirtyDaysAgo }

        var countsByDay: [Date: Int] = [:]
        for review in recentReviews {
            let day = calendar.startOfDay(for: review.date)
            countsByDay[day, default: 0] += 1
        }

        return countsByDay.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private var gradeData: [(grade: String, count: Int, color: Color)] {
        Grade.allCases.map { grade in
            let count = allReviews.filter { $0.grade == grade }.count
            return (grade: grade.label, count: count, color: gradeColor(grade))
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
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    StatsDashboardView()
        .modelContainer(for: [Deck.self, Card.self, ReviewLog.self], inMemory: true)
}
