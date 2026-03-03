import SwiftUI

struct AvatarView: View {
    let name: String
    let size: CGFloat
    var customURL: String? = nil

    private var avatarColors: (bg: Color, fg: Color, hair: Color, skin: Color, accent: Color) {
        let palettes: [(Color, Color, Color, Color, Color)] = [
            (PopcornTheme.popcornYellow.opacity(0.25), PopcornTheme.sepiaBrown, Color(red: 0.25, green: 0.18, blue: 0.1), Color(red: 0.96, green: 0.84, blue: 0.72), PopcornTheme.sepiaBrown.opacity(0.3)),
            (PopcornTheme.warmRed.opacity(0.18), PopcornTheme.warmRed.opacity(0.85), Color(red: 0.12, green: 0.08, blue: 0.05), Color(red: 0.87, green: 0.72, blue: 0.58), PopcornTheme.warmRed.opacity(0.2)),
            (PopcornTheme.freshGreen.opacity(0.18), PopcornTheme.freshGreen.opacity(0.85), Color(red: 0.55, green: 0.32, blue: 0.12), Color(red: 0.92, green: 0.78, blue: 0.65), PopcornTheme.freshGreen.opacity(0.2)),
            (PopcornTheme.sepiaBrown.opacity(0.2), PopcornTheme.darkBrown.opacity(0.85), Color(red: 0.18, green: 0.12, blue: 0.08), Color(red: 0.78, green: 0.6, blue: 0.45), PopcornTheme.sepiaBrown.opacity(0.25)),
            (Color(red: 0.92, green: 0.88, blue: 0.8), PopcornTheme.sepiaBrown.opacity(0.85), Color(red: 0.82, green: 0.6, blue: 0.28), Color(red: 0.95, green: 0.82, blue: 0.7), PopcornTheme.popcornYellow.opacity(0.25)),
            (PopcornTheme.popcornYellow.opacity(0.3), PopcornTheme.darkBrown.opacity(0.8), Color(red: 0.1, green: 0.08, blue: 0.05), Color(red: 0.65, green: 0.48, blue: 0.35), PopcornTheme.popcornYellow.opacity(0.2)),
            (PopcornTheme.warmRed.opacity(0.15), PopcornTheme.sepiaBrown.opacity(0.85), Color(red: 0.42, green: 0.22, blue: 0.1), Color(red: 0.9, green: 0.76, blue: 0.62), PopcornTheme.warmRed.opacity(0.15)),
            (PopcornTheme.freshGreen.opacity(0.15), PopcornTheme.darkBrown.opacity(0.8), Color(red: 0.65, green: 0.45, blue: 0.2), Color(red: 0.94, green: 0.8, blue: 0.66), PopcornTheme.freshGreen.opacity(0.15)),
            (Color(red: 0.88, green: 0.82, blue: 0.72), PopcornTheme.warmRed.opacity(0.8), Color(red: 0.22, green: 0.15, blue: 0.08), Color(red: 0.82, green: 0.65, blue: 0.5), PopcornTheme.warmRed.opacity(0.15)),
            (PopcornTheme.cream, PopcornTheme.sepiaBrown.opacity(0.85), Color(red: 0.5, green: 0.28, blue: 0.1), Color(red: 0.98, green: 0.86, blue: 0.74), PopcornTheme.sepiaBrown.opacity(0.15)),
        ]
        let index: Int
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            index = num - 1
        } else {
            index = abs(name.hashValue) % palettes.count
        }
        return palettes[index]
    }

    private var avatarIndex: Int {
        if let num = Int(name.replacingOccurrences(of: "avatar_", with: "")), num >= 1, num <= 10 {
            return num - 1
        }
        return abs(name.hashValue) % 10
    }

    private var isFeminine: Bool {
        avatarIndex >= 5
    }

    var body: some View {
        if let url = customURL, !url.isEmpty {
            if url.hasPrefix("local://") {
                localPhotoView
            } else if let imageURL = URL(string: url) {
                Color(PopcornTheme.sepiaBrown.opacity(0.15))
                    .frame(width: size, height: size)
                    .overlay {
                        AsyncImage(url: imageURL) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else {
                                personAvatar
                            }
                        }
                        .allowsHitTesting(false)
                    }
                    .clipShape(Circle())
            } else {
                personAvatar
            }
        } else {
            personAvatar
        }
    }

    @ViewBuilder
    private var localPhotoView: some View {
        if let data = AppViewModel.loadLocalProfilePhoto(),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            personAvatar
        }
    }

    private var personAvatar: some View {
        let colors = avatarColors
        return ZStack {
            Circle()
                .fill(colors.bg)

            Canvas { context, canvasSize in
                let s = min(canvasSize.width, canvasSize.height)
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2

                let skinColor = colors.skin
                let hairColor = colors.hair
                let shirtColor = colors.fg
                let eyeColor = colors.hair.opacity(0.9)

                let headRadius = s * 0.19
                let headCenterY = cy - s * 0.05

                if isFeminine {
                    drawFeminineHair(context: &context, cx: cx, headCenterY: headCenterY, headRadius: headRadius, s: s, color: hairColor)
                } else {
                    drawMasculineHair(context: &context, cx: cx, headCenterY: headCenterY, headRadius: headRadius, s: s, color: hairColor)
                }

                let headRect = CGRect(x: cx - headRadius, y: headCenterY - headRadius, width: headRadius * 2, height: headRadius * 2)
                context.fill(Path(ellipseIn: headRect), with: .color(skinColor))

                if isFeminine {
                    drawFeminineHairOverlay(context: &context, cx: cx, headCenterY: headCenterY, headRadius: headRadius, s: s, color: hairColor)
                }

                let eyeSpacing = headRadius * 0.38
                let eyeY = headCenterY - headRadius * 0.08
                let eyeW = headRadius * 0.2
                let eyeH = headRadius * 0.22

                let leftEyeRect = CGRect(x: cx - eyeSpacing - eyeW / 2, y: eyeY - eyeH / 2, width: eyeW, height: eyeH)
                let rightEyeRect = CGRect(x: cx + eyeSpacing - eyeW / 2, y: eyeY - eyeH / 2, width: eyeW, height: eyeH)
                context.fill(Path(ellipseIn: leftEyeRect), with: .color(eyeColor))
                context.fill(Path(ellipseIn: rightEyeRect), with: .color(eyeColor))

                let mouthY = headCenterY + headRadius * 0.35
                var mouthPath = Path()
                mouthPath.move(to: CGPoint(x: cx - headRadius * 0.18, y: mouthY))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: cx + headRadius * 0.18, y: mouthY),
                    control: CGPoint(x: cx, y: mouthY + headRadius * 0.18)
                )
                context.stroke(mouthPath, with: .color(hairColor.opacity(0.5)), lineWidth: max(1, s * 0.012))

                if isFeminine {
                    let cheekR = headRadius * 0.12
                    let cheekY = headCenterY + headRadius * 0.15
                    let cheekSpacing = headRadius * 0.52
                    let leftCheek = CGRect(x: cx - cheekSpacing - cheekR, y: cheekY - cheekR, width: cheekR * 2, height: cheekR * 2)
                    let rightCheek = CGRect(x: cx + cheekSpacing - cheekR, y: cheekY - cheekR, width: cheekR * 2, height: cheekR * 2)
                    context.fill(Path(ellipseIn: leftCheek), with: .color(Color.pink.opacity(0.2)))
                    context.fill(Path(ellipseIn: rightCheek), with: .color(Color.pink.opacity(0.2)))
                }

                let neckW = headRadius * 0.4
                let neckH = headRadius * 0.3
                let neckY = headCenterY + headRadius * 0.85
                let neckRect = CGRect(x: cx - neckW / 2, y: neckY, width: neckW, height: neckH)
                context.fill(Path(roundedRect: neckRect, cornerRadius: neckW * 0.2), with: .color(skinColor))

                let bodyTop = neckY + neckH * 0.4
                let bodyW = s * 0.56
                let bodyH = s * 0.32

                if isFeminine {
                    drawFeminineBody(context: &context, cx: cx, bodyTop: bodyTop, bodyW: bodyW, bodyH: bodyH, s: s, color: shirtColor)
                } else {
                    drawMasculineBody(context: &context, cx: cx, bodyTop: bodyTop, bodyW: bodyW, bodyH: bodyH, s: s, color: shirtColor)
                }
            }
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }

    private func drawMasculineHair(context: inout GraphicsContext, cx: CGFloat, headCenterY: CGFloat, headRadius: CGFloat, s: CGFloat, color: Color) {
        let idx = avatarIndex
        switch idx {
        case 0:
            let hairW = headRadius * 2.1
            let hairH = headRadius * 1.1
            let hairY = headCenterY - headRadius * 1.0
            let rect = CGRect(x: cx - hairW / 2, y: hairY, width: hairW, height: hairH)
            context.fill(Path(roundedRect: rect, cornerRadius: hairW * 0.35), with: .color(color))
        case 1:
            let hairW = headRadius * 2.15
            let hairH = headRadius * 0.85
            let hairY = headCenterY - headRadius * 0.95
            let rect = CGRect(x: cx - hairW / 2, y: hairY, width: hairW, height: hairH)
            context.fill(Path(roundedRect: rect, cornerRadius: hairW * 0.15), with: .color(color))
        case 2:
            for i in 0..<7 {
                let angle = Double(i - 3) * 12.0
                let rad = angle * .pi / 180
                let blobR = headRadius * 0.28
                let dist = headRadius * 0.75
                let bx = cx + CGFloat(sin(rad)) * dist
                let by = headCenterY - headRadius * 0.6 - CGFloat(cos(rad)) * dist * 0.3
                let rect = CGRect(x: bx - blobR, y: by - blobR, width: blobR * 2, height: blobR * 2)
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        case 3:
            let baseW = headRadius * 2.2
            let baseH = headRadius * 0.9
            let baseY = headCenterY - headRadius * 0.95
            let baseRect = CGRect(x: cx - baseW / 2, y: baseY, width: baseW, height: baseH)
            context.fill(Path(roundedRect: baseRect, cornerRadius: baseW * 0.3), with: .color(color))
            for i in 0..<3 {
                let spikeX = cx + CGFloat(i - 1) * headRadius * 0.45
                let spikeW = headRadius * 0.22
                let spikeH = headRadius * 0.55
                let spikeRect = CGRect(x: spikeX - spikeW / 2, y: baseY - spikeH * 0.5, width: spikeW, height: spikeH)
                context.fill(Path(roundedRect: spikeRect, cornerRadius: spikeW * 0.4), with: .color(color))
            }
        default:
            let hairW = headRadius * 2.2
            let hairH = headRadius * 1.05
            let hairY = headCenterY - headRadius * 1.02
            let rect = CGRect(x: cx - hairW / 2, y: hairY, width: hairW, height: hairH)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func drawFeminineHair(context: inout GraphicsContext, cx: CGFloat, headCenterY: CGFloat, headRadius: CGFloat, s: CGFloat, color: Color) {
        let idx = avatarIndex - 5
        switch idx {
        case 0:
            let topW = headRadius * 2.3
            let topH = headRadius * 1.2
            let topY = headCenterY - headRadius * 1.05
            let topRect = CGRect(x: cx - topW / 2, y: topY, width: topW, height: topH)
            context.fill(Path(ellipseIn: topRect), with: .color(color))
            let sideW = headRadius * 0.45
            let sideH = headRadius * 1.6
            let sideY = headCenterY - headRadius * 0.4
            let leftRect = CGRect(x: cx - headRadius * 1.15 - sideW / 2, y: sideY, width: sideW, height: sideH)
            let rightRect = CGRect(x: cx + headRadius * 1.15 - sideW / 2, y: sideY, width: sideW, height: sideH)
            context.fill(Path(roundedRect: leftRect, cornerRadius: sideW * 0.4), with: .color(color))
            context.fill(Path(roundedRect: rightRect, cornerRadius: sideW * 0.4), with: .color(color))
        case 1:
            let topW = headRadius * 2.4
            let topH = headRadius * 1.15
            let topY = headCenterY - headRadius * 1.05
            let topRect = CGRect(x: cx - topW / 2, y: topY, width: topW, height: topH)
            context.fill(Path(ellipseIn: topRect), with: .color(color))
            let sideW = headRadius * 0.5
            let sideH = headRadius * 1.3
            let sideY = headCenterY - headRadius * 0.2
            let leftRect = CGRect(x: cx - headRadius * 1.1 - sideW / 2, y: sideY, width: sideW, height: sideH)
            let rightRect = CGRect(x: cx + headRadius * 1.1 - sideW / 2, y: sideY, width: sideW, height: sideH)
            context.fill(Path(roundedRect: leftRect, cornerRadius: sideW * 0.45), with: .color(color))
            context.fill(Path(roundedRect: rightRect, cornerRadius: sideW * 0.45), with: .color(color))
        case 2:
            let topW = headRadius * 2.35
            let topH = headRadius * 1.25
            let topY = headCenterY - headRadius * 1.1
            let topRect = CGRect(x: cx - topW / 2, y: topY, width: topW, height: topH)
            context.fill(Path(ellipseIn: topRect), with: .color(color))
            let bunR = headRadius * 0.45
            let bunRect = CGRect(x: cx - bunR, y: headCenterY - headRadius * 1.5 - bunR * 0.3, width: bunR * 2, height: bunR * 2)
            context.fill(Path(ellipseIn: bunRect), with: .color(color))
        case 3:
            let topW = headRadius * 2.3
            let topH = headRadius * 1.15
            let topY = headCenterY - headRadius * 1.0
            let topRect = CGRect(x: cx - topW / 2, y: topY, width: topW, height: topH)
            context.fill(Path(ellipseIn: topRect), with: .color(color))
            let bangsH = headRadius * 0.35
            let bangsW = headRadius * 1.8
            let bangsRect = CGRect(x: cx - bangsW / 2, y: headCenterY - headRadius * 1.0, width: bangsW, height: bangsH)
            context.fill(Path(roundedRect: bangsRect, cornerRadius: bangsH * 0.5), with: .color(color))
            let sideW = headRadius * 0.4
            let sideH = headRadius * 1.8
            let sideY = headCenterY - headRadius * 0.3
            let leftRect = CGRect(x: cx - headRadius * 1.12 - sideW / 2, y: sideY, width: sideW, height: sideH)
            let rightRect = CGRect(x: cx + headRadius * 1.12 - sideW / 2, y: sideY, width: sideW, height: sideH)
            context.fill(Path(roundedRect: leftRect, cornerRadius: sideW * 0.45), with: .color(color))
            context.fill(Path(roundedRect: rightRect, cornerRadius: sideW * 0.45), with: .color(color))
        default:
            let topW = headRadius * 2.4
            let topH = headRadius * 1.3
            let topY = headCenterY - headRadius * 1.1
            let topRect = CGRect(x: cx - topW / 2, y: topY, width: topW, height: topH)
            context.fill(Path(ellipseIn: topRect), with: .color(color))
            let sideW = headRadius * 0.55
            let sideH = headRadius * 2.0
            let sideY = headCenterY - headRadius * 0.5
            let leftRect = CGRect(x: cx - headRadius * 1.05 - sideW / 2, y: sideY, width: sideW, height: sideH)
            let rightRect = CGRect(x: cx + headRadius * 1.05 - sideW / 2, y: sideY, width: sideW, height: sideH)
            context.fill(Path(roundedRect: leftRect, cornerRadius: sideW * 0.5), with: .color(color))
            context.fill(Path(roundedRect: rightRect, cornerRadius: sideW * 0.5), with: .color(color))
        }
    }

    private func drawFeminineHairOverlay(context: inout GraphicsContext, cx: CGFloat, headCenterY: CGFloat, headRadius: CGFloat, s: CGFloat, color: Color) {
        let idx = avatarIndex - 5
        if idx == 3 || idx == 2 { return }
        let bangsW = headRadius * 1.6
        let bangsH = headRadius * 0.45
        let bangsY = headCenterY - headRadius * 0.98
        let bangsRect = CGRect(x: cx - bangsW / 2, y: bangsY, width: bangsW, height: bangsH)
        context.fill(Path(roundedRect: bangsRect, cornerRadius: bangsH * 0.5), with: .color(color))
    }

    private func drawMasculineBody(context: inout GraphicsContext, cx: CGFloat, bodyTop: CGFloat, bodyW: CGFloat, bodyH: CGFloat, s: CGFloat, color: Color) {
        let idx = avatarIndex
        var bodyPath = Path()
        let shoulderRadius = bodyW * 0.12

        switch idx {
        case 0, 4:
            bodyPath.move(to: CGPoint(x: cx - bodyW / 2 + shoulderRadius, y: bodyTop))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2 - shoulderRadius, y: bodyTop))
            bodyPath.addQuadCurve(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + shoulderRadius), control: CGPoint(x: cx + bodyW / 2, y: bodyTop))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + shoulderRadius))
            bodyPath.addQuadCurve(to: CGPoint(x: cx - bodyW / 2 + shoulderRadius, y: bodyTop), control: CGPoint(x: cx - bodyW / 2, y: bodyTop))
            bodyPath.closeSubpath()
            context.fill(bodyPath, with: .color(color))
        case 1:
            let collarW = bodyW * 0.25
            bodyPath.move(to: CGPoint(x: cx - collarW / 2, y: bodyTop))
            bodyPath.addLine(to: CGPoint(x: cx + collarW / 2, y: bodyTop))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH * 0.35))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH * 0.35))
            bodyPath.closeSubpath()
            context.fill(bodyPath, with: .color(color))
        default:
            let rect = CGRect(x: cx - bodyW / 2, y: bodyTop, width: bodyW, height: bodyH)
            context.fill(Path(roundedRect: rect, cornerRadius: shoulderRadius), with: .color(color))
        }

        if idx == 1 || idx == 3 {
            let lineW = max(1, s * 0.008)
            var vLine = Path()
            vLine.move(to: CGPoint(x: cx, y: bodyTop + bodyH * 0.05))
            vLine.addLine(to: CGPoint(x: cx, y: bodyTop + bodyH * 0.5))
            context.stroke(vLine, with: .color(color.opacity(0.4)), lineWidth: lineW)
        }
    }

    private func drawFeminineBody(context: inout GraphicsContext, cx: CGFloat, bodyTop: CGFloat, bodyW: CGFloat, bodyH: CGFloat, s: CGFloat, color: Color) {
        let idx = avatarIndex - 5
        let shoulderRadius = bodyW * 0.12

        switch idx {
        case 0:
            let topW = bodyW * 0.85
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: cx - topW / 2, y: bodyTop))
            bodyPath.addQuadCurve(to: CGPoint(x: cx + topW / 2, y: bodyTop), control: CGPoint(x: cx, y: bodyTop - bodyH * 0.08))
            bodyPath.addQuadCurve(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH), control: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH * 0.3))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addQuadCurve(to: CGPoint(x: cx - topW / 2, y: bodyTop), control: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH * 0.3))
            bodyPath.closeSubpath()
            context.fill(bodyPath, with: .color(color))
        case 1, 4:
            let necklineW = bodyW * 0.2
            var bodyPath = Path()
            bodyPath.move(to: CGPoint(x: cx - necklineW, y: bodyTop))
            bodyPath.addQuadCurve(to: CGPoint(x: cx, y: bodyTop + bodyH * 0.12), control: CGPoint(x: cx - necklineW * 0.3, y: bodyTop + bodyH * 0.12))
            bodyPath.addQuadCurve(to: CGPoint(x: cx + necklineW, y: bodyTop), control: CGPoint(x: cx + necklineW * 0.3, y: bodyTop + bodyH * 0.12))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2 - shoulderRadius, y: bodyTop))
            bodyPath.addQuadCurve(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + shoulderRadius), control: CGPoint(x: cx + bodyW / 2, y: bodyTop))
            bodyPath.addLine(to: CGPoint(x: cx + bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + bodyH))
            bodyPath.addLine(to: CGPoint(x: cx - bodyW / 2, y: bodyTop + shoulderRadius))
            bodyPath.addQuadCurve(to: CGPoint(x: cx - bodyW / 2 + shoulderRadius, y: bodyTop), control: CGPoint(x: cx - bodyW / 2, y: bodyTop))
            bodyPath.closeSubpath()
            context.fill(bodyPath, with: .color(color))
        default:
            let rect = CGRect(x: cx - bodyW * 0.45, y: bodyTop, width: bodyW * 0.9, height: bodyH)
            context.fill(Path(roundedRect: rect, cornerRadius: shoulderRadius), with: .color(color))
        }
    }
}
