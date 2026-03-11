import Foundation
import SwiftData

@Model
final class ReadingGoal {
    var id: UUID
    var year: Int
    var targetBooks: Int
    var targetPages: Int

    init(
        year: Int,
        targetBooks: Int = 12,
        targetPages: Int = 5000
    ) {
        self.id = UUID()
        self.year = year
        self.targetBooks = targetBooks
        self.targetPages = targetPages
    }
}
