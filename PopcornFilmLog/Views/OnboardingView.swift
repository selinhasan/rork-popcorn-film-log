import SwiftUI

struct OnboardingView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var currentStep = 0
    @State private var selectedAvatar = "avatar_1"
    @State private var topFiveFilms: [Film] = []
    @State private var showImportSheet = false

    var body: some View {
        VStack(spacing: 0) {
            progressBar

            TabView(selection: $currentStep) {
                welcomeStep.tag(0)
                avatarStep.tag(1)
                topFiveStep.tag(2)
                importStep.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.spring(duration: 0.4), value: currentStep)

            bottomButtons
        }
        .background(PopcornTheme.cream.ignoresSafeArea())
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? PopcornTheme.warmRed : PopcornTheme.sepiaBrown.opacity(0.2))
                    .frame(height: 4)
                    .animation(.spring(duration: 0.3), value: currentStep)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            PopcornLogoView(size: 120)
            Text("Welcome to Popcorn!")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(PopcornTheme.darkBrown)
            Text("Let's set up your profile so you can start logging films and connecting with buddies.")
                .font(.body)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var avatarStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Choose your avatar")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(PopcornTheme.darkBrown)

            AvatarView(name: selectedAvatar, size: 100)
                .animation(.spring(duration: 0.3), value: selectedAvatar)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 5), spacing: 12) {
                ForEach(MockDataService.defaultAvatars, id: \.self) { avatar in
                    Button {
                        selectedAvatar = avatar
                    } label: {
                        AvatarView(name: avatar, size: 52)
                            .overlay {
                                if selectedAvatar == avatar {
                                    Circle()
                                        .stroke(PopcornTheme.warmRed, lineWidth: 3)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var topFiveStep: some View {
        VStack(spacing: 16) {
            Text("Set your Top 5 Films")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(PopcornTheme.darkBrown)
                .padding(.top, 24)

            Text("These will appear on your profile. You can change them anytime.")
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        if index < topFiveFilms.count {
                            selectedFilmRow(topFiveFilms[index], index: index)
                        } else {
                            emptySlotRow(index: index + 1)
                        }
                    }
                }
                .padding(.horizontal)

                if topFiveFilms.count < 5 {
                    VStack(spacing: 8) {
                        Text("Quick picks")
                            .font(.headline)
                            .foregroundStyle(PopcornTheme.darkBrown)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 12)

                        ForEach(suggestedFilms) { film in
                            Button {
                                withAnimation(.spring(duration: 0.3)) {
                                    if topFiveFilms.count < 5 {
                                        topFiveFilms.append(film)
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    filmPosterSmall(film.posterURL)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(film.title)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(PopcornTheme.darkBrown)
                                        Text(film.year)
                                            .font(.caption)
                                            .foregroundStyle(PopcornTheme.sepiaBrown)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(PopcornTheme.freshGreen)
                                        .font(.title3)
                                }
                                .padding(10)
                                .background(Color.white, in: .rect(cornerRadius: 10))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }

    private var importStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 56))
                .foregroundStyle(PopcornTheme.sepiaBrown)

            Text("Import your watch history")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(PopcornTheme.darkBrown)

            Text("Already use another film logging app? Import your previously watched films so you're all caught up.")
                .font(.body)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showImportSheet = true
            } label: {
                Label("Import from CSV", systemImage: "doc.badge.arrow.up")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(PopcornTheme.sepiaBrown, in: .rect(cornerRadius: 12))
            }

            Text("You can also do this later in Settings")
                .font(.caption)
                .foregroundStyle(PopcornTheme.subtleGray)

            Spacer()
        }
        .alert("Import", isPresented: $showImportSheet) {
            Button("OK") {}
        } message: {
            Text("CSV import will be available when connected to a file source. You can import your watch history anytime from Settings.")
        }
    }

    private var bottomButtons: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    withAnimation { currentStep -= 1 }
                } label: {
                    Text("Back")
                        .font(.headline)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                }
            }

            Spacer()

            Button {
                if currentStep < 3 {
                    withAnimation { currentStep += 1 }
                } else {
                    finishOnboarding()
                }
            } label: {
                Text(currentStep == 3 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 32)
                    .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private var suggestedFilms: [Film] {
        MockDataService.popularFilms.filter { film in
            !topFiveFilms.contains(where: { $0.id == film.id })
        }.prefix(8).map { $0 }
    }

    private func selectedFilmRow(_ film: Film, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.headline)
                .foregroundStyle(PopcornTheme.warmRed)
                .frame(width: 24)
            filmPosterSmall(film.posterURL)
            Text(film.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(PopcornTheme.darkBrown)
            Spacer()
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    topFiveFilms.removeAll { $0.id == film.id }
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(PopcornTheme.warmRed)
            }
        }
        .padding(10)
        .background(PopcornTheme.popcornYellow.opacity(0.15), in: .rect(cornerRadius: 10))
    }

    private func emptySlotRow(index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.headline)
                .foregroundStyle(PopcornTheme.subtleGray)
                .frame(width: 24)
            RoundedRectangle(cornerRadius: 4)
                .fill(PopcornTheme.subtleGray.opacity(0.2))
                .frame(width: 32, height: 44)
            Text("Tap a film below to add")
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.subtleGray)
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.5), in: .rect(cornerRadius: 10))
    }

    private func filmPosterSmall(_ urlString: String) -> some View {
        Color(PopcornTheme.sepiaBrown.opacity(0.2))
            .frame(width: 32, height: 44)
            .overlay {
                AsyncImage(url: URL(string: urlString)) { phase in
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
    }

    private func finishOnboarding() {
        viewModel.updateProfile(profileImage: selectedAvatar, topFive: topFiveFilms)
        viewModel.completeOnboarding()
    }
}
