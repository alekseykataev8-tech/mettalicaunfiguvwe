import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var allBooks: [Book]
    @Query(sort: \ReadingSession.date, order: .reverse) private var allSessions: [ReadingSession]

    @State private var appeared = false
    @State private var chartPeriod: ChartPeriod = .week

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    enum ChartPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
    }

    private var finishedBooks: [Book] {
        allBooks.filter { $0.status == .finished }
    }

    private var totalPagesRead: Int {
        allSessions.reduce(0) { $0 + $1.pagesRead }
    }

    private var totalReadingMinutes: Int {
        allSessions.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryRow
                pagesBarChart
                genreDistribution
                streakCalendar
                topRatedSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(creamBackground.ignoresSafeArea())
        .navigationTitle("Stats")
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimation.cardAppear) {
                    appeared = true
                }
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            statMiniCard(value: "\(finishedBooks.count)", label: "Books", icon: "book.fill", color: .purple)
            statMiniCard(value: "\(totalPagesRead)", label: "Pages", icon: "doc.text.fill", color: .orange)
            statMiniCard(value: totalReadingMinutes >= 60 ? "\(totalReadingMinutes / 60)h" : "\(totalReadingMinutes)m", label: "Time", icon: "clock.fill", color: .cyan)
        }
        .staggeredAppear(index: 0)
    }

    private func statMiniCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(warmBrown)

            Text(label)
                .font(.caption2)
                .foregroundStyle(warmBrown.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: warmBrown.opacity(0.06), radius: 6, x: 0, y: 3)
    }

    private var pagesBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Pages Read")
                    .font(.headline)
                    .foregroundStyle(warmBrown)

                Spacer()

                Picker("Period", selection: $chartPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            let chartData = chartPeriod == .week ? weeklyChartData() : monthlyChartData()

            Chart(chartData, id: \.label) { item in
                BarMark(
                    x: .value("Day", item.label),
                    y: .value("Pages", item.pages)
                )
                .foregroundStyle(Color.purple.gradient)
                .cornerRadius(4)
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                        .foregroundStyle(warmBrown.opacity(0.1))
                    AxisValueLabel()
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 1)
    }

    private var genreDistribution: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By Genre")
                .font(.headline)
                .foregroundStyle(warmBrown)

            let genreCounts = Dictionary(grouping: allBooks, by: { $0.genre })
            let sortedGenres = BookGenre.allCases.filter { genreCounts[$0] != nil }
                .sorted { (genreCounts[$0]?.count ?? 0) > (genreCounts[$1]?.count ?? 0) }
            let maxCount = genreCounts.values.map(\.count).max() ?? 1

            if sortedGenres.isEmpty {
                Text("No books yet")
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(sortedGenres.enumerated()), id: \.element) { index, genre in
                    let count = genreCounts[genre]?.count ?? 0
                    HStack(spacing: 10) {
                        Image(systemName: genre.iconName)
                            .font(.caption)
                            .frame(width: 20)
                            .foregroundStyle(.purple)

                        Text(genre.displayName)
                            .font(.caption)
                            .foregroundStyle(warmBrown)
                            .frame(width: 75, alignment: .leading)

                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.purple.gradient)
                                .frame(width: appeared ? geo.size.width * CGFloat(count) / CGFloat(max(maxCount, 1)) : 0)
                                .animation(AppAnimation.cardAppear.delay(AppAnimation.staggerDelay(index: index)), value: appeared)
                        }
                        .frame(height: 16)

                        Text("\(count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(warmBrown.opacity(0.5))
                            .frame(width: 24, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 2)
    }

    private var streakCalendar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Reading Streak")
                    .font(.headline)
                    .foregroundStyle(warmBrown)

                Spacer()

                let streak = currentStreak()
                if streak > 0 {
                    HStack(spacing: 4) {
                        Text("\u{1F525}")
                        Text("\(streak) days")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                    }
                }
            }

            let days = last21Days()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days, id: \.date) { day in
                    VStack(spacing: 2) {
                        if day.hasReading {
                            Text("\u{1F525}")
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                        } else {
                            Circle()
                                .fill(warmBrown.opacity(0.08))
                                .frame(width: 32, height: 32)
                        }
                        Text(day.label)
                            .font(.system(size: 8))
                            .foregroundStyle(warmBrown.opacity(0.4))
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 3)
    }

    private var topRatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Rated")
                .font(.headline)
                .foregroundStyle(warmBrown)

            let topRated = finishedBooks
                .filter { ($0.rating ?? 0) >= 4 }
                .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
                .prefix(5)

            if topRated.isEmpty {
                Text("Rate your finished books to see them here")
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(topRated.enumerated()), id: \.element.id) { index, book in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.title3.bold())
                            .foregroundStyle(.purple)
                            .frame(width: 24)

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(warmBrown.opacity(0.06))
                                .frame(width: 36, height: 36)
                            Image(systemName: book.genre.iconName)
                                .font(.caption)
                                .foregroundStyle(.purple.opacity(0.4))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(book.title)
                                .font(.subheadline)
                                .foregroundStyle(warmBrown)
                                .lineLimit(1)
                            Text(book.author)
                                .font(.caption)
                                .foregroundStyle(warmBrown.opacity(0.5))
                                .lineLimit(1)
                        }

                        Spacer()

                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= (book.rating ?? 0) ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 4)
    }

    private func weeklyChartData() -> [(label: String, pages: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let pages = allSessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
                .reduce(0) { $0 + $1.pagesRead }
            return (label: formatter.string(from: date), pages: pages)
        }
    }

    private func monthlyChartData() -> [(label: String, pages: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"

        return (0..<6).reversed().map { offset in
            guard let monthDate = calendar.date(byAdding: .month, value: -offset, to: today) else {
                return (label: "", pages: 0)
            }
            let month = calendar.component(.month, from: monthDate)
            let year = calendar.component(.year, from: monthDate)
            let pages = allSessions.filter { session in
                calendar.component(.month, from: session.date) == month &&
                calendar.component(.year, from: session.date) == year
            }.reduce(0) { $0 + $1.pagesRead }
            return (label: formatter.string(from: monthDate), pages: pages)
        }
    }

    private func currentStreak() -> Int {
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

    private func last21Days() -> [(date: Date, label: String, hasReading: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let readingDays = Set(allSessions.map { calendar.startOfDay(for: $0.date) })
        let formatter = DateFormatter()
        formatter.dateFormat = "d"

        return (0..<21).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            return (date: date, label: formatter.string(from: date), hasReading: readingDays.contains(date))
        }
    }
}

#Preview {
    NavigationStack {
        StatsView()
    }
    .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
