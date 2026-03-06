import SwiftUI

struct BrowseView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var selectedGenre: TMDbGenre? = nil
    @State private var sortOption: SortOption = .popular
    @State private var selectedFilm: Film?
    @State private var displayedFilms: [Film] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?

    enum SortOption: String, CaseIterable {
        case popular = "Popular"
        case topRated = "Top Rated"
        case newest = "Newest"
        case trending = "Trending"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    genreChips
                    sortPicker

                    if isLoading || viewModel.isSearching {
                        ProgressView()
                            .tint(PopcornTheme.warmRed)
                            .padding(.top, 40)
                    } else if !searchText.isEmpty && viewModel.searchResults.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.4))
                            Text("No results for \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.subtleGray)
                        }
                        .padding(.top, 40)
                    } else {
                        filmGrid
                    }

                    tmdbAttribution
                }
                .padding(.bottom, 20)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Browse")
            .searchable(text: $searchText, prompt: "Search films & shows")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    await viewModel.searchFilms(query: newValue)
                }
            }
            .onChange(of: selectedGenre) { _, _ in
                Task { await loadFilmsForFilter() }
            }
            .onChange(of: sortOption) { _, _ in
                Task { await loadFilmsForFilter() }
            }
            .sheet(item: $selectedFilm) { film in
                FilmDetailSheet(film: film)
            }
            .task {
                if displayedFilms.isEmpty {
                    await loadFilmsForFilter()
                }
            }
        }
    }

    private func loadFilmsForFilter() async {
        guard searchText.isEmpty else { return }
        isLoading = true

        let sortBy: String
        switch sortOption {
        case .popular: sortBy = "popularity.desc"
        case .topRated: sortBy = "vote_average.desc"
        case .newest: sortBy = "primary_release_date.desc"
        case .trending: sortBy = "popularity.desc"
        }

        if sortOption == .trending {
            if let genre = selectedGenre {
                displayedFilms = viewModel.trendingFilms.filter { $0.genre.contains(genre.name) }
            } else {
                displayedFilms = viewModel.trendingFilms
            }
        } else {
            let films = await viewModel.discoverFilms(genreId: selectedGenre?.id, sortBy: sortBy)
            displayedFilms = films
        }

        if displayedFilms.isEmpty {
            displayedFilms = viewModel.popularFilms
        }
        isLoading = false
    }

    private var filmsToShow: [Film] {
        if !searchText.isEmpty {
            return viewModel.searchResults
        }
        return displayedFilms
    }

    private var genreChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(duration: 0.25)) {
                        selectedGenre = nil
                    }
                } label: {
                    Text("All")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selectedGenre == nil ? .white : PopcornTheme.darkBrown)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            selectedGenre == nil ? PopcornTheme.warmRed : Color.white,
                            in: .capsule
                        )
                        .overlay {
                            if selectedGenre != nil {
                                Capsule()
                                    .stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                            }
                        }
                }

                ForEach(viewModel.tmdbGenres) { genre in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            selectedGenre = genre
                        }
                    } label: {
                        Text(genre.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(selectedGenre?.id == genre.id ? .white : PopcornTheme.darkBrown)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                selectedGenre?.id == genre.id ? PopcornTheme.warmRed : Color.white,
                                in: .capsule
                            )
                            .overlay {
                                if selectedGenre?.id != genre.id {
                                    Capsule()
                                        .stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                                }
                            }
                    }
                }
            }
        }
        .contentMargins(.horizontal, 16)
        .scrollIndicators(.hidden)
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
            ForEach(filmsToShow) { film in
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
                                    } else if phase.error != nil {
                                        VStack(spacing: 4) {
                                            Image(systemName: "film")
                                                .font(.title2)
                                            Text(film.title)
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                    } else {
                                        ProgressView()
                                            .tint(PopcornTheme.sepiaBrown)
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

    private var tmdbAttribution: some View {
        Text("This product uses the TMDb API but is not endorsed or certified by TMDb.")
            .font(.caption2)
            .foregroundStyle(PopcornTheme.subtleGray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 8)
    }
}

struct FilmDetailSheet: View {
    let film: Film
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showLogSheet = false
    @State private var detailedFilm: Film?
    @State private var isLoadingDetail = false

    private var displayFilm: Film {
        detailedFilm ?? film
    }

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
                                AsyncImage(url: URL(string: displayFilm.posterURL)) { phase in
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
                            Text(displayFilm.title)
                                .font(.title2.bold())
                                .foregroundStyle(PopcornTheme.darkBrown)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 8) {
                                Text(displayFilm.year)
                                if !displayFilm.runtime.isEmpty {
                                    Text("·")
                                    Text(displayFilm.runtime)
                                }
                                if !displayFilm.director.isEmpty {
                                    Text("·")
                                    Text(displayFilm.director)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(PopcornTheme.sepiaBrown)

                            if displayFilm.averageRating > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "popcorn.fill")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.popcornYellow)
                                    Text(String(format: "%.1f", displayFilm.averageRating))
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

                        if !displayFilm.genre.isEmpty {
                            ScrollView(.horizontal) {
                                HStack(spacing: 6) {
                                    ForEach(displayFilm.genre, id: \.self) { genre in
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
                        }

                        if !displayFilm.synopsis.isEmpty {
                            Text(displayFilm.synopsis)
                                .font(.body)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .padding(.horizontal)
                        }

                        if !displayFilm.cast.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cast")
                                    .font(.headline)
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                Text(displayFilm.cast.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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
                                    viewModel.removeFromWatchlist(displayFilm)
                                } else {
                                    viewModel.addToWatchlist(displayFilm)
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
            LogFilmView(preselectedFilm: displayFilm)
        }
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        guard let id = Int(film.id) else { return }
        isLoadingDetail = true
        if let detail = await viewModel.fetchFilmDetail(filmId: film.id) {
            detailedFilm = detail
        }
        isLoadingDetail = false
    }
}
