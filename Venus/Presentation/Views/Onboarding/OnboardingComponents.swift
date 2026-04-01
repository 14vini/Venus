//
//  OnboardingComponents.swift
//  Venus
//
//  Created by Kaua on 26/03/26.
//

import SwiftUI

struct OnboardingPill: View {
    let title: String
    let systemImage: String
    var tint: Color = VenusTheme.primary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))

            Text(title)
                .font(.system(.caption, design: .rounded).weight(.bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            Capsule(style: .continuous)
                .fill(LinearGradient(
                    colors: [tint, tint.opacity(0.75)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .shadow(color: tint.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

struct OnboardingAccessoryPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = VenusTheme.textSecondary

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .bold))
            }

            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.bold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: Capsule(style: .continuous))
    }
}

struct OnboardingStepHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String?
    let systemImage: String
    var tint: Color = VenusTheme.primary
    var accessory: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                OnboardingPill(title: eyebrow, systemImage: systemImage, tint: tint)

                Spacer()

                if let accessory {
                    OnboardingAccessoryPill(title: accessory)
                }
            }

            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OnboardingSelectionRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let isSelected: Bool
    var tint: Color = VenusTheme.primary
    let action: () -> Void

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                action()
            }
        } label: {
            Group {
                if isSelected {
                    rowContent
                        .background(
                            LinearGradient(
                                colors: [tint, tint.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
                        )
                        .shadow(color: tint.opacity(0.18), radius: 16, x: 0, y: 10)
                } else {
                    rowContent
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var rowContent: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.22) : tint.opacity(0.16))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(isSelected ? .white : tint)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(isSelected ? .white : VenusTheme.text)

                Text(detail)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.85) : VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

struct OnboardingVisualPalette {
    let accent: Color
    let secondary: Color
    let tertiary: Color
    let moods: [MoodType]

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent,
                secondary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.gray.opacity(0.35),
                Color.gray.opacity(0.22)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func forStep(_ step: Int) -> OnboardingVisualPalette {
        switch step {
        case 0:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.accentPurple,
                moods: [.happy, .calm, .tired]
            )
        case 1:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentGreen,
                tertiary: VenusTheme.accentBlue,
                moods: [.happy, .energetic, .calm]
            )
        case 2:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentBlue,
                secondary: VenusTheme.accentPurple,
                tertiary: VenusTheme.primary,
                moods: [.calm, .tired, .happy]
            )
        case 3:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentBlue,
                secondary: VenusTheme.primary,
                tertiary: VenusTheme.accentPurple,
                moods: [.calm, .happy, .tired]
            )
        case 4:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentGreen,
                secondary: VenusTheme.primary,
                tertiary: VenusTheme.accentBlue,
                moods: [.happy, .calm, .energetic]
            )
        case 5:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentPurple,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.primary,
                moods: [.tired, .calm, .happy]
            )
        case 6:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentOrange,
                secondary: VenusTheme.accentPink,
                tertiary: VenusTheme.primary,
                moods: [.energetic, .happy, .calm]
            )
        case 7:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentPink,
                secondary: VenusTheme.accentOrange,
                tertiary: VenusTheme.accentPurple,
                moods: [.sad, .calm, .happy]
            )
        default:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentOrange,
                secondary: VenusTheme.accentPink,
                tertiary: VenusTheme.primary,
                moods: [.stressed, .calm, .happy]
            )
        }
    }
}

struct OnboardingAnimatedBackground: View {
    let palette: OnboardingVisualPalette
    var isAnimated: Bool = true

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: palette.accent,
                secondaryAccent: palette.secondary,
                tertiaryAccent: palette.tertiary,
                isAnimated: isAnimated
            )
            OnboardingWavesOverlay(
                tint: palette.accent,
                secondary: palette.secondary,
                tertiary: palette.tertiary
            )
        }
    }
}

struct OnboardingWavesOverlay: View {
    var tint: Color = VenusTheme.primary
    var secondary: Color = VenusTheme.accentBlue
    var tertiary: Color = VenusTheme.accentPurple

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: false)) { context in
            Canvas { canvasContext, size in
                let time = context.date.timeIntervalSinceReferenceDate
                drawWaves(in: canvasContext, size: size, time: time)
            }
        }
        .opacity(colorScheme == .dark ? 0.42 : 0.26)
        .blendMode(.softLight)
        .blur(radius: 1.0)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func drawWaves(in context: GraphicsContext, size: CGSize, time: TimeInterval) {
        let baseOpacity: Double = colorScheme == .dark ? 0.12 : 0.08
        let strokeStyle = StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round)

        let wave1 = wavePath(
            size: size,
            baseline: size.height * 0.24,
            amplitude: 16,
            wavelength: max(220, size.width * 0.9),
            phase: time * 0.9
        )
        context.stroke(wave1, with: .color(tint.opacity(baseOpacity)), style: strokeStyle)

        let wave2 = wavePath(
            size: size,
            baseline: size.height * 0.54,
            amplitude: 12,
            wavelength: max(260, size.width * 1.2),
            phase: time * 0.72
        )
        context.stroke(wave2, with: .color(secondary.opacity(baseOpacity * 0.9)), style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round))

        let wave3 = wavePath(
            size: size,
            baseline: size.height * 0.74,
            amplitude: 10,
            wavelength: max(300, size.width * 1.35),
            phase: time * 0.6
        )
        context.stroke(wave3, with: .color(tertiary.opacity(baseOpacity * 0.75)), style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round))

        var fill = wave2
        fill.addLine(to: CGPoint(x: size.width, y: size.height))
        fill.addLine(to: CGPoint(x: 0, y: size.height))
        fill.closeSubpath()
        context.fill(fill, with: .color(tint.opacity(colorScheme == .dark ? 0.045 : 0.035)))
    }

    private func wavePath(
        size: CGSize,
        baseline: CGFloat,
        amplitude: CGFloat,
        wavelength: CGFloat,
        phase: TimeInterval
    ) -> Path {
        var path = Path()
        let twoPi = Double.pi * 2
        let step = max(10, size.width / 48)

        path.move(to: CGPoint(x: 0, y: baseline))
        var x: CGFloat = 0
        while x <= size.width + step {
            let progress = Double(x / wavelength) * twoPi
            let y = baseline + CGFloat(sin(progress + phase)) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
            x += step
        }
        return path
    }
}

struct OnboardingMascotBackdrop: View {
    let palette: OnboardingVisualPalette

    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    var body: some View {
        OnboardingAmbientOrb(mood: palette.moods.first, size: 236)
            .opacity(colorScheme == .dark ? 0.26 : 0.18)
            .blur(radius: 6)
            .scaleEffect(animate ? 1.04 : 0.96)
            .offset(x: animate ? 156 : 128, y: animate ? -18 : 2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, 10)
            .allowsHitTesting(false)
        .onAppear {
            guard !animate else { return }
            withAnimation(.easeInOut(duration: 7.0).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}

private struct OnboardingAmbientOrb: View {
    let mood: MoodType?
    var size: CGFloat = 220

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

    var body: some View {
        ZStack {
            Circle()
                .fill(orbGradient)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: size * 0.56, height: size * 0.34)
                .blur(radius: 12)
                .offset(x: -size * 0.14, y: -size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

struct OnboardingPressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
