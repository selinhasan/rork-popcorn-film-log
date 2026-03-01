import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showEditProfile = false
    @State private var showEditTopFive = false
    @State private var showImportSheet = false
    @State private var showLogoutAlert = false
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    topFiveSection
                    statsSection
                    settingsSection
                }
                .padding(.bottom, 32)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit", systemImage: "pencil") {
                        showEditProfile = true
                    }
                    .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet()
            }
            .sheet(isPresented: $showEditTopFive) {
                EditTopFiveSheet()
            }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Log Out", role: .destructive) { viewModel.logOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Import", isPresented: $showImportSheet) {
                Button("OK") {}
            } message: {
                Text("CSV import will be available when connected to a file source.")
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            AvatarView(name: viewModel.currentUser?.profileImageName ?? "avatar_1", size: 90)
                .shadow(color: PopcornTheme.sepiaBrown.opacity(0.2), radius: 10, y: 4)

            Text(viewModel.currentUser?.username ?? "User")
                .font(.title2.bold())
                .foregroundStyle(PopcornTheme.darkBrown)

            Text(viewModel.currentUser?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.sepiaBrown)

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
                        ForEach(Array(topFive.enumerated()), id: \.element.id) { index, film in
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
                                        Text("#\(index + 1)")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 4))
                                            .padding(4)
                                    }

                                Text(film.title)
                                    .font(.caption2)
                                    .foregroundStyle(PopcornTheme.darkBrown)
                                    .lineLimit(1)
                                    .frame(width: 80)
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 16)
                .scrollIndicators(.hidden)
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

    private var settingsSection: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.headline)
                .foregroundStyle(PopcornTheme.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)

            VStack(spacing: 1) {
                settingsToggle(icon: "bell.fill", title: "Notifications", isOn: $notificationsEnabled)
                settingsToggle(icon: "speaker.wave.2.fill", title: "Sound", isOn: $soundEnabled)

                Button {
                    showImportSheet = true
                } label: {
                    settingsRow(icon: "square.and.arrow.down.fill", title: "Import Watch History", showChevron: true)
                }

                Button {
                    showEditProfile = true
                } label: {
                    settingsRow(icon: "person.crop.circle", title: "Edit Profile", showChevron: true)
                }

                Button {
                    showLogoutAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.body)
                            .foregroundStyle(PopcornTheme.warmRed)
                            .frame(width: 28)
                        Text("Log Out")
                            .font(.body)
                            .foregroundStyle(PopcornTheme.warmRed)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                }
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
    @State private var selectedAvatar = "avatar_1"
    @State private var password = ""
    @State private var newPassword = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Avatar") {
                    HStack {
                        Spacer()
                        AvatarView(name: selectedAvatar, size: 80)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(MockDataService.defaultAvatars, id: \.self) { avatar in
                            Button {
                                selectedAvatar = avatar
                            } label: {
                                AvatarView(name: avatar, size: 44)
                                    .overlay {
                                        if selectedAvatar == avatar {
                                            Circle().stroke(PopcornTheme.warmRed, lineWidth: 2)
                                        }
                                    }
                            }
                        }
                    }
                }

                Section("Profile") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                }

                Section("Change Password") {
                    SecureField("Current Password", text: $password)
                    SecureField("New Password", text: $newPassword)
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
                        if !username.isEmpty {
                            viewModel.updateProfile(username: username, profileImage: selectedAvatar)
                        } else {
                            viewModel.updateProfile(profileImage: selectedAvatar)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                username = viewModel.currentUser?.username ?? ""
                selectedAvatar = viewModel.currentUser?.profileImageName ?? "avatar_1"
            }
        }
    }
}

struct EditTopFiveSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var topFive: [Film] = []

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
                        ForEach(availableFilms) { film in
                            Button {
                                withAnimation {
                                    topFive.append(film)
                                }
                            } label: {
                                HStack {
                                    Text(film.title)
                                        .foregroundStyle(PopcornTheme.darkBrown)
                                    Text(film.year)
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.subtleGray)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(PopcornTheme.freshGreen)
                                }
                            }
                        }
                    }
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
        MockDataService.popularFilms.filter { film in
            !topFive.contains { $0.id == film.id }
        }
    }
}
