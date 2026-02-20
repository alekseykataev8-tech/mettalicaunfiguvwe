import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step = 0
    @State private var selectedGenres: Set<BookGenre> = []
    @State private var bookTitle = ""
    @State private var bookAuthor = ""
    @State private var bookPages = ""

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    private let genresWithEmoji: [(genre: BookGenre, emoji: String)] = [
        (.fiction, "\u{1F4D6}"),
        (.nonFiction, "\u{1F4DA}"),
        (.sciFi, "\u{1F680}"),
        (.fantasy, "\u{1FA84}"),
        (.mystery, "\u{1F50D}"),
        (.romance, "\u{2764}\u{FE0F}"),
        (.biography, "\u{1F464}"),
        (.selfHelp, "\u{1F4A1}"),
        (.history, "\u{1F3DB}\u{FE0F}"),
        (.science, "\u{1F52C}"),
        (.philosophy, "\u{1F9E0}"),
        (.poetry, "\u{270F}\u{FE0F}")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            if step == 0 {
                welcomeStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            } else if step == 1 {
                genrePickerStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            } else {
                firstBookStep
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }

            Spacer()

            bottomButton
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(creamBackground.ignoresSafeArea())
        .animation(AppAnimation.smooth, value: step)
    }

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 70))
                .foregroundStyle(.purple)

            Text("Welcome to For")
                .font(.largeTitle.bold())
                .foregroundStyle(warmBrown)

            Text("Your personal reading companion.\nTrack books, set goals, and build reading habits.")
                .font(.body)
                .foregroundStyle(warmBrown.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private var genrePickerStep: some View {
        VStack(spacing: 20) {
            Text("Pick your favorite genres")
                .font(.title2.bold())
                .foregroundStyle(warmBrown)

            Text("Select at least 3")
                .font(.subheadline)
                .foregroundStyle(warmBrown.opacity(0.5))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 12) {
                ForEach(genresWithEmoji, id: \.genre) { item in
                    let isSelected = selectedGenres.contains(item.genre)
                    Button {
                        withAnimation(AppAnimation.quickSpring) {
                            if isSelected {
                                selectedGenres.remove(item.genre)
                            } else {
                                selectedGenres.insert(item.genre)
                            }
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text(item.emoji)
                                .font(.title2)
                            Text(item.genre.displayName)
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(isSelected ? .white : warmBrown)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(isSelected ? Color.purple : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: warmBrown.opacity(isSelected ? 0.15 : 0.06), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var firstBookStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.fill")
                .font(.system(size: 50))
                .foregroundStyle(.purple)

            Text("What are you reading?")
                .font(.title2.bold())
                .foregroundStyle(warmBrown)

            Text("Add your first book to get started")
                .font(.subheadline)
                .foregroundStyle(warmBrown.opacity(0.5))

            VStack(spacing: 14) {
                TextField("Book title", text: $bookTitle)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: warmBrown.opacity(0.06), radius: 4, x: 0, y: 2)

                TextField("Author", text: $bookAuthor)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: warmBrown.opacity(0.06), radius: 4, x: 0, y: 2)

                TextField("Total pages", text: $bookPages)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: warmBrown.opacity(0.06), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 24)
        }
    }

    private var bottomButton: some View {
        Button {
            handleNext()
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isButtonEnabled ? Color.purple : Color.purple.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isButtonEnabled)
    }

    private var buttonTitle: String {
        switch step {
        case 0: return "Let's Go"
        case 1: return "Continue"
        default: return bookTitle.isEmpty ? "Skip" : "Start Reading"
        }
    }

    private var isButtonEnabled: Bool {
        switch step {
        case 0: return true
        case 1: return selectedGenres.count >= 3
        default: return true
        }
    }

    private func handleNext() {
        switch step {
        case 0:
            withAnimation { step = 1 }
        case 1:
            withAnimation { step = 2 }
        default:
            if !bookTitle.isEmpty, !bookAuthor.isEmpty, let pages = Int(bookPages), pages > 0 {
                let genre = selectedGenres.first ?? .fiction
                let book = Book(
                    title: bookTitle,
                    author: bookAuthor,
                    genre: genre,
                    totalPages: pages,
                    status: .reading,
                    startDate: Date()
                )
                modelContext.insert(book)
            }
            withAnimation(AppAnimation.smooth) {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
