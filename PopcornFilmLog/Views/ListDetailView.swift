import SwiftUI

struct ListDetailView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var list: FilmList
    @State private var showEditList = false
    @State private var showAddFilms = false
    @State private var showDeleteAlert = false
    @State private var selectedFilm: Film?
    @State private var showShareSheet = false

    init(list: FilmList) {
        self._list = State(initialValue: list)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerSection

                if !list.description.isEmpty {
                    Text(list.description)
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                }

                HStack {
                    Text("\(list.films.count) films")
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.subtleGray)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: list.isPublic ? "globe" : "lock.fill")
                            .font(.caption)
                        Text(list.isPublic ? "Public" : "Private")
                            .font(.caption)
                    }
                    .foregroundStyle(PopcornTheme.subtleGray)
                }
                .padding(.horizontal)

                if list.films.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "film.stack")
                            .font(.system(size: 40))
                            .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.3))
                        Text("No films in this list yet")
                            .font(.subheadline)
                            .foregroundStyle(PopcornTheme.subtleGray)
                        Button {
                            showAddFilms = true
                        } label: {
                            Label("Add Films", systemImage: "plus")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(PopcornTheme.warmRed, in: .capsule)
                        }
                    }
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 8) {
                        ForEach(list.films) { film in
                            Button {
                                selectedFilm = film
                            } label: {
                                filmRow(film)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 20)
        }
        .background(PopcornTheme.cream.ignoresSafeArea())
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    ShareLink(item: viewModel.shareableListText(for: list)) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                    Menu {
                        Button { showAddFilms = true } label: {
                            Label("Add Films", systemImage: "plus")
                        }
                        Button { showEditList = true } label: {
                            Label("Edit List", systemImage: "pencil")
                        }
                        Button(role: .destructive) { showDeleteAlert = true } label: {
                            Label("Delete List", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddFilms) {
            AddFilmsToListSheet(list: $list)
        }
        .sheet(isPresented: $showEditList) {
            EditListSheet(list: $list)
        }
        .sheet(item: $selectedFilm) { film in
            FilmDetailSheet(film: film)
        }
        .alert("Delete List", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteList(list)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(list.name)'?")
        }
        .onChange(of: list) { _, newValue in
            viewModel.updateList(newValue)
        }
    }

    private var headerSection: some View {
        Color(PopcornTheme.sepiaBrown.opacity(0.15))
            .frame(height: 160)
            .overlay {
                if let url = list.coverPosterURL {
                    AsyncImage(url: URL(string: url)) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .allowsHitTesting(false)
                } else {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 40))
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }
            .clipShape(.rect(cornerRadius: 16))
            .overlay {
                LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .center, endPoint: .bottom)
                    .clipShape(.rect(cornerRadius: 16))
            }
            .overlay(alignment: .bottomLeading) {
                Text(list.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(16)
            }
            .padding(.horizontal)
    }

    private func filmRow(_ film: Film) -> some View {
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
                Text(film.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PopcornTheme.darkBrown)
                    .lineLimit(1)
                Text("\(film.year) · \(film.director)")
                    .font(.caption)
                    .foregroundStyle(PopcornTheme.sepiaBrown)
            }
            Spacer()

            Button {
                withAnimation {
                    list.films.removeAll { $0.id == film.id }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(PopcornTheme.warmRed.opacity(0.6))
            }
        }
        .padding(10)
        .background(Color.white, in: .rect(cornerRadius: 12))
    }
}

struct AddFilmsToListSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var list: FilmList
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    private var availableFilms: [Film] {
        if !searchText.isEmpty {
            return viewModel.searchResults.filter { film in
                !list.films.contains { $0.id == film.id }
            }
        }
        let logged = viewModel.diaryEntries.map(\.film)
        let trending = viewModel.trendingFilms
        var combined = logged + trending.filter { film in !logged.contains { $0.id == film.id } }
        combined = combined.filter { film in !list.films.contains { $0.id == film.id } }
        return Array(combined.prefix(20))
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.isSearching {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(PopcornTheme.warmRed)
                        Spacer()
                    }
                }
                ForEach(availableFilms) { film in
                    Button {
                        withAnimation {
                            list.films.append(film)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                .frame(width: 36, height: 50)
                                .overlay {
                                    AsyncImage(url: URL(string: film.posterURL)) { phase in
                                        if let image = phase.image {
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        }
                                    }
                                    .allowsHitTesting(false)
                                }
                                .clipShape(.rect(cornerRadius: 4))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(film.title)
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                Text(film.year)
                                    .font(.caption)
                                    .foregroundStyle(PopcornTheme.subtleGray)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(PopcornTheme.freshGreen)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search films")
            .onChange(of: searchText) { _, newValue in
                searchTask?.cancel()
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(400))
                    guard !Task.isCancelled else { return }
                    await viewModel.searchFilms(query: newValue)
                }
            }
            .navigationTitle("Add Films")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct EditListSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var list: FilmList
    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                Section {
                    Toggle("Public", isOn: $isPublic)
                        .tint(PopcornTheme.freshGreen)
                }

                if !list.films.isEmpty {
                    Section("Cover Image") {
                        ForEach(list.films) { film in
                            Button {
                                list.coverFilmId = film.id
                            } label: {
                                HStack(spacing: 10) {
                                    Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                        .frame(width: 36, height: 50)
                                        .overlay {
                                            AsyncImage(url: URL(string: film.posterURL)) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                }
                                            }
                                            .allowsHitTesting(false)
                                        }
                                        .clipShape(.rect(cornerRadius: 4))
                                    Text(film.title)
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                    Spacer()
                                    if list.coverFilmId == film.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(PopcornTheme.freshGreen)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        list.name = name
                        list.description = description
                        list.isPublic = isPublic
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                name = list.name
                description = list.description
                isPublic = list.isPublic
            }
        }
    }
}
