import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var author = ""
    @State private var genre: BookGenre = .fiction
    @State private var totalPages = ""
    @State private var status: ReadingStatus = .wantToRead
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Book Details") {
                    TextField("Title", text: $title)
                    TextField("Author", text: $author)
                    TextField("Total Pages", text: $totalPages)
                        .keyboardType(.numberPad)
                }

                Section("Genre") {
                    Picker("Genre", selection: $genre) {
                        ForEach(BookGenre.allCases) { g in
                            Label(g.displayName, systemImage: g.iconName)
                                .tag(g)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ReadingStatus.allCases) { s in
                            Label(s.displayName, systemImage: s.iconName)
                                .tag(s)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveBook()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || author.isEmpty || (Int(totalPages) ?? 0) <= 0)
                }
            }
        }
    }

    private func saveBook() {
        let pages = Int(totalPages) ?? 0
        let book = Book(
            title: title,
            author: author,
            genre: genre,
            totalPages: pages,
            status: status,
            startDate: status == .reading ? Date() : nil,
            notes: notes
        )
        modelContext.insert(book)
        dismiss()
    }
}

#Preview {
    AddBookView()
        .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
