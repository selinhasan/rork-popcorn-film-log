import SwiftUI

struct ReviewDetailView: View {
    let entry: LogEntry
    @State private var selectedFilm: Film?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Color(PopcornTheme.sepiaBrown.opacity(0.15))
                        .frame(height: 280)
                        .overlay {
                            AsyncImage(url: URL(string: entry.film.posterURL)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Image(systemName: "film")
                                        .font(.largeTitle)
                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipped()

                    LinearGradient(
                        colors: [.clear, .clear, PopcornTheme.cream.opacity(0.6), PopcornTheme.cream],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 280)
                    .allowsHitTesting(false)
                }

                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        AvatarView(name: "avatar_\((entry.userId.hashValue % 10 + 10) % 10 + 1)", size: 44)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(entry.username)
                                .font(.headline)
                                .foregroundStyle(PopcornTheme.darkBrown)
                            Text(entry.dateWatched, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.subtleGray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)

                    Button {
                        selectedFilm = entry.film
                    } label: {
                        HStack(spacing: 14) {
                            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                .frame(width: 64, height: 90)
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
                                Text(entry.film.title)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 6) {
                                    Text(entry.film.year)
                                    if !entry.film.director.isEmpty {
                                        Text("·")
                                        Text(entry.film.director)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .lineLimit(1)

                                if !entry.film.genre.isEmpty {
                                    Text(entry.film.genre.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.subtleGray)
                                }
                            }

                            Spacer(minLength: 0)

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(PopcornTheme.subtleGray)
                        }
                        .padding(14)
                        .background(Color.white, in: .rect(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 10) {
                        PopcornRatingDisplay(rating: entry.rating, isGoldenPopcorn: entry.isGoldenPopcorn)
                            .font(.title3)

                        if entry.isGoldenPopcorn {
                            HStack(spacing: 6) {
                                GoldenPopcornView(size: 14)
                                Text("Golden Popcorn")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.13))
                            }
                        }
                    }

                    if !entry.review.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Review")
                                .font(.headline)
                                .foregroundStyle(PopcornTheme.darkBrown)

                            Text(entry.review)
                                .font(.body)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                    }

                    if let ep = entry.episodeInfo, !ep.isEmpty {
                        HStack {
                            Image(systemName: "tv")
                                .foregroundStyle(PopcornTheme.freshGreen)
                            Text(ep)
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top, -10)
                .padding(.bottom, 30)
            }
        }
        .background(PopcornTheme.cream.ignoresSafeArea())
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedFilm) { film in
            FilmDetailSheet(film: film)
        }
    }
}
