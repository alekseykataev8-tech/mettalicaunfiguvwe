import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var book: Book
    @State private var showingLogSession = false
    @State private var appeared = false

    private let creamBackground = Color(red: 1.0, green: 0.97, blue: 0.94)
    private let warmBrown = Color(red: 0.45, green: 0.30, blue: 0.20)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                progressSection
                ratingSection
                infoSection
                sessionsSection
                notesSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 30)
        }
        .background(creamBackground.ignoresSafeArea())
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if book.status == .reading || book.status == .wantToRead {
                    Button {
                        showingLogSession = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLogSession) {
            LogSessionView(book: book)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimation.cardAppear) {
                    appeared = true
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(warmBrown.opacity(0.06))
                    .frame(width: 140, height: 200)

                if let imageData = book.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: book.genre.iconName)
                            .font(.system(size: 44))
                            .foregroundStyle(.purple.opacity(0.4))
                        Text(book.genre.displayName)
                            .font(.caption)
                            .foregroundStyle(warmBrown.opacity(0.5))
                    }
                }
            }
            .shadow(color: warmBrown.opacity(0.15), radius: 12, x: 0, y: 6)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            .animation(AppAnimation.cardAppear.delay(0.1), value: appeared)

            Text(book.title)
                .font(.title2.bold())
                .foregroundStyle(warmBrown)
                .multilineTextAlignment(.center)

            Text(book.author)
                .font(.subheadline)
                .foregroundStyle(warmBrown.opacity(0.6))

            HStack(spacing: 8) {
                Label(book.genre.displayName, systemImage: book.genre.iconName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.1))
                    .foregroundStyle(.purple)
                    .clipShape(Capsule())

                Label(book.status.displayName, systemImage: book.status.iconName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(book.status.color.opacity(0.1))
                    .foregroundStyle(book.status.color)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private var progressSection: some View {
        VStack(spacing: 16) {
            Text("Progress")
                .font(.headline)
                .foregroundStyle(warmBrown)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 24) {
                GoalRingView(progress: book.progress, lineWidth: 10, size: 100, color: .purple) {
                    Text("\(Int(book.progress * 100))%")
                        .font(.title3.bold())
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 8) {
                    detailRow(label: "Current Page", value: "\(book.currentPage)")
                    detailRow(label: "Total Pages", value: "\(book.totalPages)")
                    detailRow(label: "Remaining", value: "\(book.pagesRemaining)")
                    if book.pagesPerHour > 0 {
                        detailRow(label: "Speed", value: String(format: "%.0f pg/hr", book.pagesPerHour))
                    }
                }
            }

            if book.status == .reading || book.status == .wantToRead {
                Button {
                    showingLogSession = true
                } label: {
                    Label("Log Reading", systemImage: "square.and.pencil")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 0)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(warmBrown.opacity(0.6))
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(warmBrown)
        }
    }

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rating")
                .font(.headline)
                .foregroundStyle(warmBrown)

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Button {
                        withAnimation(AppAnimation.quickSpring) {
                            book.rating = book.rating == star ? nil : star
                        }
                    } label: {
                        Image(systemName: star <= (book.rating ?? 0) ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundStyle(star <= (book.rating ?? 0) ? .yellow : warmBrown.opacity(0.2))
                    }
                    .buttonStyle(.plain)
                    .bounce(trigger: book.rating == star)
                }

                Spacer()

                if let rating = book.rating {
                    Text("\(rating)/5")
                        .font(.subheadline.bold())
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

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundStyle(warmBrown)

            if let startDate = book.startDate {
                infoRow(icon: "calendar", label: "Started", value: startDate.formatted(date: .abbreviated, time: .omitted))
            }
            if let finishDate = book.finishDate {
                infoRow(icon: "calendar.badge.checkmark", label: "Finished", value: finishDate.formatted(date: .abbreviated, time: .omitted))
            }
            infoRow(icon: "calendar.badge.plus", label: "Added", value: book.dateAdded.formatted(date: .abbreviated, time: .omitted))

            if book.totalReadingMinutes > 0 {
                let hours = book.totalReadingMinutes / 60
                let minutes = book.totalReadingMinutes % 60
                infoRow(icon: "clock", label: "Total Time", value: hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m")
            }

            infoRow(icon: "number", label: "Sessions", value: "\(book.readingSessions.count)")
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 2)
    }

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(warmBrown)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundStyle(warmBrown.opacity(0.6))
        }
    }

    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Sessions")
                .font(.headline)
                .foregroundStyle(warmBrown)

            let sortedSessions = book.readingSessions.sorted { $0.date > $1.date }

            if sortedSessions.isEmpty {
                Text("No sessions logged yet")
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(sortedSessions.prefix(10).enumerated()), id: \.element.id) { index, session in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(warmBrown)
                            if !session.notes.isEmpty {
                                Text(session.notes)
                                    .font(.caption)
                                    .foregroundStyle(warmBrown.opacity(0.5))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(session.pagesRead) pages")
                                .font(.subheadline.bold())
                                .foregroundStyle(.purple)
                            if session.durationMinutes > 0 {
                                Text("\(session.durationMinutes) min")
                                    .font(.caption)
                                    .foregroundStyle(warmBrown.opacity(0.5))
                            }
                        }
                    }
                    .padding(.vertical, 4)

                    if index < min(sortedSessions.count, 10) - 1 {
                        Divider()
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

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundStyle(warmBrown)

            if book.notes.isEmpty {
                Text("No notes added")
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                Text(book.notes)
                    .font(.subheadline)
                    .foregroundStyle(warmBrown.opacity(0.7))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: warmBrown.opacity(0.08), radius: 8, x: 0, y: 4)
        .staggeredAppear(index: 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Book.self, ReadingSession.self, ReadingGoal.self, configurations: config)
    let book = Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: .fiction, totalPages: 180, currentPage: 75, status: .reading)
    container.mainContext.insert(book)
    return NavigationStack {
        BookDetailView(book: book)
    }
    .modelContainer(container)
}
