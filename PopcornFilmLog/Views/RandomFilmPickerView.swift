import SwiftUI

struct RandomFilmPickerView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var source: FilmSource = .watchlist
    @State private var selectedGenre: String?
    @State private var selectedDirector = ""
    @State private var selectedYear = ""
    @State private var selectedBuddyId: String?
    @State private var pickedFilm: Film?
    @State private var isSpinning = false

    enum FilmSource: String, CaseIterable {
        case watchlist = "My Watchlist"
        case allFilms = "All Films"
        case withBuddy = "With a Buddy"
    }

    private var filmPool: [Film] {
        var films: [Film]

        switch source {
        case .watchlist:
            films = viewModel.currentUser?.watchlist ?? []
        case .allFilms:
            films = MockDataService.allContent
        case .withBuddy:
            var merged = viewModel.currentUser?.watchlist ?? []
            if let buddyId = selectedBuddyId,
               let buddy = viewModel.buddies.first(where: { $0.id == buddyId }) {
                for film in buddy.watchlist where !merged.contains(where: { $0.id == film.id }) {
                    merged.append(film)
                }
            }
            films = merged
        }

        if let genre = selectedGenre {
            films = films.filter { $0.genre.contains(genre) }
        }
        if !selectedDirector.isEmpty {
            films = films.filter { $0.director.localizedCaseInsensitiveContains(selectedDirector) }
        }
        if !selectedYear.isEmpty {
            films = films.filter { $0.year == selectedYear }
        }

        return films
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "dice.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(PopcornTheme.warmRed)
                        .rotationEffect(.degrees(isSpinning ? 360 : 0))
                        .padding(.top, 16)

                    Text("Random Film Picker")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(PopcornTheme.darkBrown)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Pick from")
                            .font(.headline)
                            .foregroundStyle(PopcornTheme.darkBrown)

                        Picker("Source", selection: $source) {
                            ForEach(FilmSource.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)

                        if source == .withBuddy {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose a buddy")
                                    .font(.subheadline)
                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                                ScrollView(.horizontal) {
                                    HStack(spacing: 10) {
                                        ForEach(viewModel.buddies) { buddy in
                                            Button {
                                                selectedBuddyId = buddy.id
                                            } label: {
                                                VStack(spacing: 4) {
                                                    AvatarView(name: buddy.profileImageName, size: 44)
                                                        .overlay {
                                                            if selectedBuddyId == buddy.id {
                                                                Circle().stroke(PopcornTheme.warmRed, lineWidth: 2)
                                                            }
                                                        }
                                                    Text(buddy.username)
                                                        .font(.caption2)
                                                        .foregroundStyle(PopcornTheme.darkBrown)
                                                }
                                            }
                                        }
                                    }
                                }
                                .scrollIndicators(.hidden)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filters (optional)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PopcornTheme.sepiaBrown)

                            ScrollView(.horizontal) {
                                HStack(spacing: 6) {
                                    filterChip(nil, label: "Any Genre", selected: selectedGenre == nil) {
                                        selectedGenre = nil
                                    }
                                    ForEach(MockDataService.genres, id: \.self) { genre in
                                        filterChip(genre, label: genre, selected: selectedGenre == genre) {
                                            selectedGenre = genre
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)

                            TextField("Director (optional)", text: $selectedDirector)
                                .padding(10)
                                .background(Color.white, in: .rect(cornerRadius: 8))

                            TextField("Year (optional)", text: $selectedYear)
                                .keyboardType(.numberPad)
                                .padding(10)
                                .background(Color.white, in: .rect(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal)

                    Text("\(filmPool.count) films available")
                        .font(.caption)
                        .foregroundStyle(PopcornTheme.subtleGray)

                    Button {
                        pickRandom()
                    } label: {
                        HStack {
                            Image(systemName: "dice.fill")
                            Text("Pick a Film!")
                                .fontWeight(.semibold)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            filmPool.isEmpty ? PopcornTheme.subtleGray : PopcornTheme.warmRed,
                            in: .rect(cornerRadius: 14)
                        )
                    }
                    .disabled(filmPool.isEmpty)
                    .padding(.horizontal)

                    if let film = pickedFilm {
                        VStack(spacing: 12) {
                            Text("Your pick:")
                                .font(.headline)
                                .foregroundStyle(PopcornTheme.darkBrown)

                            HStack(spacing: 14) {
                                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                    .frame(width: 70, height: 100)
                                    .overlay {
                                        AsyncImage(url: URL(string: film.posterURL)) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            }
                                        }
                                        .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(film.title)
                                        .font(.title3.bold())
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                    Text("\(film.year) · \(film.director)")
                                        .font(.subheadline)
                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                    if !film.genre.isEmpty {
                                        Text(film.genre.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundStyle(PopcornTheme.subtleGray)
                                    }
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(PopcornTheme.popcornYellow.opacity(0.15), in: .rect(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer().frame(height: 20)
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
    }

    private func filterChip(_ value: String?, label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(selected ? .white : PopcornTheme.darkBrown)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(selected ? PopcornTheme.warmRed : Color.white, in: .capsule)
                .overlay {
                    if !selected {
                        Capsule().stroke(PopcornTheme.sepiaBrown.opacity(0.2), lineWidth: 1)
                    }
                }
        }
    }

    private func pickRandom() {
        guard !filmPool.isEmpty else { return }
        withAnimation(.spring(duration: 0.5)) {
            isSpinning = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(duration: 0.4)) {
                pickedFilm = filmPool.randomElement()
                isSpinning = false
            }
        }
    }
}
