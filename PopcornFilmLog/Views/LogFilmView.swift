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
    @State private var isGoldenPopcorn = false
    @State private var showGoldenConfirm = false
    @State private var selectedListId: String?
    @State private var watchDate: Date = Date()
    @FocusState private var searchFocused: Bool

    var preselectedFilm: Film? = nil

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
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if let film = preselectedFilm {
                selectedFilm = film
                showTVField = film.isTV
            }
        }
        .alert("Golden Popcorn", isPresented: $showGoldenConfirm) {
            Button("Give Golden Popcorn", role: .destructive) {
                isGoldenPopcorn = true
                rating = 5.0
            }
            Button("Cancel", role: .cancel) {
                isGoldenPopcorn = false
            }
        } message: {
            if let currentGolden = viewModel.currentUser?.goldenPopcornFilmId,
               let film = viewModel.diaryEntries.first(where: { $0.film.id == currentGolden })?.film {
                Text("This will remove the Golden Popcorn from \(film.title) and reduce it to 5 popcorns. Are you sure?")
            } else {
                Text("You can only give the Golden Popcorn to one film ever. Are you sure?")
            }
        }
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
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        Color(PopcornTheme.sepiaBrown.opacity(0.15))
                            .frame(height: 320)
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
                            .clipped()

                        LinearGradient(
                            colors: [.clear, .clear, PopcornTheme.cream.opacity(0.5), PopcornTheme.cream],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 320)
                        .allowsHitTesting(false)
                    }

                    VStack(spacing: 16) {
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

                            if film.averageRating > 0 {
                                HStack(spacing: 6) {
                                    Image(systemName: "popcorn.fill")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.popcornYellow)
                                    Text(String(format: "%.1f", film.averageRating))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                    Text("avg from Popcorn users")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.subtleGray)
                                }
                                .padding(.top, 2)
                            }
                        }
                        .padding(.horizontal)

                        if !film.synopsis.isEmpty {
                            Text(film.synopsis)
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.8))
                                .padding(.horizontal, 20)
                                .multilineTextAlignment(.center)
                        }

                        VStack(spacing: 12) {
                            Text("Your Rating")
                                .font(.headline)
                                .foregroundStyle(PopcornTheme.darkBrown)

                            PopcornRatingView(rating: $rating, interactive: !isGoldenPopcorn)

                            Text(ratingLabel)
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.sepiaBrown)

                            Button {
                                if isGoldenPopcorn {
                                    isGoldenPopcorn = false
                                } else if viewModel.currentUser?.goldenPopcornFilmId != nil {
                                    showGoldenConfirm = true
                                } else {
                                    isGoldenPopcorn = true
                                    rating = 5.0
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    GoldenPopcornView(size: 20)
                                    Text(isGoldenPopcorn ? "Golden Popcorn!" : "Award Golden Popcorn")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(isGoldenPopcorn ? Color(red: 0.85, green: 0.65, blue: 0.13) : PopcornTheme.sepiaBrown)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    isGoldenPopcorn
                                        ? Color(red: 1.0, green: 0.95, blue: 0.8)
                                        : Color.white,
                                    in: .capsule
                                )
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            isGoldenPopcorn
                                                ? Color(red: 0.85, green: 0.65, blue: 0.13).opacity(0.5)
                                                : PopcornTheme.sepiaBrown.opacity(0.2),
                                            lineWidth: 1
                                        )
                                }
                            }


                        }
                        .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date Watched")
                                .font(.headline)
                                .foregroundStyle(PopcornTheme.darkBrown)
                            DatePicker("Date", selection: $watchDate, in: ...Date(), displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .tint(PopcornTheme.warmRed)
                        }
                        .padding(.horizontal)

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

                        if !viewModel.filmLists.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Add to List")
                                    .font(.headline)
                                    .foregroundStyle(PopcornTheme.darkBrown)

                                ScrollView(.horizontal) {
                                    HStack(spacing: 8) {
                                        ForEach(viewModel.filmLists) { list in
                                            Button {
                                                selectedListId = selectedListId == list.id ? nil : list.id
                                            } label: {
                                                Text(list.name)
                                                    .font(.subheadline.weight(.medium))
                                                    .foregroundStyle(selectedListId == list.id ? .white : PopcornTheme.darkBrown)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        selectedListId == list.id ? PopcornTheme.warmRed : Color.white,
                                                        in: .capsule
                                                    )
                                                    .overlay {
                                                        if selectedListId != list.id {
                                                            Capsule()
                                                                .stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                                                        }
                                                    }
                                            }
                                        }
                                    }
                                }
                                .contentMargins(.horizontal, 0)
                                .scrollIndicators(.hidden)
                            }
                            .padding(.horizontal)
                        }

                        Spacer().frame(height: 80)
                    }
                    .padding(.top, -20)
                }
            }
            .scrollDismissesKeyboard(.interactively)

            Button {
                saveLog()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "popcorn.fill")
                    Text("Log")
                        .fontWeight(.bold)
                }
                .font(.title3)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [PopcornTheme.warmRed, Color(red: 0.72, green: 0.2, blue: 0.18)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: .rect(cornerRadius: 14)
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            .background(PopcornTheme.cream)
        }
    }

    private var ratingLabel: String {
        if isGoldenPopcorn { return "Golden Popcorn — your all-time favourite!" }
        if rating == 0 { return "Tap to rate" }
        if rating <= 1 { return "Not great" }
        if rating <= 2 { return "Below average" }
        if rating <= 3 { return "Good" }
        if rating <= 4 { return "Great" }
        return "Masterpiece!"
    }

    private func saveLog() {
        guard let film = selectedFilm else { return }
        let effectiveRating = isGoldenPopcorn ? 5.0 : rating
        viewModel.logFilm(film, rating: effectiveRating, review: review, episodeInfo: showTVField ? episodeInfo : nil, isGoldenPopcorn: isGoldenPopcorn, listId: selectedListId, watchDate: watchDate)
        dismiss()
    }
}
