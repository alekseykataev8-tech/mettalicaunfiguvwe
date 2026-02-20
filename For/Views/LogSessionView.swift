import SwiftUI
import SwiftData

struct LogSessionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let book: Book

    @State private var pagesRead = ""
    @State private var durationMinutes = ""
    @State private var notes = ""
    @State private var sessionDate = Date()

    @AppStorage("defaultSessionDuration") private var defaultSessionDuration = 30

    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(warmBrown.opacity(0.06))
                                .frame(width: 50, height: 50)
                            Image(systemName: book.genre.iconName)
                                .foregroundStyle(.purple.opacity(0.5))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.subheadline.bold())
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Page \(book.currentPage) of \(book.totalPages)")
                                .font(.caption2)
                                .foregroundStyle(.purple)
                        }
                    }
                }

                Section("Session Details") {
                    TextField("Pages Read", text: $pagesRead)
                        .keyboardType(.numberPad)

                    HStack {
                        Text("Quick Add")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("+10") { addPages(10) }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                        Button("+25") { addPages(25) }
                            .buttonStyle(.bordered)
                            .tint(.purple)
                    }

                    TextField("Duration (minutes)", text: $durationMinutes)
                        .keyboardType(.numberPad)

                    DatePicker("Date", selection: $sessionDate, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Session notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSession()
                    }
                    .fontWeight(.semibold)
                    .disabled((Int(pagesRead) ?? 0) <= 0)
                }
            }
            .onAppear {
                durationMinutes = "\(defaultSessionDuration)"
            }
        }
    }

    private func addPages(_ count: Int) {
        let current = Int(pagesRead) ?? 0
        let maxRemaining = book.totalPages - book.currentPage
        let newValue = min(current + count, maxRemaining)
        pagesRead = "\(newValue)"
    }

    private func saveSession() {
        let pages = Int(pagesRead) ?? 0
        let duration = Int(durationMinutes) ?? 0

        let session = ReadingSession(
            date: sessionDate,
            pagesRead: pages,
            durationMinutes: duration,
            notes: notes,
            book: book
        )
        modelContext.insert(session)

        book.currentPage = min(book.currentPage + pages, book.totalPages)
        book.readingSessions.append(session)

        if book.currentPage >= book.totalPages {
            book.status = .finished
            book.finishDate = Date()
        } else if book.status == .wantToRead {
            book.status = .reading
            book.startDate = book.startDate ?? Date()
        }

        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, ReadingSession.self, ReadingGoal.self, configurations: config)
    let book = Book(title: "Sample Book", author: "Author Name", genre: .fiction, totalPages: 350, currentPage: 120, status: .reading)
    container.mainContext.insert(book)
    return LogSessionView(book: book)
        .modelContainer(container)
}
