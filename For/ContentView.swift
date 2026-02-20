import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Book.dateAdded, order: .reverse) private var allBooks: [Book]
    @Query private var allGoals: [ReadingGoal]
    @Query(sort: \ReadingSession.date, order: .reverse) private var allSessions: [ReadingSession]

    @State private var showingAddBook = false
    @State private var showingSettings = false

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    private var currentlyReading: [Book] {
        allBooks.filter { $0.status == .reading }
    }

    private var wantToRead: [Book] {
        allBooks.filter { $0.status == .wantToRead }
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var currentGoal: ReadingGoal? {
        allGoals.first { $0.year == currentYear }
    }

    private var booksFinishedThisYear: Int {
        allBooks.filter { book in
            guard book.status == .finished, let finishDate = book.finishDate else { return false }
            return Calendar.current.component(.year, from: finishDate) == currentYear
        }.count
    }

    private var weeklyPages: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return allSessions.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.pagesRead }
    }

    private var weeklyMinutes: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return allSessions.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.durationMinutes }
    }

    private var readingStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) }).sorted().reversed()
        guard let first = uniqueDays.first else { return 0 }
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        guard calendar.isDate(first, inSameDayAs: today) || calendar.isDate(first, inSameDayAs: yesterday) else { return 0 }
        var streak = 1
        let sortedDays = Array(uniqueDays)
        for i in 1..<sortedDays.count {
            if calendar.isDate(sortedDays[i], inSameDayAs: calendar.date(byAdding: .day, value: -1, to: sortedDays[i - 1])!) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    heroSection
                    streakStrip
                    upNextSection
                    sectionCardsGrid
                    goalMiniCard
                    weeklyStatsMiniCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .background(creamBackground.ignoresSafeArea())
            .navigationTitle("For")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(warmBrown)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.purple)
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var heroSection: some View {
        Group {
            if let book = currentlyReading.first {
                NavigationLink(destination: BookDetailView(book: book)) {
                    HStack(spacing: 16) {
                        bookCoverView(book: book, width: 90, height: 130)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Currently Reading")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(warmBrown.opacity(0.7))
                                .textCase(.uppercase)
                                .tracking(1)

                            Text(book.title)
                                .font(.title3.bold())
                                .foregroundStyle(warmBrown)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(book.author)
                                .font(.subheadline)
                                .foregroundStyle(warmBrown.opacity(0.6))

                            Spacer(minLength: 0)

                            VStack(alignment: .leading, spacing: 4) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(warmBrown.opacity(0.15))
                                            .frame(height: 8)

                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(.purple)
                                            .frame(width: geo.size.width * book.progress, height: 8)
                                    }
                                }
                                .frame(height: 8)

                                Text("\(Int(book.progress * 100))% complete - \(book.pagesRemaining) pages left")
                                    .font(.caption2)
                                    .foregroundStyle(warmBrown.opacity(0.5))
                            }
                        }
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: warmBrown.opacity(0.1), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .staggeredAppear(index: 0)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(warmBrown.opacity(0.3))

                    Text("No book in progress")
                        .font(.headline)
                        .foregroundStyle(warmBrown)

                    Text("Tap + to add your first book")
                        .font(.subheadline)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: warmBrown.opacity(0.1), radius: 12, x: 0, y: 6)
                .staggeredAppear(index: 0)
            }
        }
    }

    private var streakStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Reading Streak")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(warmBrown)

                Spacer()

                if readingStreak > 0 {
                    HStack(spacing: 4) {
                        Text("\(readingStreak)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        Text("days")
                            .font(.caption)
                            .foregroundStyle(warmBrown.opacity(0.6))
                    }
                }
            }

            HStack(spacing: 4) {
                ForEach(streakDays(), id: \.date) { dayInfo in
                    VStack(spacing: 4) {
                        Text(dayInfo.label)
                            .font(.system(size: 9))
                            .foregroundStyle(warmBrown.opacity(0.5))

                        if dayInfo.hasReading {
                            Text("\u{1F525}")
                                .font(.system(size: 16))
                        } else {
                            Circle()
                                .fill(warmBrown.opacity(0.1))
                                .frame(width: 18, height: 18)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 1)
    }

    private var upNextSection: some View {
        Group {
            if !wantToRead.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Up Next")
                        .font(.headline)
                        .foregroundStyle(warmBrown)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(wantToRead) { book in
                                NavigationLink(destination: BookDetailView(book: book)) {
                                    VStack(spacing: 6) {
                                        bookCoverView(book: book, width: 70, height: 100)
                                        Text(book.title)
                                            .font(.caption2)
                                            .foregroundStyle(warmBrown)
                                            .lineLimit(1)
                                            .frame(width: 70)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .staggeredAppear(index: 2)
            }
        }
    }

    private var sectionCardsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
            NavigationLink(destination: LibraryView()) {
                sectionCard(
                    icon: "books.vertical.fill",
                    title: "Library",
                    subtitle: "\(allBooks.count) books",
                    color: .purple
                )
            }
            .buttonStyle(.plain)
            .staggeredAppear(index: 3)

            NavigationLink(destination: ReadingView()) {
                sectionCard(
                    icon: "book.fill",
                    title: "Reading Now",
                    subtitle: "\(currentlyReading.count) in progress",
                    color: .orange
                )
            }
            .buttonStyle(.plain)
            .staggeredAppear(index: 4)

            NavigationLink(destination: GoalsView()) {
                sectionCard(
                    icon: "target",
                    title: "Goals",
                    subtitle: goalSubtitle,
                    color: .green
                )
            }
            .buttonStyle(.plain)
            .staggeredAppear(index: 5)

            NavigationLink(destination: StatsView()) {
                sectionCard(
                    icon: "chart.bar.fill",
                    title: "Stats",
                    subtitle: "\(allSessions.count) sessions",
                    color: .cyan
                )
            }
            .buttonStyle(.plain)
            .staggeredAppear(index: 6)
        }
    }

    private var goalSubtitle: String {
        if let goal = currentGoal {
            return "\(booksFinishedThisYear)/\(goal.targetBooks) books"
        }
        return "Set a goal"
    }

    private func sectionCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(warmBrown)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(warmBrown.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var goalMiniCard: some View {
        Group {
            if let goal = currentGoal {
                NavigationLink(destination: GoalsView()) {
                    HStack(spacing: 16) {
                        GoalRingView(
                            progress: goal.targetBooks > 0 ? min(Double(booksFinishedThisYear) / Double(goal.targetBooks), 1.0) : 0,
                            lineWidth: 8,
                            size: 56,
                            color: .purple
                        ) {
                            Text("\(booksFinishedThisYear)")
                                .font(.caption.bold())
                                .foregroundStyle(.purple)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reading Goal \(currentYear)")
                                .font(.subheadline.bold())
                                .foregroundStyle(warmBrown)

                            Text("\(booksFinishedThisYear) of \(goal.targetBooks) books")
                                .font(.caption)
                                .foregroundStyle(warmBrown.opacity(0.6))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(warmBrown.opacity(0.3))
                    }
                    .padding(16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .staggeredAppear(index: 7)
            }
        }
    }

    private var weeklyStatsMiniCard: some View {
        NavigationLink(destination: StatsView()) {
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(weeklyPages)")
                        .font(.title3.bold())
                        .foregroundStyle(.purple)
                    Text("pages")
                        .font(.caption2)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }

                Rectangle()
                    .fill(warmBrown.opacity(0.1))
                    .frame(width: 1, height: 30)

                VStack(spacing: 4) {
                    Text(weeklyMinutes > 0 ? "\(weeklyMinutes / 60)h \(weeklyMinutes % 60)m" : "0m")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                    Text("reading")
                        .font(.caption2)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }

                Rectangle()
                    .fill(warmBrown.opacity(0.1))
                    .frame(width: 1, height: 30)

                VStack(spacing: 4) {
                    Text("\(allSessions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }.count)")
                        .font(.title3.bold())
                        .foregroundStyle(.green)
                    Text("sessions")
                        .font(.caption2)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
            .overlay(alignment: .topLeading) {
                Text("This Week")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(warmBrown.opacity(0.5))
                    .padding(.top, 8)
                    .padding(.leading, 12)
            }
        }
        .buttonStyle(.plain)
        .staggeredAppear(index: 8)
    }

    private func bookCoverView(book: Book, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(warmBrown.opacity(0.08))
                .frame(width: width, height: height)

            if let imageData = book.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: book.genre.iconName)
                        .font(.system(size: width * 0.3))
                        .foregroundStyle(.purple.opacity(0.4))
                    Text(book.genre.displayName)
                        .font(.system(size: 8))
                        .foregroundStyle(warmBrown.opacity(0.4))
                }
            }
        }
        .shadow(color: warmBrown.opacity(0.15), radius: 6, x: 0, y: 3)
    }

    private func streakDays() -> [(date: Date, label: String, hasReading: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let readingDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) })

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return (
                date: date,
                label: formatter.string(from: date),
                hasReading: readingDays.contains(date)
            )
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
