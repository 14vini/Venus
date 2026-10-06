//
//  OnboardingComponents.swift
//  Venus
//
//  Created by Kaua on 26/03/26.
//

import SwiftUI

struct OnboardingStepHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var tint: Color = VenusTheme.primary
    var accessory: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
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
                                colors: [tint, tint.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .shadow(color: tint.opacity(0.18), radius: 14, x: 0, y: 8)
                } else {
                    rowContent
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                    .fill(isSelected ? Color.white.opacity(0.22) : tint.opacity(0.14))
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(isSelected ? .white : tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(isSelected ? .white : VenusTheme.text)

                Text(detail)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(isSelected ? .white.opacity(0.88) : VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

struct OnboardingVisualPalette {
    let accent: Color
    let secondary: Color
    let tertiary: Color
    let moods: [MoodType]

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [accent, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray.opacity(0.35), Color.gray.opacity(0.22)],
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
                accent: VenusTheme.accentBlue,
                secondary: VenusTheme.primary,
                tertiary: VenusTheme.accentPurple,
                moods: [.calm, .happy, .tired]
            )
        case 2:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentPurple,
                secondary: VenusTheme.accentOrange,
                tertiary: VenusTheme.primary,
                moods: [.calm, .stressed, .sad]
            )
        case 3:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentBlue,
                secondary: VenusTheme.accentGreen,
                tertiary: VenusTheme.primary,
                moods: [.calm, .happy, .energetic]
            )
        case 4:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentPink,
                tertiary: VenusTheme.accentOrange,
                moods: [.happy, .energetic, .calm]
            )
        case 5:
            return OnboardingVisualPalette(
                accent: VenusTheme.accentOrange,
                secondary: VenusTheme.accentPink,
                tertiary: VenusTheme.primary,
                moods: [.calm, .happy, .energetic]
            )
        case 6:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.accentPurple,
                moods: [.happy, .calm, .energetic]
            )
        case 7:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentGreen,
                tertiary: VenusTheme.accentBlue,
                moods: [.happy, .calm, .energetic]
            )
        default:
            return OnboardingVisualPalette(
                accent: VenusTheme.primary,
                secondary: VenusTheme.accentBlue,
                tertiary: VenusTheme.accentPurple,
                moods: [.happy, .calm, .tired]
            )
        }
    }
}

struct OnboardingAnimatedBackground: View {
    let palette: OnboardingVisualPalette
    var isAnimated: Bool = true

    var body: some View {
        VenusReadingBackground(
            accent: palette.accent,
            secondaryAccent: palette.secondary,
            tertiaryAccent: palette.tertiary,
            isAnimated: isAnimated
        )
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
