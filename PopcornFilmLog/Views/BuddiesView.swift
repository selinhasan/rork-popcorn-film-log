import SwiftUI

struct BuddiesView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showAddBuddy = false
    @State private var showNewPost = false
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    Text("All").tag(0)
                    Text("Activity").tag(1)
                    Text("Posts").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollView {
                    switch selectedSegment {
                    case 0: allFeed
                    case 1: activityFeed
                    default: postsFeed
                    }
                }
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Buddies")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if selectedSegment == 0 || selectedSegment == 2 {
                            Button("New Post", systemImage: "square.and.pencil") {
                                showNewPost = true
                            }
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                        }
                        Button("Add Buddy", systemImage: "person.badge.plus") {
                            showAddBuddy = true
                        }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                }
            }
            .sheet(isPresented: $showAddBuddy) {
                AddBuddySheet()
            }
            .sheet(isPresented: $showNewPost) {
                NewPostSheet()
            }
        }
    }

    private var allFeed: some View {
        LazyVStack(spacing: 12) {
            let combined = allItems
            if combined.isEmpty {
                emptyState(icon: "person.2", title: "Nothing here yet", subtitle: "Add some buddies to see what they're up to!")
            } else {
                ForEach(combined) { item in
                    switch item.content {
                    case .log(let entry):
                        BuddyLogCard(entry: entry)
                    case .post(let post):
                        PostCard(post: post)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var activityFeed: some View {
        LazyVStack(spacing: 12) {
            if viewModel.buddyLogs.isEmpty {
                emptyState(icon: "person.2", title: "No buddy activity yet", subtitle: "Add some buddies to see what they're watching!")
            } else {
                ForEach(viewModel.buddyLogs) { entry in
                    BuddyLogCard(entry: entry)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var postsFeed: some View {
        LazyVStack(spacing: 12) {
            if viewModel.posts.isEmpty {
                emptyState(icon: "bubble.left.and.bubble.right", title: "No posts yet", subtitle: "Be the first to share something with your buddies!")
            } else {
                ForEach(viewModel.posts) { post in
                    PostCard(post: post)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var allItems: [FeedItem] {
        var items: [FeedItem] = []
        for entry in viewModel.buddyLogs {
            items.append(FeedItem(date: entry.dateWatched, content: .log(entry)))
        }
        for post in viewModel.posts {
            items.append(FeedItem(date: post.date, content: .post(post)))
        }
        return items.sorted { $0.date > $1.date }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(PopcornTheme.sepiaBrown.opacity(0.4))
            Text(title)
                .font(.title3.weight(.medium))
                .foregroundStyle(PopcornTheme.darkBrown)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 60)
        .padding(.horizontal, 32)
    }
}

struct FeedItem: Identifiable {
    let id = UUID()
    let date: Date
    let content: FeedContent

    enum FeedContent {
        case log(LogEntry)
        case post(BuddyPost)
    }
}

struct BuddyLogCard: View {
    let entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(name: "avatar_\((entry.userId.hashValue % 10 + 10) % 10 + 1)", size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PopcornTheme.darkBrown)
                    Text("watched a film")
                        .font(.caption)
                        .foregroundStyle(PopcornTheme.subtleGray)
                }
                Spacer()
                Text(entry.dateWatched.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(PopcornTheme.subtleGray)
            }

            HStack(spacing: 12) {
                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                    .frame(width: 50, height: 70)
                    .overlay {
                        AsyncImage(url: URL(string: entry.film.posterURL)) { phase in
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
                    Text(entry.film.title)
                        .font(.headline)
                        .foregroundStyle(PopcornTheme.darkBrown)
                        .lineLimit(1)
                    PopcornRatingDisplay(rating: entry.rating, isGoldenPopcorn: entry.isGoldenPopcorn)
                    if !entry.review.isEmpty {
                        Text(entry.review)
                            .font(.caption)
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct PostCard: View {
    let post: BuddyPost
    @Environment(AppViewModel.self) private var viewModel
    @State private var showComments = false
    @State private var newComment = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                AvatarView(name: post.profileImageName, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PopcornTheme.darkBrown)
                    Text(post.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(PopcornTheme.subtleGray)
                }
                Spacer()
            }

            if post.postType == .watchlistAdd, let film = post.relatedFilm {
                HStack(spacing: 10) {
                    Color(PopcornTheme.sepiaBrown.opacity(0.15))
                        .frame(width: 40, height: 56)
                        .overlay {
                            AsyncImage(url: URL(string: film.posterURL)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Image(systemName: "film")
                                        .font(.caption)
                                        .foregroundStyle(PopcornTheme.sepiaBrown)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        .clipShape(.rect(cornerRadius: 4))
                    Text(post.text)
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            } else {
                Text(post.text)
                    .font(.body)
                    .foregroundStyle(PopcornTheme.darkBrown)
            }

            HStack(spacing: 20) {
                Button {
                    viewModel.togglePostLike(post)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLiked ? PopcornTheme.warmRed : PopcornTheme.sepiaBrown)
                        Text("\(post.likeCount)")
                            .font(.caption)
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                }
                .sensoryFeedback(.impact(weight: .light), trigger: post.isLiked)

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showComments.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                        Text("\(post.comments.count)")
                            .font(.caption)
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                    }
                }
            }

            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments) { comment in
                        HStack(alignment: .top, spacing: 8) {
                            Text(comment.username)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PopcornTheme.darkBrown)
                            Text(comment.text)
                                .font(.caption)
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Add a comment...", text: $newComment)
                            .font(.caption)
                            .padding(8)
                            .background(PopcornTheme.cream, in: .rect(cornerRadius: 8))
                        Button {
                            guard !newComment.isEmpty else { return }
                            viewModel.addComment(to: post, text: newComment)
                            newComment = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.caption)
                                .foregroundStyle(PopcornTheme.warmRed)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color.white, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

struct AddBuddySheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var searchResults: [UserProfile] {
        if searchText.isEmpty { return MockDataService.sampleBuddies }
        return MockDataService.sampleBuddies.filter {
            $0.username.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(searchResults) { buddy in
                    HStack(spacing: 12) {
                        AvatarView(name: buddy.profileImageName, size: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(buddy.username)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PopcornTheme.darkBrown)
                            Text(buddy.email)
                                .font(.caption)
                                .foregroundStyle(PopcornTheme.subtleGray)
                        }
                        Spacer()
                        if viewModel.buddies.contains(where: { $0.id == buddy.id }) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PopcornTheme.freshGreen)
                        } else {
                            Button {
                                viewModel.addBuddy(buddy)
                            } label: {
                                Text("Add")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(PopcornTheme.warmRed, in: .capsule)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by username or email")
            .navigationTitle("Add Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }
        }
    }
}

struct NewPostSheet: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var postText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("What's on your mind?", text: $postText, axis: .vertical)
                    .lineLimit(3...10)
                    .focused($isFocused)
                    .padding()
                Spacer()
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        viewModel.createPost(text: postText)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(PopcornTheme.warmRed)
                    .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { isFocused = true }
        }
    }
}
