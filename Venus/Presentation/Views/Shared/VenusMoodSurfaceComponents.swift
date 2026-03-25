//
//  VenusMoodSurfaceComponents.swift
//  Venus
//
//  Created by Kaua on 24/03/26.
//

import SwiftUI

struct VenusGlassPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
            }

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
                .lineLimit(1)
        }
        .foregroundColor(tint)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(hex: "1E2E20").opacity(0.95) : Color.white.opacity(0.94))
                .overlay(
                    Capsule()
                        .stroke(
                            colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.8) : VenusTheme.moodSage.opacity(0.7),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 10, x: 0, y: 6)
    }
}

struct VenusFloatingHintBubble: View {
    let title: String
    let bodyText: String
    var systemImage: String? = nil
    var tint: Color = VenusTheme.moodMintStrong
    var maxWidth: CGFloat = 230

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let systemImage {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 30, height: 30)

                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(tint)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(bodyText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct VenusMoodWaveform: View {
    var tint: Color = VenusTheme.moodMintStrong
    var secondaryTint: Color = VenusTheme.moodMint
    var barHeights: [CGFloat] = [18, 24, 34, 48, 62, 76, 88, 76, 62, 48, 34, 24, 18]

    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                secondaryTint.opacity(0.1),
                                secondaryTint.opacity(0.34),
                                tint.opacity(index == barHeights.count / 2 ? 0.96 : 0.82)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 8, height: animate ? height : height * 0.9)
                    .opacity(animate ? 1 : 0.82)
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
        }
        .frame(height: 88)
        .padding(.horizontal, 14)
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

struct VenusMoodMascotOrb: View {
    var mood: MoodType? = nil
    var size: CGFloat = 258

    @State private var animateFloat = false

    // MARK: - Mood-driven colors

    private var orbColors: (light: String, mid: String, deep: String) {
        mood?.orbColors ?? ("D6FFB9", "9BF66F", "59D85A")
    }

    private var orbGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: orbColors.light),
                Color(hex: orbColors.mid),
                Color(hex: orbColors.deep)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        Color(hex: orbColors.mid)
    }

    private var faceInk: Color {
        Color(hex: mood?.faceColorHex ?? "27603F")
    }

    private var eyeInk: Color {
        // Slightly darker than face ink for contrast
        Color(hex: mood?.faceColorHex ?? "1A251D").opacity(0.9)
    }

    var body: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(glowColor.opacity(0.22))
                .frame(width: size * 1.08, height: size * 1.08)
                .blur(radius: 26)
                .scaleEffect(animateFloat ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 0.7), value: mood)

            mascotEar(rotation: -26)
                .offset(x: -size * 0.22, y: -size * 0.38)

            mascotEar(rotation: 26)
                .offset(x: size * 0.22, y: -size * 0.38)

            ZStack {
                mascotArm(rotation: -34)
                    .offset(x: -size * 0.45, y: size * 0.06)

                mascotArm(rotation: 34)
                    .offset(x: size * 0.45, y: size * 0.06)

                Circle()
                    .fill(orbGradient)
                    .overlay(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.34), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.2)
                    )
                    .animation(.easeInOut(duration: 0.7), value: mood)

                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: size * 0.52, height: size * 0.3)
                    .blur(radius: 10)
                    .offset(x: -size * 0.1, y: -size * 0.22)

                MascotFace(mood: mood, size: size, faceInk: faceInk, eyeInk: eyeInk)


            }
            .frame(width: size, height: size)
            .offset(y: animateFloat ? -8 : 6)
            .scaleEffect(animateFloat ? 1.02 : 0.98)
        }
        .frame(width: size * 1.4, height: size * 1.28)
        .onAppear {
            guard !animateFloat else { return }
            withAnimation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true)) {
                animateFloat = true
            }
        }
    }

    private func mascotEar(rotation: Double) -> some View {
        Capsule(style: .continuous)
            .fill(orbGradient)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)
            )
            .frame(width: size * 0.11, height: size * 0.24)
            .rotationEffect(.degrees(rotation + (animateFloat ? 4 : -4)))
            .animation(.easeInOut(duration: 0.7), value: mood)
    }

    private func mascotArm(rotation: Double) -> some View {
        Capsule(style: .continuous)
            .fill(orbGradient)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .frame(width: size * 0.13, height: size * 0.34)
            .rotationEffect(.degrees(rotation + (animateFloat ? 10 : -8)))
            .offset(y: animateFloat ? -4 : 4)
            .animation(.easeInOut(duration: 0.7), value: mood)
    }
}

private struct MascotFace: View {
    let mood: MoodType?
    let size: CGFloat
    let faceInk: Color
    let eyeInk: Color

    private var expression: MascotExpression {
        switch mood {
        case .happy:
            return MascotExpression(eyeStyle: .round, mouthStyle: .bigSmile, leftBrowAngle: 0, rightBrowAngle: 0, cheekOpacity: 0.16)
        case .calm:
            return MascotExpression(eyeStyle: .calm, mouthStyle: .softSmile, leftBrowAngle: 0, rightBrowAngle: 0, cheekOpacity: 0.08)
        case .energetic:
            return MascotExpression(eyeStyle: .alert, mouthStyle: .bigSmile, leftBrowAngle: -6, rightBrowAngle: 6, cheekOpacity: 0.12)
        case .stressed:
            return MascotExpression(eyeStyle: .stressed, mouthStyle: .flat, leftBrowAngle: 18, rightBrowAngle: -18, cheekOpacity: 0)
        case .sad:
            return MascotExpression(eyeStyle: .sad, mouthStyle: .frown, leftBrowAngle: -14, rightBrowAngle: 14, cheekOpacity: 0)
        case .tired:
            return MascotExpression(eyeStyle: .sleepy, mouthStyle: .sleepy, leftBrowAngle: -4, rightBrowAngle: 4, cheekOpacity: 0)
        case nil:
            return MascotExpression(eyeStyle: .round, mouthStyle: .softSmile, leftBrowAngle: 0, rightBrowAngle: 0, cheekOpacity: 0.05)
        }
    }

    var body: some View {
        ZStack {
            if expression.cheekOpacity > 0 {
                HStack(spacing: size * 0.3) {
                    Circle()
                        .fill(Color.white.opacity(expression.cheekOpacity))
                        .frame(width: size * 0.08, height: size * 0.08)

                    Circle()
                        .fill(Color.white.opacity(expression.cheekOpacity))
                        .frame(width: size * 0.08, height: size * 0.08)
                }
                .offset(y: size * 0.06)
            }

            if expression.leftBrowAngle != 0 || expression.rightBrowAngle != 0 {
                HStack(spacing: size * 0.2) {
                    MascotBrow(angle: expression.leftBrowAngle, ink: faceInk)
                    MascotBrow(angle: expression.rightBrowAngle, ink: faceInk)
                }
                .offset(y: -size * 0.12)
            }

            HStack(spacing: size * 0.22) {
                VenusMascotEye(style: expression.eyeStyle, ink: eyeInk)
                VenusMascotEye(style: expression.eyeStyle, ink: eyeInk)
            }
            .offset(y: -size * 0.02)

            VStack(spacing: size * 0.02) {
                Circle()
                    .fill(faceInk)
                    .frame(width: size * 0.042, height: size * 0.042)

                mouthView
            }
            .offset(y: size * 0.17)
        }
        .animation(.easeInOut(duration: 0.5), value: mood)
    }

    @ViewBuilder
    private var mouthView: some View {
        switch expression.mouthStyle {
        case .softSmile:
            MascotSmileShape()
                .stroke(faceInk, style: StrokeStyle(lineWidth: 5.2, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.18, height: size * 0.09)
        case .bigSmile:
            MascotSmileShape()
                .stroke(faceInk, style: StrokeStyle(lineWidth: 6.2, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.22, height: size * 0.11)
        case .flat:
            Capsule(style: .continuous)
                .fill(faceInk)
                .frame(width: size * 0.16, height: 5)
        case .frown:
            MascotFrownShape()
                .stroke(faceInk, style: StrokeStyle(lineWidth: 5.2, lineCap: .round, lineJoin: .round))
                .frame(width: size * 0.18, height: size * 0.09)
        case .sleepy:
            Capsule(style: .continuous)
                .fill(faceInk.opacity(0.9))
                .frame(width: size * 0.12, height: 4)
        }
    }
}

private struct MascotExpression {
    let eyeStyle: MascotEyeStyle
    let mouthStyle: MascotMouthStyle
    let leftBrowAngle: Double
    let rightBrowAngle: Double
    let cheekOpacity: Double
}

private enum MascotEyeStyle {
    case round, calm, alert, stressed, sad, sleepy
}

private enum MascotMouthStyle {
    case softSmile, bigSmile, flat, frown, sleepy
}

private struct VenusMascotEye: View {
    let style: MascotEyeStyle
    let ink: Color

    var body: some View {
        switch style {
        case .sleepy:
            Capsule(style: .continuous)
                .fill(ink)
                .frame(width: 28, height: 9)
                .overlay(
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 11, height: 3)
                        .offset(x: -4, y: -1)
                )
        case .calm:
            eyeOrb(width: 28, height: 22, yOffset: 1)
        case .alert:
            eyeOrb(width: 32, height: 32, yOffset: 0)
        case .stressed:
            eyeOrb(width: 30, height: 24, yOffset: 1)
                .rotationEffect(.degrees(4))
        case .sad:
            eyeOrb(width: 28, height: 22, yOffset: 3)
        case .round:
            eyeOrb(width: 30, height: 30, yOffset: 0)
        }
    }

    private func eyeOrb(width: CGFloat, height: CGFloat, yOffset: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill(ink)
                .frame(width: width, height: height)

            Circle()
                .fill(Color.white.opacity(0.96))
                .frame(width: width * 0.32, height: width * 0.32)
                .offset(x: width * 0.18, y: width * 0.16)

            Circle()
                .fill(Color.white.opacity(0.72))
                .frame(width: width * 0.16, height: width * 0.16)
                .offset(x: width * 0.52, y: width * 0.46)
        }
        .offset(y: yOffset)
    }
}

private struct MascotBrow: View {
    let angle: Double
    let ink: Color

    var body: some View {
        Capsule(style: .continuous)
            .fill(ink)
            .frame(width: 26, height: 4)
            .rotationEffect(.degrees(angle))
    }
}

private struct MascotSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.2))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY * 0.96)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.maxY * 0.96)
        )
        return path
    }
}

private struct MascotFrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.1),
            control: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.minY + rect.height * 0.08)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY),
            control: CGPoint(x: rect.maxX - rect.width * 0.34, y: rect.minY + rect.height * 0.08)
        )
        return path
    }
}
