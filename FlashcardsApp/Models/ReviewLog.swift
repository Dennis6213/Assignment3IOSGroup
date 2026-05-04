import Foundation
import SwiftData

@Model
final class ReviewLog {
    var id: UUID
    var date: Date
    var gradeRawValue: Int
    var card: Card?

    init(id: UUID = UUID(), date: Date = Date(), grade: Grade, card: Card? = nil) {
        self.id = id
        self.date = date
        self.gradeRawValue = grade.rawValue
        self.card = card
    }

    var grade: Grade {
        get { Grade(rawValue: gradeRawValue) ?? .again }
        set { gradeRawValue = newValue.rawValue }
    }
}
