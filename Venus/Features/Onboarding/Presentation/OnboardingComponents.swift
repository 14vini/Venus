//
//  OnboardingComponents.swift
//  Venus
//
//  Created by Kaua on 26/03/26.
//

import SwiftUI

// MARK: - Jornada: paleta local

/// Paleta da jornada (lilás → rosa → azul), definida aqui para manter o
/// onboarding autocontido e não depender do tema global compartilhado.
struct OnboardingVisualPalette {
    let accent: Color
    let secondary: Color
    let tertiary: Color
    let moods: [MoodType]

    static let lilac = journeyColor(light: "B39CE8", dark: "C6B4F2")
    static let rose = journeyColor(light: "F0A6BE", dark: "E794B0")
    static let sky = journeyColor(light: "9FC6F2", dark: "82AEEA")

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

    static func forStep(_ step: Int) -> OnboardingVisualPalette {
        switch step {
        case 0:
            return OnboardingVisualPalette(accent: lilac, secondary: rose, tertiary: sky, moods: [.happy, .calm, .tired])
        case 1:
            return OnboardingVisualPalette(accent: sky, secondary: lilac, tertiary: rose, moods: [.calm, .happy, .tired])
        case 2:
            return OnboardingVisualPalette(accent: rose, secondary: sky, tertiary: lilac, moods: [.calm, .stressed, .sad])
        case 3:
            return OnboardingVisualPalette(accent: lilac, secondary: sky, tertiary: rose, moods: [.calm, .happy, .energetic])
        case 4:
            return OnboardingVisualPalette(accent: rose, secondary: lilac, tertiary: sky, moods: [.happy, .energetic, .calm])
        case 5:
            return OnboardingVisualPalette(accent: lilac, secondary: rose, tertiary: sky, moods: [.calm, .happy, .energetic])
        default:
            return OnboardingVisualPalette(accent: sky, secondary: lilac, tertiary: rose, moods: [.happy, .calm, .tired])
        }
    }

    private static func journeyColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Jornada: fundo suave

struct OnboardingAnimatedBackground: View {
    let palette: OnboardingVisualPalette
    var isAnimated: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: baseColors,
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.42),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 360
            )
            .scaleEffect(isBreathing ? 1.08 : 1)
            .animation(
                isAnimated ? .easeInOut(duration: 7).repeatForever(autoreverses: true) : .default,
                value: isBreathing
            )

            RadialGradient(
                colors: [
                    OnboardingVisualPalette.rose.opacity(colorScheme == .dark ? 0.18 : 0.34),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 340
            )
            .scaleEffect(isBreathing ? 0.94 : 1)
            .animation(
                isAnimated ? .easeInOut(duration: 9).repeatForever(autoreverses: true) : .default,
                value: isBreathing
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            if isAnimated { isBreathing = true }
        }
    }

    private var baseColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(hex: "2B2340"),
                Color(hex: "3A2639"),
                Color(hex: "17131F")
            ]
        }
        return [
            Color(hex: "DCD0F4"),
            Color(hex: "F4CBD8"),
            Color(hex: "FDF8FB")
        ]
    }
}

// MARK: - Jornada: progresso em arco

private struct OnboardingJourneyArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = 6
        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
        path.addCurve(
            to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset),
            control1: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + 2),
            control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + 2)
        )
        return path
    }
}

struct OnboardingJourneyProgress: View {
    let currentStep: Int
    var totalSteps: Int = 6
    var tint: Color = OnboardingVisualPalette.lilac

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotal: Int { max(totalSteps, 1) }
    private var activeIndex: Int { min(max(currentStep, 0), safeTotal - 1) }
    private var progress: CGFloat {
        safeTotal <= 1 ? 1 : CGFloat(activeIndex) / CGFloat(safeTotal - 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.frame(in: .local)

            ZStack {
                OnboardingJourneyArc()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.60),
                        lineWidth: 1.5
                    )

                OnboardingJourneyArc()
                    .trim(from: 0, to: progress)
                    .stroke(tint.opacity(0.92), lineWidth: 2.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.82), value: progress)

                ForEach(0..<safeTotal, id: \.self) { index in
                    let point = arcPoint(t: safeTotal == 1 ? 0.5 : CGFloat(index) / CGFloat(safeTotal - 1), in: rect)
                    Circle()
                        .fill(dotFill(for: index))
                        .frame(width: index == activeIndex ? 11 : 7, height: index == activeIndex ? 11 : 7)
                        .shadow(
                            color: index == activeIndex ? tint.opacity(0.55) : .clear,
                            radius: index == activeIndex ? 8 : 0,
                            y: index == activeIndex ? 1 : 0
                        )
                        .position(point)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: activeIndex)
                }
            }
        }
        .frame(height: 32)
    }

    private func dotFill(for index: Int) -> Color {
        if index == activeIndex { return .white }
        if index < activeIndex { return tint.opacity(0.72) }
        return colorScheme == .dark ? Color.white.opacity(0.28) : Color.white.opacity(0.78)
    }

    private func arcPoint(t: CGFloat, in rect: CGRect) -> CGPoint {
        let inset: CGFloat = 6
        let p0 = CGPoint(x: rect.minX + inset, y: rect.maxY - inset)
        let p1 = CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + 2)
        let p2 = CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + 2)
        let p3 = CGPoint(x: rect.maxX - inset, y: rect.maxY - inset)
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x,
            y: mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        )
    }
}

/// Cabeçalho de jornada: "cada passo importa" acima do arco de progresso.
struct OnboardingJourneyHeader: View {
    let currentStep: Int
    var totalSteps: Int = 6
    var tint: Color = OnboardingVisualPalette.lilac

    var body: some View {
        VStack(spacing: 6) {
            VStack(spacing: 2) {
                Text("Esta é sua jornada")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .contentTransition(.opacity)

                Text(currentStep >= 5 ? "Cada passo importou." : "Cada passo que você dá importa.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
            }

            OnboardingJourneyProgress(currentStep: currentStep, totalSteps: totalSteps, tint: tint)
                .frame(maxWidth: 280)
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: currentStep)
    }
}

// MARK: - Jornada: CTA escuro em pill

struct OnboardingJourneyCTALabel: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                // Loading é apenas a Venus em pose .thinking — sem palavras e sem pontos.
                VenusMoodOrb(
                    mood: .calm,
                    state: .thinking,
                    size: 34,
                    showFace: true,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
                .frame(width: 34, height: 34)
            } else {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .contentTransition(.opacity)

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .foregroundStyle(Color.white)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
            Capsule(style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "3B3442") : Color(hex: "241E2B"))
        )
        .overlay(
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        )
        .contentShape(Capsule(style: .continuous))
    }
}

// MARK: - Componentes existentes (mantidos)

struct OnboardingStepHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var tint: Color = OnboardingVisualPalette.lilac
    var accessory: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(tint)
                        .frame(width: 30, height: 30)
                        .glassEffect(.regular, in: Circle())
                }

                Text(eyebrow.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .tracking(1.3)
            }

            Text(title)
                .font(.system(size: 30, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3)
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
    var tint: Color = OnboardingVisualPalette.lilac
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
                        .glassEffect(.regular.tint(tint), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
                    .font(.system(.headline, design: .rounded).weight(.semibold))
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

struct OnboardingPressableButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.98

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.78), value: configuration.isPressed)
    }
}
