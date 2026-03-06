import SwiftUI

struct DetailedStatsView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    watchTimeBanner
                    if !stats.topGenres.isEmpty { genresSection }
                    if !stats.topDirectors.isEmpty { directorsSection }
                    if !stats.topActors.isEmpty { actorsSection }
                }
                .padding(.bottom, 32)
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .navigationTitle("Your Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var stats: UserStats { viewModel.userStats }

    private var watchTimeBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("\(stats.filmsWatched)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(PopcornTheme.warmRed)
                    Text("Films")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }

                Rectangle()
                    .fill(PopcornTheme.sepiaBrown.opacity(0.2))
                    .frame(width: 1, height: 50)

                VStack(spacing: 4) {
                    Text("\(stats.totalMinutes)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(PopcornTheme.popcornYellow)
                    Text("Minutes")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }

                Rectangle()
                    .fill(PopcornTheme.sepiaBrown.opacity(0.2))
                    .frame(width: 1, height: 50)

                VStack(spacing: 4) {
                    Text("\(stats.totalHours)")
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(PopcornTheme.freshGreen)
                    Text("Hours")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
            }

            if stats.totalDays > 0 {
                Text("That's \(stats.totalDays) full day\(stats.totalDays == 1 ? "" : "s") of watching!")
                    .font(.caption)
                    .foregroundStyle(PopcornTheme.sepiaBrown)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.white, in: .rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 3)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Genres Watched", systemImage: "theatermasks.fill")
                .font(.headline)
                .foregroundStyle(PopcornTheme.darkBrown)
                .padding(.horizontal)

            VStack(spacing: 6) {
                ForEach(stats.topGenres) { genre in
                    statRow(name: genre.name, count: genre.count, maxCount: stats.topGenres.first?.count ?? 1, color: PopcornTheme.warmRed)
                }
            }
            .padding(.horizontal)
        }
    }

    private var directorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Directors Watched", systemImage: "megaphone.fill")
                .font(.headline)
                .foregroundStyle(PopcornTheme.darkBrown)
                .padding(.horizontal)

            VStack(spacing: 6) {
                ForEach(stats.topDirectors) { director in
                    statRow(name: director.name, count: director.count, maxCount: stats.topDirectors.first?.count ?? 1, color: PopcornTheme.popcornYellow)
                }
            }
            .padding(.horizontal)
        }
    }

    private var actorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Actors Watched", systemImage: "person.fill")
                .font(.headline)
                .foregroundStyle(PopcornTheme.darkBrown)
                .padding(.horizontal)

            VStack(spacing: 6) {
                ForEach(stats.topActors) { actor in
                    statRow(name: actor.name, count: actor.count, maxCount: stats.topActors.first?.count ?? 1, color: PopcornTheme.freshGreen)
                }
            }
            .padding(.horizontal)
        }
    }

    private func statRow(name: String, count: Int, maxCount: Int, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.subheadline)
                .foregroundStyle(PopcornTheme.darkBrown)
                .frame(width: 120, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                let fraction = maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) : 0
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(0.25))
                    .frame(height: 20)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: max(geo.size.width * fraction, 4), height: 20)
                    }
            }
            .frame(height: 20)

            Text("\(count)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .frame(width: 30, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white, in: .rect(cornerRadius: 10))
    }
}
