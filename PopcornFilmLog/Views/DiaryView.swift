import SwiftUI

struct DiaryView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showLogSheet = false

    private var groupedEntries: [(key: String, date: Date, entries: [LogEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.diaryEntries) { entry in
            calendar.startOfDay(for: entry.dateWatched)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (key: formatSectionDate($0.key), date: $0.key, entries: $0.value) }
    }

    private func formatSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date).uppercased()
    }

    private var monthGrouped: [(month: String, days: [(date: Date, entries: [LogEntry])])] {
        let calendar = Calendar.current
        let dayGrouped = Dictionary(grouping: viewModel.diaryEntries) { entry in
            calendar.startOfDay(for: entry.dateWatched)
        }
        let sortedDays = dayGrouped.sorted { $0.key > $1.key }

        var months: [(month: String, days: [(date: Date, entries: [LogEntry])])] = []
        var currentMonth = ""
        var currentDays: [(date: Date, entries: [LogEntry])] = []

        for day in sortedDays {
            let month = formatSectionDate(day.key)
            if month != currentMonth {
                if !currentDays.isEmpty {
                    months.append((month: currentMonth, days: currentDays))
                }
                currentMonth = month
                currentDays = []
            }
            currentDays.append((date: day.key, entries: day.value))
        }
        if !currentDays.isEmpty {
            months.append((month: currentMonth, days: currentDays))
        }
        return months
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 14) {
                        PopcornLogoView(size: 36)
                        Text("Popcorn")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(PopcornTheme.darkBrown)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    Button {
                        showLogSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "popcorn.fill")
                                .font(.title2)
                            Text("Log a Film")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [PopcornTheme.warmRed, Color(red: 0.72, green: 0.2, blue: 0.18)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: .rect(cornerRadius: 16)
                        )
                        .shadow(color: PopcornTheme.warmRed.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal)

                    if viewModel.diaryEntries.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 48))
                                .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.4))
                            Text("Your diary is empty")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(PopcornTheme.darkBrown)
                            Text("Tap 'Log a Film' to start tracking what you watch!")
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                        .padding(.horizontal, 32)
                    } else {
                        LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                            ForEach(monthGrouped, id: \.month) { monthGroup in
                                Section {
                                    ForEach(monthGroup.days, id: \.date) { dayGroup in
                                        DiaryDayRow(date: dayGroup.date, entries: dayGroup.entries)
                                    }
                                } header: {
                                    HStack {
                                        Text(monthGroup.month)
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(PopcornTheme.sepiaBrown)
                                            .tracking(1.5)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(PopcornTheme.cream.opacity(0.95))
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .sheet(isPresented: $showLogSheet) {
                LogFilmView()
            }
        }
    }
}

struct DiaryDayRow: View {
    let date: Date
    let entries: [LogEntry]

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(PopcornTheme.darkBrown)
                Text(dayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(PopcornTheme.sepiaBrown)
            }
            .frame(width: 44)
            .padding(.top, 4)

            VStack(spacing: 8) {
                ForEach(entries) { entry in
                    DiaryEntryCard(entry: entry)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

struct DiaryEntryCard: View {
    let entry: LogEntry

    var body: some View {
        HStack(spacing: 12) {
            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                .frame(width: 56, height: 80)
                .overlay {
                    AsyncImage(url: URL(string: entry.film.posterURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "film")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(entry.film.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PopcornTheme.darkBrown)
                        .lineLimit(1)
                    if entry.film.isTV {
                        Text("TV")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(PopcornTheme.freshGreen, in: .capsule)
                    }
                }

                Text(entry.film.year)
                    .font(.caption)
                    .foregroundStyle(PopcornTheme.sepiaBrown)

                if let ep = entry.episodeInfo, !ep.isEmpty {
                    Text(ep)
                        .font(.caption2)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }

                HStack(spacing: 4) {
                    if entry.isGoldenPopcorn {
                        GoldenPopcornView(size: 12)
                        Text("Golden Popcorn")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.13))
                    } else {
                        PopcornRatingDisplay(rating: entry.rating, isGoldenPopcorn: false)
                    }
                }

                if !entry.review.isEmpty {
                    Text(entry.review)
                        .font(.caption2)
                        .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.8))
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color.white, in: .rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }
}
