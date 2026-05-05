import Foundation

struct ScheduleResult {
    let newInterval: Int
    let newEaseFactor: Double
    let newRepetitions: Int
    let nextDueDate: Date

    static let minimumEaseFactor: Double = 1.3
}

enum SM2Scheduler {

    static func schedule(card: Card, grade: Grade, now: Date = Date()) -> ScheduleResult {
        var interval = card.interval
        var easeFactor = card.easeFactor
        var repetitions = card.repetitions

        switch grade {
        case .again:
            repetitions = 0
            interval = 1
            easeFactor -= 0.2

        case .hard:
            if repetitions == 0 {
                interval = 1
            } else {
                interval = max(1, Int(Double(interval) * 1.2))
            }
            easeFactor -= 0.15
            repetitions += 1

        case .good:
            if repetitions == 0 {
                interval = 1
            } else if repetitions == 1 {
                interval = 6
            } else {
                interval = Int(round(Double(interval) * easeFactor))
            }
            repetitions += 1

        case .easy:
            if repetitions == 0 {
                interval = 1
            } else if repetitions == 1 {
                interval = 6
            } else {
                interval = Int(round(Double(interval) * easeFactor))
            }
            interval = Int(round(Double(interval) * 1.3))
            easeFactor += 0.15
            repetitions += 1
        }

        easeFactor = max(ScheduleResult.minimumEaseFactor, easeFactor)
        interval = max(1, interval)

        let nextDueDate = Calendar.current.date(byAdding: .day, value: interval, to: now) ?? now

        return ScheduleResult(
            newInterval: interval,
            newEaseFactor: easeFactor,
            newRepetitions: repetitions,
            nextDueDate: nextDueDate
        )
    }

    static func apply(result: ScheduleResult, to card: Card) {
        card.interval = result.newInterval
        card.easeFactor = result.newEaseFactor
        card.repetitions = result.newRepetitions
        card.dueDate = result.nextDueDate
    }

    static func previewIntervals(for card: Card, now: Date = Date()) -> [Grade: Int] {
        var previews: [Grade: Int] = [:]
        for grade in Grade.allCases {
            let result = schedule(card: card, grade: grade, now: now)
            previews[grade] = result.newInterval
        }
        return previews
    }
}
