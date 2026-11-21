//
//  VenusJourneyDesign.swift
//  Venus
//
//  Linguagem visual da "jornada": gradiente suave lilás→rosa→branco,
//  progresso em arco, tipografia fina e CTA escuro em pill.
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

    static let lilac = journeyColor(light: "#B39CE8", dark: "#C6B4F2")
    static let rose = journeyColor(light: "#F0A6BE", dark: "#E794B0")
    static let sky = journeyColor(light: "#9FC6F2", dark: "#82AEEA")

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

    private static func journeyColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Fundo da jornada

struct VenusJourneyBackground: View {
    let palette: VenusJourneyPalette
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
                    palette.accent.opacity(colorScheme == .dark ? 0.24 : 0.38),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 340
            )
            .scaleEffect(isBreathing ? 1.08 : 1)
            .animation(
                isAnimated
                    ? .easeInOut(duration: 7).repeatForever(autoreverses: true)
                    : .default,
                value: isBreathing
            )

            RadialGradient(
                colors: [
                    VenusJourneyPalette.rose.opacity(colorScheme == .dark ? 0.18 : 0.34),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .scaleEffect(isBreathing ? 0.94 : 1)
            .animation(
                isAnimated
                    ? .easeInOut(duration: 9).repeatForever(autoreverses: true)
                    : .default,
                value: isBreathing
            )
        }
        .ignoresSafeArea()
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

// MARK: - Progresso em arco

struct VenusJourneyProgress: View {
    let currentStep: Int
    let totalSteps: Int
    var tint: Color = VenusJourneyPalette.lilac
    var caption: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotal: Int { max(totalSteps, 1) }
    private var safeCurrent: Int { min(max(currentStep, 1), safeTotal) }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let rect = geometry.frame(in: .local)

                ZStack {
                    VenusJourneyArc()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55),
                            lineWidth: 1.5
                        )

                    VenusJourneyArc()
                        .trim(from: 0, to: progress)
                        .stroke(tint.opacity(0.9), lineWidth: 2.5)

                    ForEach(0..<safeTotal, id: \.self) { index in
                        let point = bezierPoint(
                            t: safeTotal == 1 ? 0.5 : CGFloat(index) / CGFloat(safeTotal - 1),
                            in: rect
                        )
                        Circle()
                            .fill(dotFill(for: index))
                            .frame(width: index == safeCurrent - 1 ? 11 : 7,
                                   height: index == safeCurrent - 1 ? 11 : 7)
                            .shadow(
                                color: index == safeCurrent - 1 ? tint.opacity(0.55) : .clear,
                                radius: index == safeCurrent - 1 ? 8 : 0,
                                y: index == safeCurrent - 1 ? 1 : 0
                            )
                            .position(point)
                    }
                }
            }
            .frame(height: 32)

            if let caption {
                Text(caption)
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: caption)
            }
        }
    }

    private var progress: CGFloat {
        safeTotal <= 1 ? 1 : CGFloat(safeCurrent - 1) / CGFloat(safeTotal - 1)
    }

    private func dotFill(for index: Int) -> Color {
        if index == safeCurrent - 1 { return .white }
        if index < safeCurrent - 1 { return tint.opacity(0.7) }
        return colorScheme == .dark ? Color.white.opacity(0.26) : Color.white.opacity(0.75)
    }

    private func bezierPoint(t: CGFloat, in rect: CGRect) -> CGPoint {
        let p0 = CGPoint(x: rect.minX + 6, y: rect.maxY - 6)
        let p1 = CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + 2)
        let p2 = CGPoint(x: rect.minX + rect.width * 0.7, y: rect.minY + 2)
        let p3 = CGPoint(x: rect.maxX - 6, y: rect.maxY - 6)
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x,
            y: mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        )
    }
}

private struct VenusJourneyArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY - 6))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 6, y: rect.maxY - 6),
            control1: CGPoint(x: rect.minX + rect.width * 0.3, y: rect.minY + 2),
            control2: CGPoint(x: rect.minX + rect.width * 0.7, y: rect.minY + 2)
        )
        return path
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
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                    .tracking(1.4)
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
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
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
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .glassEffect(isSelected ? .clear : .regular.interactive(), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
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

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))

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

// MARK: - Estilo de toque suave

struct VenusJourneyPressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.975

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

// MARK: - Cartão de vidro liquído

struct VenusJourneyGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 22
    var interactive: Bool = false

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        if interactive {
            content.glassEffect(.regular.interactive(), in: shape)
        } else {
            content.glassEffect(.regular, in: shape)
        }
    }
}

extension View {
    func venusJourneyGlassCard(cornerRadius: CGFloat = 22, interactive: Bool = false) -> some View {
        modifier(VenusJourneyGlassCardModifier(cornerRadius: cornerRadius, interactive: interactive))
    }
}
