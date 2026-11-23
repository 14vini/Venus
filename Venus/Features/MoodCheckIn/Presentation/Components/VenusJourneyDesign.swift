//
//  VenusJourneyDesign.swift
//  Venus
//
//  Linguagem visual da "jornada": gradiente suave lilás→rosa→branco,
//  progresso em arco, tipografia fina e CTA escuro em pill.
//
//  F32: os tokens e componentes reutilizáveis vivem em `VenusJourneyStyle`.
//  Este arquivo preserva os nomes públicos consumidos pelo check-in.
//

import SwiftUI

// MARK: - Paleta da jornada

struct VenusJourneyPalette {
    let accent: Color
    let secondary: Color
    let tertiary: Color
    let moods: [MoodType]

    var glow: Color { secondary }

    var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [accent, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var disabledGradient: LinearGradient {
        LinearGradient(
            colors: [Color.gray.opacity(0.28), Color.gray.opacity(0.16)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let lilac = VenusJourneyStyle.lilac
    static let rose = VenusJourneyStyle.rose
    static let sky = VenusJourneyStyle.sky

    static func forStep(_ step: Int, totalSteps: Int) -> VenusJourneyPalette {
        let palettes = [
            VenusJourneyPalette(accent: lilac, secondary: rose, tertiary: sky, moods: [.happy, .calm, .tired]),
            VenusJourneyPalette(accent: sky, secondary: lilac, tertiary: rose, moods: [.calm, .tired, .happy]),
            VenusJourneyPalette(accent: rose, secondary: sky, tertiary: lilac, moods: [.happy, .calm, .energetic]),
            VenusJourneyPalette(accent: lilac, secondary: sky, tertiary: rose, moods: [.tired, .calm, .happy]),
            VenusJourneyPalette(accent: rose, secondary: lilac, tertiary: sky, moods: [.stressed, .calm, .happy])
        ]
        guard totalSteps > 0 else { return palettes[0] }
        return palettes[min(max(step - 1, 0), palettes.count - 1)]
    }
}

// MARK: - Fundo da jornada

struct VenusJourneyBackground: View {
    let palette: VenusJourneyPalette
    var isAnimated: Bool = true

    var body: some View {
        VenusJourneyBreathingBackground(
            accent: palette.accent,
            secondary: VenusJourneyPalette.rose,
            isAnimated: isAnimated
        )
    }
}

// MARK: - Progresso em arco

struct VenusJourneyProgress: View {
    let currentStep: Int
    let totalSteps: Int
    var tint: Color = VenusJourneyPalette.lilac
    var caption: String? = nil

    var body: some View {
        VenusJourneyProgressArc(
            currentStep: currentStep,
            totalSteps: totalSteps,
            tint: tint,
            caption: caption
        )
    }
}

// MARK: - Cabeçalho da etapa

struct VenusJourneyStepHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var tint: Color = VenusJourneyPalette.lilac

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular, in: Circle())
                }

                Text(eyebrow.uppercased())
                    .venusJourneyText(.eyebrow(tint: tint))
            }

            Text(title)
                .venusJourneyText(.title)

            if let subtitle {
                Text(subtitle)
                    .venusJourneyText(.subtitle)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Linha de seleção

struct VenusJourneySelectionRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let isSelected: Bool
    var tint: Color = VenusJourneyPalette.lilac
    let action: () -> Void

    var body: some View {
        Button {
            VenusJourneyHaptic.selection()
            withAnimation(VenusJourneyStyle.selection) {
                action()
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.24) : tint.opacity(0.16))
                        .frame(width: 42, height: 42)

                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(isSelected ? .white : tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(isSelected ? .white : VenusTheme.text)

                    Text(detail)
                        .font(.system(.caption, design: .rounded).weight(.medium))
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [tint, tint.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                in: RoundedRectangle(cornerRadius: VenusJourneyStyle.cardRadius, style: .continuous)
            )
            .glassEffect(
                isSelected ? .clear : .regular.interactive(),
                in: RoundedRectangle(cornerRadius: VenusJourneyStyle.cardRadius, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: VenusJourneyStyle.cardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - CTA escuro em pill

struct VenusJourneyPrimaryButtonLabel: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false

    var body: some View {
        VenusJourneyCTAPill(
            title: title,
            systemImage: systemImage,
            isLoading: isLoading
        )
    }
}

// MARK: - Estilo de toque suave

struct VenusJourneyPressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.975

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(VenusJourneyStyle.press, value: configuration.isPressed)
    }
}

// MARK: - Cartão de vidro líquido

struct VenusJourneyGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = VenusJourneyStyle.cardRadius
    var interactive: Bool = false

    func body(content: Content) -> some View {
        content.modifier(
            VenusJourneyCardModifier(
                cornerRadius: cornerRadius,
                interactive: interactive
            )
        )
    }
}

extension View {
    func venusJourneyGlassCard(
        cornerRadius: CGFloat = VenusJourneyStyle.cardRadius,
        interactive: Bool = false
    ) -> some View {
        modifier(VenusJourneyGlassCardModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}
