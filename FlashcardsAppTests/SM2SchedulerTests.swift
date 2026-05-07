import XCTest
@testable import FlashcardsApp

final class SM2SchedulerTests: XCTestCase {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    func testAgainStartsCardOver() {
        let card = makeCard(interval: 10, easeFactor: 2.5, repetitions: 5)
        let result = SM2Scheduler.schedule(card: card, grade: .again, now: referenceDate)

        XCTAssertEqual(result.newRepetitions, 0)
        XCTAssertEqual(result.newEaseFactor, 2.3, accuracy: 0.01)
    }

    func testAgainKeepsEaseAboveFloor() {
        let card = makeCard(interval: 1, easeFactor: 1.4, repetitions: 0)
        let result = SM2Scheduler.schedule(card: card, grade: .again, now: referenceDate)

        XCTAssertEqual(result.newEaseFactor, 1.3, accuracy: 0.01)
    }

    func testHardOnNewCardKeepsNextStepShort() {
        let card = makeCard(interval: 0, easeFactor: 2.5, repetitions: 0)
        let result = SM2Scheduler.schedule(card: card, grade: .hard, now: referenceDate)

        XCTAssertEqual(result.newInterval, 1)
        XCTAssertEqual(result.newEaseFactor, 2.35, accuracy: 0.01)
    }

    func testHardExtendsExistingInterval() {
        let card = makeCard(interval: 10, easeFactor: 2.5, repetitions: 3)
        let result = SM2Scheduler.schedule(card: card, grade: .hard, now: referenceDate)

        XCTAssertEqual(result.newRepetitions, 4)
    }

    func testGoodOnFirstReviewSetsOneDayInterval() {
        let card = makeCard(interval: 0, easeFactor: 2.5, repetitions: 0)
        let result = SM2Scheduler.schedule(card: card, grade: .good, now: referenceDate)

        XCTAssertEqual(result.newInterval, 1)
    }

    func testGoodOnSecondReviewSetsSixDayInterval() {
        let card = makeCard(interval: 1, easeFactor: 2.5, repetitions: 1)
        let result = SM2Scheduler.schedule(card: card, grade: .good, now: referenceDate)

        XCTAssertEqual(result.newInterval, 6)
        XCTAssertEqual(result.newRepetitions, 2)
    }

    func testGoodAfterThatUsesEaseFactor() {
        let card = makeCard(interval: 6, easeFactor: 2.5, repetitions: 2)
        let result = SM2Scheduler.schedule(card: card, grade: .good, now: referenceDate)

        XCTAssertEqual(result.newRepetitions, 3)
    }

    func testEasyGivesExtraIntervalBoost() {
        let card = makeCard(interval: 6, easeFactor: 2.5, repetitions: 2)
        let result = SM2Scheduler.schedule(card: card, grade: .easy, now: referenceDate)

        XCTAssertEqual(result.newInterval, 20)
        XCTAssertEqual(result.newRepetitions, 3)
    }

    func testHardCannotPushEaseBelowMinimum() {
        let card = makeCard(interval: 5, easeFactor: 1.3, repetitions: 3)
        let result = SM2Scheduler.schedule(card: card, grade: .hard, now: referenceDate)

        XCTAssertGreaterThanOrEqual(result.newEaseFactor, 1.3)
    }

    func testDueDateAdvancedByInterval() {
        let card = makeCard(interval: 6, easeFactor: 2.5, repetitions: 2)
        let result = SM2Scheduler.schedule(card: card, grade: .good, now: referenceDate)

        let expectedDate = Calendar.current.date(byAdding: .day, value: result.newInterval, to: referenceDate)!
        XCTAssertEqual(result.nextDueDate, expectedDate)
    }

    func testPreviewIntervalsReturnsAllGrades() {
        let card = makeCard(interval: 6, easeFactor: 2.5, repetitions: 2)
        let previews = SM2Scheduler.previewIntervals(for: card, now: referenceDate)

        XCTAssertEqual(previews.count, 4)
        XCTAssertNotNil(previews[.again])
        XCTAssertNotNil(previews[.hard])
        XCTAssertNotNil(previews[.good])
        XCTAssertNotNil(previews[.easy])
    }

    func testApplyMutatesCard() {
        let card = makeCard(interval: 0, easeFactor: 2.5, repetitions: 0)
        let result = SM2Scheduler.schedule(card: card, grade: .good, now: referenceDate)
        SM2Scheduler.apply(result: result, to: card)

        XCTAssertEqual(card.interval, result.newInterval)
        XCTAssertEqual(card.easeFactor, result.newEaseFactor)
        XCTAssertEqual(card.repetitions, result.newRepetitions)
        XCTAssertEqual(card.dueDate, result.nextDueDate)
    }

    private func makeCard(
        interval: Int = 0,
        easeFactor: Double = 2.5,
        repetitions: Int = 0
    ) -> Card {
        Card(
            front: "Front",
            back: "Back",
            interval: interval,
            easeFactor: easeFactor,
            repetitions: repetitions,
            dueDate: referenceDate
        )
    }
}
