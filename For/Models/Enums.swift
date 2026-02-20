import SwiftUI

enum BookGenre: String, Codable, CaseIterable, Identifiable {
    case fiction
    case nonFiction
    case sciFi
    case fantasy
    case mystery
    case romance
    case biography
    case selfHelp
    case history
    case science
    case philosophy
    case poetry

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fiction: "Fiction"
        case .nonFiction: "Non-Fiction"
        case .sciFi: "Sci-Fi"
        case .fantasy: "Fantasy"
        case .mystery: "Mystery"
        case .romance: "Romance"
        case .biography: "Biography"
        case .selfHelp: "Self-Help"
        case .history: "History"
        case .science: "Science"
        case .philosophy: "Philosophy"
        case .poetry: "Poetry"
        }
    }

    var iconName: String {
        switch self {
        case .fiction: "book.fill"
        case .nonFiction: "text.book.closed.fill"
        case .sciFi: "sparkles"
        case .fantasy: "wand.and.stars"
        case .mystery: "magnifyingglass"
        case .romance: "heart.fill"
        case .biography: "person.fill"
        case .selfHelp: "lightbulb.fill"
        case .history: "clock.fill"
        case .science: "atom"
        case .philosophy: "brain.head.profile.fill"
        case .poetry: "quote.opening"
        }
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable {
    case wantToRead
    case reading
    case finished
    case abandoned

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wantToRead: "Want to Read"
        case .reading: "Reading"
        case .finished: "Finished"
        case .abandoned: "Abandoned"
        }
    }

    var iconName: String {
        switch self {
        case .wantToRead: "bookmark.fill"
        case .reading: "book.fill"
        case .finished: "checkmark.circle.fill"
        case .abandoned: "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .wantToRead: .blue
        case .reading: .purple
        case .finished: .green
        case .abandoned: .gray
        }
    }
}
