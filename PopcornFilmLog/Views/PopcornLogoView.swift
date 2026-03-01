import SwiftUI

struct PopcornLogoView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(PopcornTheme.warmRed)
                .frame(width: size * 0.5, height: size * 0.55)
                .offset(y: size * 0.08)

            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(
                    LinearGradient(
                        colors: [PopcornTheme.warmRed, Color(red: 0.72, green: 0.2, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.55, height: size * 0.15)
                .offset(y: -size * 0.1)

            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(PopcornTheme.popcornYellow)
                    .frame(width: size * 0.22, height: size * 0.22)
                    .offset(
                        x: CGFloat(i - 1) * size * 0.18,
                        y: -size * 0.28
                    )
            }

            ForEach(0..<2, id: \.self) { i in
                Circle()
                    .fill(PopcornTheme.cream)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .offset(
                        x: CGFloat(i) * size * 0.2 - size * 0.1,
                        y: -size * 0.4
                    )
            }
        }
        .frame(width: size, height: size)
    }
}
