import SwiftUI

struct PopcornRatingView: View {
    @Binding var rating: Double
    let maxRating: Int = 5
    let interactive: Bool

    init(rating: Binding<Double>, interactive: Bool = true) {
        self._rating = rating
        self.interactive = interactive
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                popcornIcon(for: index)
                    .onTapGesture {
                        guard interactive else { return }
                        let tapped = Double(index)
                        if rating == tapped {
                            rating = tapped - 0.5
                        } else if rating == tapped - 0.5 {
                            rating = 0
                        } else {
                            rating = tapped
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func popcornIcon(for index: Int) -> some View {
        let value = Double(index)
        ZStack {
            if rating >= value {
                Image(systemName: "popcorn.fill")
                    .foregroundStyle(PopcornTheme.popcornYellow)
            } else if rating >= value - 0.5 {
                Image(systemName: "popcorn.fill")
                    .foregroundStyle(
                        .linearGradient(
                            stops: [
                                .init(color: PopcornTheme.popcornYellow, location: 0.5),
                                .init(color: PopcornTheme.subtleGray.opacity(0.3), location: 0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            } else {
                Image(systemName: "popcorn")
                    .foregroundStyle(PopcornTheme.subtleGray.opacity(0.4))
            }
        }
        .font(.title2)
    }
}

struct GoldenPopcornView: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "popcorn.fill")
            .font(.system(size: size))
            .foregroundStyle(
                .linearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0),
                        Color(red: 0.85, green: 0.65, blue: 0.13),
                        Color(red: 1.0, green: 0.92, blue: 0.5),
                        Color(red: 0.85, green: 0.65, blue: 0.13),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.5), radius: 4, y: 2)
    }
}

struct PopcornRatingDisplay: View {
    let rating: Double
    var isGoldenPopcorn: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            if isGoldenPopcorn {
                GoldenPopcornView(size: 12)
                Text("6/5")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(red: 0.85, green: 0.65, blue: 0.13))
            } else {
                ForEach(1...5, id: \.self) { index in
                    let value = Double(index)
                    if rating >= value {
                        Image(systemName: "popcorn.fill")
                            .foregroundStyle(PopcornTheme.popcornYellow)
                    } else if rating >= value - 0.5 {
                        Image(systemName: "popcorn.fill")
                            .foregroundStyle(
                                .linearGradient(
                                    stops: [
                                        .init(color: PopcornTheme.popcornYellow, location: 0.5),
                                        .init(color: PopcornTheme.subtleGray.opacity(0.3), location: 0.5)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    } else {
                        Image(systemName: "popcorn")
                            .foregroundStyle(PopcornTheme.subtleGray.opacity(0.4))
                    }
                }
            }
        }
        .font(.caption)
    }
}
