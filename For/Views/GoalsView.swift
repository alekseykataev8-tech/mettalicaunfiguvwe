import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allGoals: [ReadingGoal]
    @Query private var allBooks: [Book]
    @Query(sort: \ReadingSession.date, order: .reverse) private var allSessions: [ReadingSession]

    @State private var showingEditGoal = false
    @State private var appeared = false
    @State private var selectedRing: Int?

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var currentGoal: ReadingGoal? {
        allGoals.first { $0.year == currentYear }
    }

    private var booksFinishedThisYear: [Book] {
        allBooks.filter { book in
            guard book.status == .finished, let finishDate = book.finishDate else { return false }
            return Calendar.current.component(.year, from: finishDate) == currentYear
        }
    }

    private var pagesReadThisYear: Int {
        allSessions.filter { session in
            Calendar.current.component(.year, from: session.date) == currentYear
        }.reduce(0) { $0 + $1.pagesRead }
    }

    private var pagesReadThisMonth: Int {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())
        let year = calendar.component(.year, from: Date())
        return allSessions.filter { session in
            calendar.component(.month, from: session.date) == month &&
            calendar.component(.year, from: session.date) == year
        }.reduce(0) { $0 + $1.pagesRead }
    }

    private var minutesReadThisWeek: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return allSessions.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ringsSection
                ringDetailCard
                paceCard
                monthlyBreakdown
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(creamBackground.ignoresSafeArea())
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditGoal = true
                } label: {
                    Image(systemName: currentGoal == nil ? "plus.circle.fill" : "pencil.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.purple)
                }
            }
        }
        .sheet(isPresented: $showingEditGoal) {
            EditGoalView(existingGoal: currentGoal)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimation.cardAppear) {
                    appeared = true
                }
            }
        }
    }

    private var ringsSection: some View {
        VStack(spacing: 16) {
            Text("\(currentYear) Reading Goals")
                .font(.headline)
                .foregroundStyle(warmBrown)

            if let goal = currentGoal {
                HStack(spacing: 20) {
                    ringTappable(
                        index: 0,
                        label: "Books / Year",
                        current: booksFinishedThisYear.count,
                        target: goal.targetBooks,
                        color: .purple,
                        size: 100
                    )

                    ringTappable(
                        index: 1,
                        label: "Pages / Month",
                        current: pagesReadThisMonth,
                        target: goal.targetPages / 12,
                        color: .orange,
                        size: 100
                    )

                    ringTappable(
                        index: 2,
                        label: "Min / Week",
                        current: minutesReadThisWeek,
                        target: 300,
                        color: .green,
                        size: 100
                    )
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundStyle(warmBrown.opacity(0.3))

                    Text("No goal set for \(currentYear)")
                        .font(.subheadline)
                        .foregroundStyle(warmBrown.opacity(0.6))

                    Button("Set a Goal") {
                        showingEditGoal = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
                .padding(.vertical, 8)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: warmBrown.opacity(0.1), radius: 12, x: 0, y: 6)
        .staggeredAppear(index: 0)
    }

    private func ringTappable(index: Int, label: String, current: Int, target: Int, color: Color, size: CGFloat) -> some View {
        let progress = target > 0 ? min(Double(current) / Double(target), 1.0) : 0

        return Button {
            withAnimation(AppAnimation.quickSpring) {
                selectedRing = selectedRing == index ? nil : index
            }
        } label: {
            VStack(spacing: 8) {
                GoalRingView(progress: progress, lineWidth: 10, size: size, color: color) {
                    VStack(spacing: 0) {
                        Text("\(current)")
                            .font(.title3.bold())
                            .foregroundStyle(color)
                        Text("/ \(target)")
                            .font(.caption2)
                            .foregroundStyle(warmBrown.opacity(0.5))
                    }
                }

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(warmBrown.opacity(0.6))
            }
            .scaleEffect(selectedRing == index ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var ringDetailCard: some View {
        Group {
            if let ring = selectedRing, let goal = currentGoal {
                let (title, current, target, color, detail) = ringInfo(ring, goal: goal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Circle()
                            .fill(color)
                            .frame(width: 10, height: 10)
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(warmBrown)
                    }

                    Text("\(current) of \(target)")
                        .font(.title2.bold())
                        .foregroundStyle(color)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(warmBrown.opacity(0.6))

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(color.opacity(0.15))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(color)
                                .frame(width: geo.size.width * min(Double(current) / max(Double(target), 1), 1.0), height: 10)
                        }
                    }
                    .frame(height: 10)
                }
                .padding(16)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func ringInfo(_ index: Int, goal: ReadingGoal) -> (String, Int, Int, Color, String) {
        switch index {
        case 0:
            let remaining = max(goal.targetBooks - booksFinishedThisYear.count, 0)
            return ("Books This Year", booksFinishedThisYear.count, goal.targetBooks, .purple, "\(remaining) more books to reach your goal")
        case 1:
            let monthTarget = goal.targetPages / 12
            let remaining = max(monthTarget - pagesReadThisMonth, 0)
            return ("Pages This Month", pagesReadThisMonth, monthTarget, .orange, "\(remaining) more pages this month")
        default:
            let remaining = max(300 - minutesReadThisWeek, 0)
            return ("Minutes This Week", minutesReadThisWeek, 300, .green, "\(remaining) more minutes this week")
        }
    }

    private var paceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Pace")
                .font(.headline)
                .foregroundStyle(warmBrown)

            let dailyAvg = dailyPagesAverage()
            let projected = projectedBooks()

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text(String(format: "%.1f", dailyAvg))
                        .font(.title3.bold())
                        .foregroundStyle(.purple)
                    Text("pages/day")
                        .font(.caption2)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(warmBrown.opacity(0.1))
                    .frame(width: 1, height: 30)

                VStack(spacing: 4) {
                    Text("\(projected)")
                        .font(.title3.bold())
                        .foregroundStyle(.orange)
                    Text("projected books")
                        .font(.caption2)
                        .foregroundStyle(warmBrown.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 1)
    }

    private var monthlyBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Books Finished per Month")
                .font(.headline)
                .foregroundStyle(warmBrown)

            let monthlyData = monthlyFinishedData()
            let maxBooks = monthlyData.map(\.count).max() ?? 1

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(monthlyData.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        Text("\(data.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(warmBrown.opacity(0.5))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple.gradient)
                            .frame(height: appeared ? max(CGFloat(data.count) / CGFloat(max(maxBooks, 1)) * 80, data.count > 0 ? 8 : 2) : 2)
                            .animation(AppAnimation.cardAppear.delay(AppAnimation.staggerDelay(index: index)), value: appeared)

                        Text(data.label)
                            .font(.system(size: 9))
                            .foregroundStyle(warmBrown.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 2)
    }

    private func dailyPagesAverage() -> Double {
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let daysSoFar = max(calendar.dateComponents([.day], from: startOfYear, to: Date()).day ?? 1, 1)
        return Double(pagesReadThisYear) / Double(daysSoFar)
    }

    private func projectedBooks() -> Int {
        let finished = booksFinishedThisYear.count
        guard finished > 0 else { return 0 }
        let calendar = Calendar.current
        let startOfYear = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1))!
        let daysSoFar = max(calendar.dateComponents([.day], from: startOfYear, to: Date()).day ?? 1, 1)
        return Int(Double(finished) / Double(daysSoFar) * 365.0)
    }

    private func monthlyFinishedData() -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        var result: [(label: String, count: Int)] = []
        for month in 1...12 {
            let count = booksFinishedThisYear.filter { book in
                guard let date = book.finishDate else { return false }
                return calendar.component(.month, from: date) == month
            }.count
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            let date = calendar.date(from: DateComponents(year: currentYear, month: month, day: 1))!
            result.append((label: formatter.string(from: date), count: count))
        }
        return result
    }
}

struct EditGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let existingGoal: ReadingGoal?

    @State private var targetBooks = 12
    @State private var targetPages = 5000

    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    var body: some View {
        NavigationStack {
            Form {
                Section("Books Goal") {
                    Stepper(value: $targetBooks, in: 1...100) {
                        HStack {
                            Image(systemName: "book.fill")
                                .foregroundStyle(.purple)
                            Text("\(targetBooks) books")
                        }
                    }
                }

                Section("Pages Goal") {
                    Stepper(value: $targetPages, in: 500...100000, step: 500) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.orange)
                            Text("\(targetPages) pages")
                        }
                    }
                }
            }
            .navigationTitle(existingGoal == nil ? "Set Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let goal = existingGoal {
                    targetBooks = goal.targetBooks
                    targetPages = goal.targetPages
                }
            }
        }
    }

    private func saveGoal() {
        if let goal = existingGoal {
            goal.targetBooks = targetBooks
            goal.targetPages = targetPages
        } else {
            let year = Calendar.current.component(.year, from: Date())
            let goal = ReadingGoal(year: year, targetBooks: targetBooks, targetPages: targetPages)
            modelContext.insert(goal)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GoalsView()
    }
    .modelContainer(for: [Book.self, ReadingSession.self, ReadingGoal.self], inMemory: true)
}
