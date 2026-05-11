import Foundation

enum StudyStatsService {

    static func currentStreak(from reviews: [ReviewLog], calendar: Calendar = .current) -> Int {
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        let hasReviewsToday = reviews.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
        if !hasReviewsToday {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDate) else { return 0 }
            checkDate = yesterday
        }

        while true {
            let hasActivity = reviews.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if !hasActivity { break }
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }

        return streak
    }

    static func masteredCount(from decks: [Deck]) -> Int {
        decks.flatMap(\.cards).filter { $0.interval >= 21 }.count
    }
}
