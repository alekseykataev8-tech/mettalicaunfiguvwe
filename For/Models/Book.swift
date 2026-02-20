import Foundation
import SwiftData

@Model
final class Book {
    var id: UUID
    var title: String
    var author: String
    var genre: BookGenre
    var totalPages: Int
    var currentPage: Int
    var status: ReadingStatus
    var rating: Int?
    var startDate: Date?
    var finishDate: Date?
    var imageData: Data?
    var notes: String
    var dateAdded: Date

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var readingSessions: [ReadingSession]

    init(
        title: String,
        author: String,
        genre: BookGenre,
        totalPages: Int,
        currentPage: Int = 0,
        status: ReadingStatus = .wantToRead,
        rating: Int? = nil,
        startDate: Date? = nil,
        finishDate: Date? = nil,
        imageData: Data? = nil,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.genre = genre
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.status = status
        self.rating = rating
        self.startDate = startDate
        self.finishDate = finishDate
        self.imageData = imageData
        self.notes = notes
        self.dateAdded = Date()
        self.readingSessions = []
    }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages)
    }

    var pagesRemaining: Int {
        max(totalPages - currentPage, 0)
    }

    var totalReadingMinutes: Int {
        readingSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var pagesPerHour: Double {
        let totalMinutes = totalReadingMinutes
        guard totalMinutes > 0 else { return 0 }
        let totalPagesRead = readingSessions.reduce(0) { $0 + $1.pagesRead }
        return Double(totalPagesRead) / (Double(totalMinutes) / 60.0)
    }
}
