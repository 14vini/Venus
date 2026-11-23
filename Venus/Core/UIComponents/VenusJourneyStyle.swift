//
//  VenusJourneyStyle.swift
//  Venus
//
//  F32 — sistema visual compartilhado da jornada: paleta lilás/rosa/céu,
//  fundo com respiração lenta, arco de progresso com pontos, CTA escuro em
//  pill, cards de vidro líquido e tipografia fina com negrito seletivo.
//
//  As implementações ficam aqui; VenusJourneyDesign mantém os nomes públicos
//  usados pelo check-in e apenas delega para estes tokens/componentes.
//

import SwiftUI
import UIKit

// MARK: - Tokens da jornada

enum VenusJourneyStyle {
    // Paleta (light + dark definida em VenusTheme)
    static var lilac: Color { VenusTheme.journeyLilac }
    static var rose: Color { VenusTheme.journeyRose }
    static var sky: Color { VenusTheme.journeySky }

    // Geometria
    static let cardRadius: CGFloat = 22
    static let buttonHeight: CGFloat = 52
    static let progressHeight: CGFloat = 32

    // Springs — usados em seleção, toque e troca de etapa
    static var press: Animation { .spring(response: 0.28, dampingFraction: 0.8) }
    static var selection: Animation { .spring(response: 0.32, dampingFraction: 0.84) }
    static var step: Animation { .spring(response: 0.50, dampingFraction: 0.86) }

    // Respiração lenta do fundo
    static var breatheAccent: Animation {
        .easeInOut(duration: 7).repeatForever(autoreverses: true)
    }

    static var breatheGlow: Animation {
        .easeInOut(duration: 9).repeatForever(autoreverses: true)
    }
}

// MARK: - Haptics da jornada

/// Helpers finos para não espalhar `FeedbackGenerator` pelos componentes visuais.
enum VenusJourneyHaptic {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

// MARK: - Fundo com respiração

struct VenusJourneyBreathingBackground: View {
    var accent: Color = VenusJourneyStyle.lilac
    var secondary: Color = VenusJourneyStyle.rose
    var isAnimated: Bool = true

    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    VenusTheme.journeyBackgroundTop,
                    VenusTheme.journeyBackgroundMiddle,
                    VenusTheme.journeyBackgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    accent.opacity(colorScheme == .dark ? 0.24 : 0.38),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 12,
                endRadius: 340
            )
            .scaleEffect(isBreathing ? 1.08 : 1)
            .animation(
                isAnimated ? VenusJourneyStyle.breatheAccent : .default,
                value: isBreathing
            )

            RadialGradient(
                colors: [
                    secondary.opacity(colorScheme == .dark ? 0.18 : 0.34),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .scaleEffect(isBreathing ? 0.94 : 1)
            .animation(
                isAnimated ? VenusJourneyStyle.breatheGlow : .default,
                value: isBreathing
            )
        }
        .ignoresSafeArea()
        .onAppear {
            if isAnimated { isBreathing = true }
        }
    }
}

// MARK: - Arco de progresso

struct VenusJourneyArcShape: Shape {
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

struct VenusJourneyProgressArc: View {
    let currentStep: Int
    let totalSteps: Int
    var tint: Color = VenusJourneyStyle.lilac
    var caption: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotal: Int { max(totalSteps, 1) }
    private var safeCurrent: Int { min(max(currentStep, 1), safeTotal) }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let rect = geometry.frame(in: .local)

                ZStack {
                    VenusJourneyArcShape()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.55),
                            lineWidth: 1.5
                        )

                    VenusJourneyArcShape()
                        .trim(from: 0, to: progress)
                        .stroke(tint.opacity(0.9), lineWidth: 2.5)

                    ForEach(0..<safeTotal, id: \.self) { index in
                        let point = bezierPoint(
                            t: safeTotal == 1 ? 0.5 : CGFloat(index) / CGFloat(safeTotal - 1),
                            in: rect
                        )
                        Circle()
                            .fill(dotFill(for: index))
                            .frame(
                                width: index == safeCurrent - 1 ? 11 : 7,
                                height: index == safeCurrent - 1 ? 11 : 7
                            )
                            .shadow(
                                color: index == safeCurrent - 1 ? tint.opacity(0.55) : .clear,
                                radius: index == safeCurrent - 1 ? 8 : 0,
                                y: index == safeCurrent - 1 ? 1 : 0
                            )
                            .position(point)
                    }
                }
            }
            .frame(height: VenusJourneyStyle.progressHeight)

            if let caption {
                Text(caption)
                    .venusJourneyText(.caption)
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

// MARK: - CTA escuro em pill

struct VenusJourneyCTAPill: View {
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
        .frame(height: VenusJourneyStyle.buttonHeight)
        .background(Capsule(style: .continuous).fill(VenusTheme.journeyCTA))
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

// MARK: - Cards e tipografia da jornada

struct VenusJourneyCardModifier: ViewModifier {
    var cornerRadius: CGFloat = VenusJourneyStyle.cardRadius
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

enum VenusJourneyTextStyle {
    case eyebrow(tint: Color)
    case title
    case subtitle
    case caption
}

struct VenusJourneyTextModifier: ViewModifier {
    let style: VenusJourneyTextStyle

    func body(content: Content) -> some View {
        switch style {
        case .eyebrow(let tint):
            content
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .tracking(1.4)
        case .title:
            content
                .font(.system(size: 30, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
        case .subtitle:
            content
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        case .caption:
            content
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundColor(VenusTheme.textSecondary)
        }
    }
}
