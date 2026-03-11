import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]
    @State private var searchText = ""
    @State private var showingAddSheet = false

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    private var readingBooks: [Book] {
        filterBooks(allBooks.filter { $0.status == .reading })
    }

    private var wantToReadBooks: [Book] {
        filterBooks(allBooks.filter { $0.status == .wantToRead })
    }

    private var finishedBooks: [Book] {
        filterBooks(allBooks.filter { $0.status == .finished })
    }

    private var abandonedBooks: [Book] {
        filterBooks(allBooks.filter { $0.status == .abandoned })
    }

    private func filterBooks(_ books: [Book]) -> [Book] {
        if searchText.isEmpty { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            if !readingBooks.isEmpty {
                bookSection(title: "Reading", books: readingBooks, status: .reading)
            }
            if !wantToReadBooks.isEmpty {
                bookSection(title: "Want to Read", books: wantToReadBooks, status: .wantToRead)
            }
            if !finishedBooks.isEmpty {
                bookSection(title: "Finished", books: finishedBooks, status: .finished)
            }
            if !abandonedBooks.isEmpty {
                bookSection(title: "Abandoned", books: abandonedBooks, status: .abandoned)
            }

            if allBooks.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 48))
                            .foregroundStyle(warmBrown.opacity(0.3))
                        Text("Your library is empty")
                            .font(.headline)
                            .foregroundStyle(warmBrown)
                        Text("Tap + to add your first book")
                            .font(.subheadline)
                            .foregroundStyle(warmBrown.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(creamBackground.ignoresSafeArea())
        .searchable(text: $searchText, prompt: "Search books...")
        .navigationTitle("Library")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBookView()
        }
    }

    private func bookSection(title: String, books: [Book], status: ReadingStatus) -> some View {
        Section {
            ForEach(books) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    libraryRow(book: book)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteBook(book)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    ForEach(availableStatuses(for: book), id: \.self) { newStatus in
                        Button {
                            changeStatus(book, to: newStatus)
                        } label: {
                            Label(newStatus.displayName, systemImage: newStatus.iconName)
                        }
                        .tint(newStatus.color)
                    }
                }
            }
        } header: {
            HStack(spacing: 6) {
                Image(systemName: status.iconName)
                    .font(.caption2)
                    .foregroundStyle(status.color)
                Text(title)
                    .foregroundStyle(warmBrown)
                Text("\(books.count)")
                    .font(.caption2)
                    .foregroundStyle(warmBrown.opacity(0.5))
            }
        }
    }

    private func libraryRow(book: Book) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(warmBrown.opacity(0.06))
                    .frame(width: 48, height: 64)

                if let imageData = book.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: book.genre.iconName)
                        .font(.body)
                        .foregroundStyle(.purple.opacity(0.4))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(warmBrown)
                    .lineLimit(1)

                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(warmBrown.opacity(0.6))
                    .lineLimit(1)

                if book.status == .reading {
                    HStack(spacing: 6) {
                        ProgressView(value: book.progress)
                            .tint(.purple)
                            .frame(width: 60)

                        Text("\(Int(book.progress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                    }
                }

                if book.status == .finished, let rating = book.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 9))
                                .foregroundStyle(.yellow)
                        }
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(book.genre.displayName)
                    .font(.caption2)
                    .foregroundStyle(warmBrown.opacity(0.4))

                Text("\(book.totalPages) pg")
                    .font(.caption2)
                    .foregroundStyle(warmBrown.opacity(0.4))
            }
        }
        .padding(.vertical, 4)
    }

    private func availableStatuses(for book: Book) -> [ReadingStatus] {
        ReadingStatus.allCases.filter { $0 != book.status }
    }

    private func changeStatus(_ book: Book, to status: ReadingStatus) {
        withAnimation {
            book.status = status
            if status == .reading && book.startDate == nil {
                book.startDate = Date()
            }
            if status == .finished {
                book.finishDate = Date()
                book.currentPage = book.totalPages
            }
        }
    }

    private func deleteBook(_ book: Book) {
        withAnimation {
            modelContext.delete(book)
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
