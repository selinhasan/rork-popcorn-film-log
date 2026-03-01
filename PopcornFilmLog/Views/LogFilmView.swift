import SwiftUI

struct LogFilmView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilm: Film?
    @State private var rating: Double = 0
    @State private var review = ""
    @State private var episodeInfo = ""
    @State private var showTVField = false
    @FocusState private var searchFocused: Bool

    private var filteredFilms: [Film] {
        if searchText.isEmpty {
            return MockDataService.popularFilms
        }
        return MockDataService.allContent.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let film = selectedFilm {
                    filmDetailView(film)
                } else {
                    searchView
                }
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle(selectedFilm != nil ? "Log Film" : "Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
                if selectedFilm != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            saveLog()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(PopcornTheme.warmRed)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var searchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                TextField("Search films & TV shows...", text: $searchText)
                    .focused($searchFocused)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(PopcornTheme.subtleGray)
                    }
                }
            }
            .padding(12)
            .background(Color.white, in: .rect(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 8)

            if searchText.isEmpty {
                Text("Popular right now")
                    .font(.headline)
                    .foregroundStyle(PopcornTheme.darkBrown)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 20)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredFilms) { film in
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedFilm = film
                                showTVField = film.isTV
                            }
                        } label: {
                            filmSearchRow(film)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { searchFocused = true }
    }

    private func filmSearchRow(_ film: Film) -> some View {
        HStack(spacing: 12) {
            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                .frame(width: 50, height: 70)
                .overlay {
                    AsyncImage(url: URL(string: film.posterURL)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Image(systemName: "film")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                        }
                    }
                    .allowsHitTesting(false)
                }
                .clipShape(.rect(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(film.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PopcornTheme.darkBrown)
                        .lineLimit(1)
                    if film.isTV {
                        Text("TV")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(PopcornTheme.freshGreen, in: .capsule)
                    }
                }
                Text("\(film.year) · \(film.director)")
                    .font(.caption)
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                    .lineLimit(1)
                if !film.genre.isEmpty {
                    Text(film.genre.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundStyle(PopcornTheme.subtleGray)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(PopcornTheme.subtleGray)
        }
        .padding(10)
        .background(Color.white, in: .rect(cornerRadius: 12))
    }

    private func filmDetailView(_ film: Film) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                    .frame(height: 280)
                    .overlay {
                        AsyncImage(url: URL(string: film.posterURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                VStack {
                                    Image(systemName: "film")
                                        .font(.largeTitle)
                                    Text(film.title)
                                        .font(.headline)
                                }
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(.rect(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                    .padding(.horizontal)

                VStack(spacing: 6) {
                    Text(film.title)
                        .font(.title2.bold())
                        .foregroundStyle(PopcornTheme.darkBrown)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 8) {
                        Text(film.year)
                        Text("·")
                        Text(film.runtime)
                        Text("·")
                        Text(film.director)
                    }
                    .font(.subheadline)
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                }
                .padding(.horizontal)

                if !film.synopsis.isEmpty {
                    Text(film.synopsis)
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.8))
                        .padding(.horizontal, 20)
                        .multilineTextAlignment(.center)
                }

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

                VStack(spacing: 12) {
                    Text("Your Rating")
                        .font(.headline)
                        .foregroundStyle(PopcornTheme.darkBrown)

                    PopcornRatingView(rating: $rating)

                    Text(ratingLabel)
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
                .padding(.vertical, 8)

                if showTVField {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Episode")
                            .font(.headline)
                            .foregroundStyle(PopcornTheme.darkBrown)
                        TextField("e.g. S1E5", text: $episodeInfo)
                            .padding(12)
                            .background(Color.white, in: .rect(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Review")
                        .font(.headline)
                        .foregroundStyle(PopcornTheme.darkBrown)
                    TextField("Write your thoughts...", text: $review, axis: .vertical)
                        .lineLimit(4...8)
                        .padding(12)
                        .background(Color.white, in: .rect(cornerRadius: 10))
                }
                .padding(.horizontal)

                Spacer().frame(height: 20)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var ratingLabel: String {
        if rating == 0 { return "Tap to rate" }
        if rating <= 1 { return "Not great" }
        if rating <= 2 { return "Below average" }
        if rating <= 3 { return "Good" }
        if rating <= 4 { return "Great" }
        return "Masterpiece!"
    }

    private func saveLog() {
        guard let film = selectedFilm else { return }
        viewModel.logFilm(film, rating: rating, review: review, episodeInfo: showTVField ? episodeInfo : nil)
        dismiss()
    }
}
