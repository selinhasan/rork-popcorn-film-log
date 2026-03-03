import SwiftUI

struct DiaryView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showLogSheet = false

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
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.diaryEntries) { entry in
                                DiaryEntryCard(entry: entry)
                            }
                        }
                        .padding(.horizontal)
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

struct DiaryEntryCard: View {
    let entry: LogEntry

    var body: some View {
        HStack(spacing: 14) {
            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                .frame(width: 60, height: 85)
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

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.film.title)
                        .font(.headline)
                        .foregroundStyle(PopcornTheme.darkBrown)
                        .lineLimit(1)
                    if entry.film.isTV {
                        Text("TV")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PopcornTheme.freshGreen, in: .capsule)
                    }
                    if entry.isGoldenPopcorn {
                        GoldenPopcornView(size: 14)
                    }
                }

                if let ep = entry.episodeInfo, !ep.isEmpty {
                    Text(ep)
                        .font(.caption)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }

                PopcornRatingDisplay(rating: entry.rating, isGoldenPopcorn: entry.isGoldenPopcorn)

                if !entry.review.isEmpty {
                    Text(entry.review)
                        .font(.caption)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                        .lineLimit(2)
                }

                Text(entry.dateWatched.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(PopcornTheme.subtleGray)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
