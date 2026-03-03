import SwiftUI

struct PopcornLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: size * 0.04, bottomLeadingRadius: size * 0.12, bottomTrailingRadius: size * 0.12, topTrailingRadius: size * 0.04)
                .fill(PopcornTheme.warmRed)
                .frame(width: size * 0.44, height: size * 0.45)
                .offset(y: size * 0.1)

            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: size * 0.03)
                    .fill(PopcornTheme.warmRed.opacity(0.9))
                    .frame(width: size * 0.5, height: size * 0.08)
            }
            .offset(y: -size * 0.07)

            HStack(spacing: size * 0.01) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.04, height: size * 0.38)
                }
            }
            .offset(y: size * 0.12)
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: size * 0.04, bottomLeadingRadius: size * 0.12, bottomTrailingRadius: size * 0.12, topTrailingRadius: size * 0.04)
                    .size(width: size * 0.44, height: size * 0.45)
                    .offset(x: (size - size * 0.44) / 2, y: size * 0.1 + (size - size * 0.45) / 2)
            )

            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(PopcornTheme.popcornYellow)
                    .frame(width: size * 0.2, height: size * 0.2)
                    .offset(
                        x: CGFloat(i - 1) * size * 0.16,
                        y: -size * 0.2
                    )
            }

            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(PopcornTheme.popcornYellow.opacity(0.9))
                    .frame(width: size * 0.16, height: size * 0.16)
                    .offset(
                        x: CGFloat(i) * size * 0.18 - size * 0.09,
                        y: -size * 0.33
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
