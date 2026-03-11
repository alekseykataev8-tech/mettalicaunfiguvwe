import SwiftUI
import SwiftData
import Combine

struct ReadingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]
    @State private var selectedBook: Book?
    @State private var isTimerRunning = false
    @State private var elapsedSeconds = 0
    @State private var timerBook: Book?
    @State private var showingLogSheet = false

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var readingBooks: [Book] {
        allBooks.filter { $0.status == .reading }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if readingBooks.isEmpty {
                    emptyState
                } else {
                    timerSection
                    bookPickerSection
                    activeBookSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(creamBackground.ignoresSafeArea())
        .navigationTitle("Reading Now")
        .onReceive(timer) { _ in
            if isTimerRunning {
                elapsedSeconds += 1
            }
        }
        .onAppear {
            if timerBook == nil {
                timerBook = readingBooks.first
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            if let book = timerBook {
                LogSessionView(book: book)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 60)

            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(warmBrown.opacity(0.25))

            Text("Nothing in progress")
                .font(.title2.bold())
                .foregroundStyle(warmBrown)

            Text("Start reading a book from your library")
                .font(.subheadline)
                .foregroundStyle(warmBrown.opacity(0.5))

            Spacer()
        }
    }

    private var timerSection: some View {
        VStack(spacing: 20) {
            if let book = timerBook {
                Text(book.title)
                    .font(.headline)
                    .foregroundStyle(warmBrown)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.6))
            }

            ZStack {
                Circle()
                    .stroke(warmBrown.opacity(0.1), lineWidth: 12)
                    .frame(width: 200, height: 200)

                if isTimerRunning {
                    Circle()
                        .trim(from: 0, to: min(Double(elapsedSeconds) / 3600.0, 1.0))
                        .stroke(.purple, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: elapsedSeconds)
                }

                VStack(spacing: 4) {
                    Text(formattedTime)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(warmBrown)
                        .monospacedDigit()

                    Text(isTimerRunning ? "Reading..." : "Ready")
                        .font(.caption)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
            }

            HStack(spacing: 16) {
                Button {
                    withAnimation(AppAnimation.quickSpring) {
                        isTimerRunning.toggle()
                    }
                } label: {
                    Label(isTimerRunning ? "Pause" : "Start Timer", systemImage: isTimerRunning ? "pause.fill" : "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(PressableButtonStyle())

                if elapsedSeconds > 0 {
                    Button {
                        isTimerRunning = false
                        showingLogSheet = true
                    } label: {
                        Label("Log Pages", systemImage: "square.and.pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(warmBrown.opacity(0.1))
                            .foregroundStyle(warmBrown)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }

            if elapsedSeconds > 0 && !isTimerRunning {
                Button {
                    elapsedSeconds = 0
                } label: {
                    Text("Reset Timer")
                        .font(.subheadline)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: warmBrown.opacity(0.1), radius: 12, x: 0, y: 6)
        .staggeredAppear(index: 0)
    }

    private var bookPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Select Book")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(warmBrown)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(readingBooks) { book in
                        Button {
                            withAnimation(AppAnimation.quickSpring) {
                                timerBook = book
                                if !isTimerRunning {
                                    elapsedSeconds = 0
                                }
                            }
                        } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(warmBrown.opacity(0.06))
                                        .frame(width: 60, height: 80)

                                    if let imageData = book.imageData, let uiImage = UIImage(data: imageData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 60, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    } else {
                                        Image(systemName: book.genre.iconName)
                                            .font(.title3)
                                            .foregroundStyle(.purple.opacity(0.4))
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(timerBook?.id == book.id ? Color.purple : Color.clear, lineWidth: 2)
                                )

                                Text(book.title)
                                    .font(.caption2)
                                    .foregroundStyle(warmBrown)
                                    .lineLimit(1)
                                    .frame(width: 60)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .staggeredAppear(index: 1)
    }

    private var activeBookSection: some View {
        Group {
            if let book = timerBook {
                VStack(spacing: 14) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(warmBrown)
                        Spacer()
                        Text("\(book.currentPage) / \(book.totalPages) pages")
                            .font(.caption)
                            .foregroundStyle(warmBrown.opacity(0.6))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(warmBrown.opacity(0.1))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(.purple)
                                .frame(width: geo.size.width * book.progress, height: 12)
                        }
                    }
                    .frame(height: 12)

                    HStack(spacing: 12) {
                        quickLogButton(pages: 10, book: book)
                        quickLogButton(pages: 25, book: book)
                        quickLogButton(pages: 50, book: book)
                    }
                }
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
                .staggeredAppear(index: 2)
            }
        }
    }

    private func quickLogButton(pages: Int, book: Book) -> some View {
        Button {
            quickLog(pages: pages, book: book)
        } label: {
            Text("+\(pages) pg")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple.opacity(0.1))
                .foregroundStyle(.purple)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func quickLog(pages: Int, book: Book) {
        let actualPages = min(pages, book.pagesRemaining)
        guard actualPages > 0 else { return }

        let session = ReadingSession(
            pagesRead: actualPages,
            durationMinutes: elapsedSeconds > 0 ? elapsedSeconds / 60 : 0,
            book: book
        )
        modelContext.insert(session)
        book.readingSessions.append(session)
        book.currentPage = min(book.currentPage + actualPages, book.totalPages)

        if book.currentPage >= book.totalPages {
            book.status = .finished
            book.finishDate = Date()
        }

        if elapsedSeconds > 0 {
            elapsedSeconds = 0
            isTimerRunning = false
        }
    }

    private var formattedTime: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        ReadingView()
    }
    .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
