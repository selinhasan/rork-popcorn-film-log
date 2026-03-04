import SwiftUI

struct BrowseView: View {
    @State private var searchText = ""
    @State private var selectedGenre: String? = nil
    @State private var sortOption: SortOption = .popular
    @State private var selectedFilm: Film?

    enum SortOption: String, CaseIterable {
        case popular = "Popular"
        case topRated = "Top Rated"
        case newest = "Newest"
        case oldest = "Oldest"
    }

    private var filteredFilms: [Film] {
        var films = MockDataService.allContent
        if !searchText.isEmpty {
            films = films.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        if let genre = selectedGenre {
            films = films.filter { $0.genre.contains(genre) }
        }
        switch sortOption {
        case .popular: break
        case .topRated: films.sort { $0.averageRating > $1.averageRating }
        case .newest: films.sort { $0.year > $1.year }
        case .oldest: films.sort { $0.year < $1.year }
        }
        return films
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    genreChips
                    sortPicker
                    filmGrid
                    articlesSection
                }
                .padding(.bottom, 20)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search films & shows")
            .sheet(item: $selectedFilm) { film in
                FilmDetailSheet(film: film)
            }
        }
    }

    private var genreChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                genreButton(nil, label: "All")
                ForEach(MockDataService.genres, id: \.self) { genre in
                    genreButton(genre, label: genre)
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
    }

    private func genreButton(_ genre: String?, label: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedGenre = genre
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(selectedGenre == genre ? .white : PopcornTheme.darkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    selectedGenre == genre ? PopcornTheme.warmRed : Color.white,
                    in: .capsule
                )
                .overlay {
                    if selectedGenre != genre {
                        Capsule()
                            .stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                    }
                }
        }
    }

    private var sortPicker: some View {
        HStack {
            Text("Sort by")
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.sepiaBrown)
            Picker("Sort", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(PopcornTheme.warmRed)
            Spacer()
        }
        .padding(.horizontal)
    }

    private var filmGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 14) {
            ForEach(filteredFilms) { film in
                Button {
                    selectedFilm = film
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Color(PopcornTheme.sepiaBrown.opacity(0.1))
                            .frame(height: 200)
                            .overlay {
                                AsyncImage(url: URL(string: film.posterURL)) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "film")
                                                .font(.title2)
                                            Text(film.title)
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                    }
                                }
                                .allowsHitTesting(false)
                            }
                            .clipShape(.rect(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                if film.isTV {
                                    Text("TV")
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(PopcornTheme.freshGreen, in: .capsule)
                                        .padding(6)
                                }
                            }

                        Text(film.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PopcornTheme.darkBrown)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text("\(film.year) · \(film.genre.first ?? "")")
                                .font(.caption)
                                .foregroundStyle(PopcornTheme.subtleGray)
                            Spacer()
                            if film.averageRating > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "popcorn.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(PopcornTheme.popcornYellow)
                                    Text(String(format: "%.1f", film.averageRating))
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "newspaper.fill")
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                Text("Film Articles")
                    .font(.title3.bold())
                    .foregroundStyle(PopcornTheme.darkBrown)
            }
            .padding(.horizontal)
            .padding(.top, 8)

            ForEach(MockDataService.articles) { article in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(PopcornTheme.sepiaBrown.opacity(0.15))
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "doc.text")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(article.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(PopcornTheme.darkBrown)
                            .lineLimit(2)
                        HStack {
                            Text(article.source)
                            Text("·")
                            Text(article.timeAgo)
                        }
                        .font(.caption)
                        .foregroundStyle(PopcornTheme.subtleGray)
                    }

                    Spacer()
                }
                .padding(10)
                .background(Color.white, in: .rect(cornerRadius: 12))
                .padding(.horizontal)
            }
        }
    }
}

struct FilmDetailSheet: View {
    let film: Film
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLogSheet = false

    var buddyReviews: [LogEntry] {
        viewModel.buddyLogs.filter { $0.film.id == film.id }
    }

    var isOnWatchlist: Bool {
        viewModel.isInWatchlist(film)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        Color(PopcornTheme.sepiaBrown.opacity(0.15))
                            .frame(height: 360)
                            .overlay {
                                AsyncImage(url: URL(string: film.posterURL)) { phase in
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
                        .frame(height: 360)
                        .allowsHitTesting(false)
                    }

                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text(film.title)
                                .font(.title2.bold())
                                .foregroundStyle(PopcornTheme.darkBrown)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 8) {
                                Text(film.year)
                                if !film.runtime.isEmpty {
                                    Text("·")
                                    Text(film.runtime)
                                }
                                Text("·")
                                Text(film.director)
                            }
                            .font(.subheadline)
                            .foregroundStyle(PopcornTheme.sepiaBrown)

                            if film.averageRating > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "popcorn.fill")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.popcornYellow)
                                    Text(String(format: "%.1f", film.averageRating))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                    Text("avg from Popcorn users")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.subtleGray)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, -16)

                        ScrollView(.horizontal) {
                            HStack(spacing: 6) {
                                ForEach(film.genre, id: \.self) { genre in
                                    Text(genre)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(PopcornTheme.popcornYellow.opacity(0.3), in: .capsule)
                                }
                            }
                        }
                        .contentMargins(.horizontal, 16)
                        .scrollIndicators(.hidden)

                        if !film.synopsis.isEmpty {
                            Text(film.synopsis)
                                .font(.body)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .padding(.horizontal)
                        }

                        VStack(spacing: 10) {
                            Button {
                                showLogSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "popcorn.fill")
                                    Text("Log This Film")
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 12))
                            }

                            Button {
                                if isOnWatchlist {
                                    viewModel.removeFromWatchlist(film)
                                } else {
                                    viewModel.addToWatchlist(film)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isOnWatchlist ? "bookmark.fill" : "bookmark")
                                    Text(isOnWatchlist ? "On Watchlist" : "Add to Watchlist")
                                        .fontWeight(.medium)
                                }
                                .foregroundStyle(isOnWatchlist ? .white : PopcornTheme.darkBrown)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    isOnWatchlist ? PopcornTheme.freshGreen : Color.white,
                                    in: .rect(cornerRadius: 12)
                                )
                                .overlay {
                                    if !isOnWatchlist {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                                    }
                                }
                            }
                            .sensoryFeedback(.impact(weight: .light), trigger: isOnWatchlist)
                        }
                        .padding(.horizontal)

                        if !buddyReviews.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Buddy Reviews")
                                    .font(.headline)
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                    .padding(.horizontal)

                                ForEach(buddyReviews) { entry in
                                    NavigationLink(value: entry) {
                                        HStack(alignment: .top, spacing: 10) {
                                            AvatarView(name: "avatar_2", size: 32)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(entry.username)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundStyle(PopcornTheme.darkBrown)
                                                PopcornRatingDisplay(rating: entry.rating, isGoldenPopcorn: entry.isGoldenPopcorn)
                                                if !entry.review.isEmpty {
                                                    Text(entry.review)
                                                        .font(.caption)
                                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                                }
                                            }
                                        }
                                        .padding(10)
                                        .background(Color.white, in: .rect(cornerRadius: 10))
                                        .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .navigationDestination(for: LogEntry.self) { entry in
            ReviewDetailView(entry: entry)
        }
        .sheet(isPresented: $showLogSheet) {
            LogFilmView(preselectedFilm: film)
        }
    }
}
