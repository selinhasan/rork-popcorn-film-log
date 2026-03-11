import SwiftUI
import PhotosUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false
    @State private var showImportSheet = false

    @State private var notificationsEnabled = true
    @State private var soundEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    settingsSection
                }
                .padding(.vertical, 16)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
            }

            .alert("Import", isPresented: $showImportSheet) {
                Button("OK") {}
            } message: {
                Text("Import will be available when connected to a file source.")
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 1) {
                Button {
                    showEditProfile = true
                } label: {
                    settingsRow(icon: "person.crop.circle", title: "Edit Profile", showChevron: true)
                }

                settingsToggle(icon: "bell.fill", title: "Notifications", isOn: $notificationsEnabled)
                settingsToggle(icon: "speaker.wave.2.fill", title: "Sound", isOn: $soundEnabled)

                Button {
                    showImportSheet = true
                } label: {
                    settingsRow(icon: "text.badge.star", title: "Import from Letterboxd", showChevron: true)
                }

                Button {
                    showImportSheet = true
                } label: {
                    settingsRow(icon: "doc.badge.arrow.up", title: "Import from Spreadsheet", showChevron: true)
                }
            }
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal)

            Spacer().frame(height: 24)

            Button {
                authViewModel.logout()
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.body)
                        .foregroundStyle(PopcornTheme.warmRed)
                        .frame(width: 28)
                    Text("Sign Out")
                        .font(.body)
                        .foregroundStyle(PopcornTheme.warmRed)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
            }
            .clipShape(.rect(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    private func settingsToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(PopcornTheme.darkBrown)
            Spacer()
            Toggle("", isOn: isOn)
                .tint(PopcornTheme.freshGreen)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func settingsRow(icon: String, title: String, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .frame(width: 28)
            Text(title)
                .font(.body)
                .foregroundStyle(PopcornTheme.darkBrown)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(PopcornTheme.subtleGray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
    }
}

struct EditProfileSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var bio = ""
    @State private var selectedAvatar = "avatar_1"
    @State private var customImageURL = ""

    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Avatar") {
                    HStack {
                        Spacer()
                        AvatarView(name: selectedAvatar, size: 80, customURL: customImageURL.isEmpty ? nil : customImageURL)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(MockDataService.defaultAvatars, id: \.self) { avatar in
                            Button {
                                selectedAvatar = avatar
                                customImageURL = ""
                            } label: {
                                AvatarView(name: avatar, size: 44)
                                    .overlay {
                                        if selectedAvatar == avatar && customImageURL.isEmpty {
                                            Circle().stroke(PopcornTheme.warmRed, lineWidth: 2)
                                        }
                                    }
                            }
                        }
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                            Text("Upload a photo")
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.darkBrown)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let item = newItem else { return }
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                viewModel.saveProfilePhoto(data)
                                customImageURL = "local://profile_photo"
                            }
                        }
                    }

                    TextField("Or paste a profile picture URL", text: $customImageURL)
                        .font(.caption)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section("Profile") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(2...4)
                }


            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateProfile(
                            username: username.isEmpty ? nil : username,
                            profileImage: selectedAvatar,
                            customImageURL: customImageURL.isEmpty ? nil : customImageURL,
                            bio: bio
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                username = viewModel.currentUser?.username ?? ""
                bio = viewModel.currentUser?.bio ?? ""
                selectedAvatar = viewModel.currentUser?.profileImageName ?? "avatar_1"
                customImageURL = viewModel.currentUser?.customProfileImageURL ?? ""
            }
        }
    }
}

struct EditTopFiveSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var topFive: [Film] = []
    @State private var searchText = ""
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                Section("Your Top 5") {
                    if topFive.isEmpty {
                        Text("No films selected yet")
                            .foregroundStyle(PopcornTheme.subtleGray)
                    } else {
                        ForEach(Array(topFive.enumerated()), id: \.element.id) { index, film in
                            HStack(spacing: 12) {
                                Text("#\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(PopcornTheme.warmRed)
                                    .frame(width: 30)

                                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                    .frame(width: 36, height: 50)
                                    .overlay {
                                        AsyncImage(url: URL(string: film.posterURL)) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Image(systemName: "film")
                                                    .font(.caption2)
                                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                                            }
                                        }
                                        .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 4))

                                Text(film.title)
                                    .font(.subheadline)
                                Spacer()
                                Button {
                                    topFive.removeAll { $0.id == film.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(PopcornTheme.warmRed)
                                }
                            }
                        }
                        .onMove { from, to in
                            topFive.move(fromOffsets: from, toOffset: to)
                        }
                    }
                }

                if topFive.count < 5 {
                    Section("Add Films") {
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
                                    topFive.append(film)
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Color(PopcornTheme.sepiaBrown.opacity(0.15))
                                        .frame(width: 36, height: 50)
                                        .overlay {
                                            AsyncImage(url: URL(string: film.posterURL)) { phase in
                                                if let image = phase.image {
                                                    image.resizable().aspectRatio(contentMode: .fill)
                                                } else {
                                                    Image(systemName: "film")
                                                        .font(.caption2)
                                                        .foregroundStyle(PopcornTheme.sepiaBrown)
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
            .navigationTitle("Top 5 Films")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateProfile(topFive: topFive)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                topFive = viewModel.currentUser?.topFiveFilms ?? []
            }
        }
    }

    private var availableFilms: [Film] {
        if !searchText.isEmpty {
            return viewModel.searchResults.filter { film in
                !topFive.contains { $0.id == film.id }
            }
        }

        let highestRated = viewModel.diaryEntries
            .sorted { $0.rating > $1.rating }
            .map(\.film)
            .filter { film in !topFive.contains { $0.id == film.id } }

        let trending = viewModel.trendingFilms.filter { film in
            !topFive.contains { $0.id == film.id } &&
            !highestRated.contains { $0.id == film.id }
        }

        let combined = highestRated + trending
        return Array(combined.prefix(15))
    }
}

struct CreateListSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var isPublic = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("List Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Toggle("Public", isOn: $isPublic)
                        .tint(PopcornTheme.freshGreen)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.createList(name: name, description: description, isPublic: isPublic)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
