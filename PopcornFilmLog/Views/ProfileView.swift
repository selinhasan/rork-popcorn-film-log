import SwiftUI

struct ProfileView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showEditTopFive = false
    @State private var showSettings = false
    @State private var showCreateList = false
    @State private var showRandomPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    topFiveSection
                    watchlistSection
                    listsSection
                    statsSection
                }
                .padding(.bottom, 32)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                }
            }
            .sheet(isPresented: $showEditTopFive) {
                EditTopFiveSheet()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCreateList) {
                CreateListSheet()
            }
            .sheet(isPresented: $showRandomPicker) {
                RandomFilmPickerView()
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            AvatarView(
                name: viewModel.currentUser?.profileImageName ?? "avatar_1",
                size: 90,
                customURL: viewModel.currentUser?.customProfileImageURL
            )
            .shadow(color: PopcornTheme.sepiaBrown.opacity(0.2), radius: 10, y: 4)

            Text(viewModel.currentUser?.username ?? "User")
                .font(.title2.bold())
                .foregroundStyle(PopcornTheme.darkBrown)

            if let bio = viewModel.currentUser?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.subheadline)
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Text("Joined \(viewModel.currentUser?.joinDate.formatted(date: .abbreviated, time: .omitted) ?? "")")
                .font(.caption)
                .foregroundStyle(PopcornTheme.subtleGray)
        }
        .padding(.top, 8)
    }

    private var topFiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top 5 Films")
                    .font(.headline)
                    .foregroundStyle(PopcornTheme.darkBrown)
                Spacer()
                Button("Edit") { showEditTopFive = true }
                    .font(.subheadline)
                    .foregroundStyle(PopcornTheme.warmRed)
            }
            .padding(.horizontal)

            let topFive = viewModel.currentUser?.topFiveFilms ?? []
            let goldenId = viewModel.currentUser?.goldenPopcornFilmId

            if topFive.isEmpty {
                Button {
                    showEditTopFive = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(PopcornTheme.warmRed)
                        Text("Set your top 5 films")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white, in: .rect(cornerRadius: 12))
                }
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        if let gId = goldenId, let goldenFilm = viewModel.diaryEntries.first(where: { $0.film.id == gId })?.film,
                           !topFive.contains(where: { $0.id == gId }) {
                            filmCard(goldenFilm, index: nil, isGolden: true)
                        }

                        ForEach(Array(topFive.enumerated()), id: \.element.id) { index, film in
                            filmCard(film, index: index + 1, isGolden: film.id == goldenId)
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
    }

    private func filmCard(_ film: Film, index: Int?, isGolden: Bool) -> some View {
        VStack(spacing: 6) {
            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                .frame(width: 80, height: 115)
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
                .clipShape(.rect(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if isGolden {
                        GoldenPopcornView(size: 14)
                            .padding(4)
                    } else if let idx = index {
                        Text("#\(idx)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 4))
                            .padding(4)
                    }
                }

            Text(film.title)
                .font(.caption2)
                .foregroundStyle(PopcornTheme.darkBrown)
                .lineLimit(1)
                .frame(width: 80)
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Watchlist")
                    .font(.headline)
                    .foregroundStyle(PopcornTheme.darkBrown)
                Spacer()

                if !(viewModel.currentUser?.watchlist.isEmpty ?? true) {
                    Button {
                        showRandomPicker = true
                    } label: {
                        Image(systemName: "dice.fill")
                            .foregroundStyle(PopcornTheme.warmRed)
                    }
                }
            }
            .padding(.horizontal)

            let watchlist = viewModel.currentUser?.watchlist ?? []
            if watchlist.isEmpty {
                HStack {
                    Image(systemName: "bookmark")
                        .foregroundStyle(PopcornTheme.subtleGray)
                    Text("Your watchlist is empty")
                        .foregroundStyle(PopcornTheme.subtleGray)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white, in: .rect(cornerRadius: 12))
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(watchlist) { film in
                            VStack(spacing: 6) {
                                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                    .frame(width: 70, height: 100)
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
                                    .clipShape(.rect(cornerRadius: 8))

                                Text(film.title)
                                    .font(.caption2)
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                    .lineLimit(1)
                                    .frame(width: 70)
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
    }

    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lists")
                    .font(.headline)
                    .foregroundStyle(PopcornTheme.darkBrown)
                Spacer()
                Button {
                    showCreateList = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(PopcornTheme.warmRed)
                }
            }
            .padding(.horizontal)

            if viewModel.filmLists.isEmpty {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .foregroundStyle(PopcornTheme.subtleGray)
                    Text("No lists yet")
                        .foregroundStyle(PopcornTheme.subtleGray)
                }
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white, in: .rect(cornerRadius: 12))
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.filmLists) { list in
                            NavigationLink(value: list.id) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                        .frame(width: 130, height: 80)
                                        .overlay {
                                            if let url = list.coverPosterURL {
                                                AsyncImage(url: URL(string: url)) { phase in
                                                    if let image = phase.image {
                                                        image.resizable().aspectRatio(contentMode: .fill)
                                                    }
                                                }
                                                .allowsHitTesting(false)
                                            } else {
                                                Image(systemName: "list.bullet")
                                                    .font(.title2)
                                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                                            }
                                        }
                                        .clipShape(.rect(cornerRadius: 10))

                                    Text(list.name)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                        .lineLimit(1)

                                    HStack(spacing: 4) {
                                        Text("\(list.films.count) films")
                                            .font(.caption2)
                                            .foregroundStyle(PopcornTheme.subtleGray)
                                        if !list.isPublic {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 8))
                                                .foregroundStyle(PopcornTheme.subtleGray)
                                        }
                                    }
                                }
                                .frame(width: 130)
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
            }
        }
        .navigationDestination(for: String.self) { listId in
            if let list = viewModel.filmLists.first(where: { $0.id == listId }) {
                ListDetailView(list: list)
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(value: "\(viewModel.diaryEntries.count)", label: "Films Logged", icon: "film.fill")
            statCard(value: "\(viewModel.buddies.count)", label: "Buddies", icon: "person.2.fill")
            let avg = viewModel.diaryEntries.isEmpty ? 0.0 : viewModel.diaryEntries.map(\.rating).reduce(0, +) / Double(viewModel.diaryEntries.count)
            statCard(value: String(format: "%.1f", avg), label: "Avg Rating", icon: "popcorn.fill")
        }
        .padding(.horizontal)
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(PopcornTheme.popcornYellow)
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(PopcornTheme.darkBrown)
            Text(label)
                .font(.caption)
                .foregroundStyle(PopcornTheme.sepiaBrown)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }
}
