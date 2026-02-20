import Foundation
import SwiftData

@Model
final class ReadingSession {
    var id: UUID
    var date: Date
    var pagesRead: Int
    var durationMinutes: Int
    var notes: String
    var book: Book?

    init(
        date: Date = Date(),
        pagesRead: Int,
        durationMinutes: Int,
        notes: String = "",
        book: Book? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.pagesRead = pagesRead
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.book = book
    }
}
