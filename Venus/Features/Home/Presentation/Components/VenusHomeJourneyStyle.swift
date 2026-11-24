//
//  VenusHomeJourneyStyle.swift
//  Venus
//
//  Linguagem visual da jornada aplicada à Home: fundo único off-white com um leve
//  toque lilás no topo (equivalente sóbrio no dark), arco de progresso com pontos,
//  superfícies de vidro e CTA circular em Liquid Glass.
//  Implementado localmente para não depender de outras frentes.
//

import SwiftUI

// MARK: - Paleta local da jornada

/// Cores adaptativas da linguagem visual já aprovada na tela de check-in.
struct VenusHomeJourneyPalette {
    static let lilac = adaptiveColor(light: "B39CE8", dark: "C6B4F2")
    static let rose = adaptiveColor(light: "F0A6BE", dark: "E794B0")
    static let sky = adaptiveColor(light: "9FC6F2", dark: "82AEEA")

    private static func adaptiveColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// MARK: - Fundo único e discreto

/// Um único gradiente suave: off-white quase branco com leve lilás só no topo.
/// No dark, a mesma ideia com tons profundos e sóbrios. Sem blobs e sem respiração:
/// o movimento fica só nos elementos que têm significado (arco, Venus, CTA).
struct VenusHomeJourneyBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            stops: [
                .init(color: topColor, location: 0),
                .init(color: bottomColor, location: 0.42)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var topColor: Color {
        colorScheme == .dark ? Color(hex: "221D2E") : Color(hex: "F2EDFA")
    }

    private var bottomColor: Color {
        colorScheme == .dark ? Color(hex: "14121A") : Color(hex: "FDFBFD")
    }
}

// MARK: - Arco de progresso com pontos

private struct VenusHomeArcShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.maxY - 6))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 6, y: rect.maxY - 6),
            control1: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + 2),
            control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + 2)
        )
        return path
    }
}

/// Arco suave com um ponto por ritual; estados spring preservam a sensação da jornada.
struct VenusHomeProgressArc: View {
    let completed: Int
    let total: Int

    @Environment(\.colorScheme) private var colorScheme

    private var safeTotal: Int { max(total, 1) }
    private var safeCompleted: Int { min(max(completed, 0), safeTotal) }
    private var progress: CGFloat {
        safeTotal <= 1 ? (safeCompleted > 0 ? 1 : 0) : CGFloat(safeCompleted) / CGFloat(safeTotal - 1)
    }

    var body: some View {
        GeometryReader { geometry in
            let rect = geometry.frame(in: .local)

            ZStack {
                VenusHomeArcShape()
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.62),
                        lineWidth: 1.5
                    )

                VenusHomeArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(VenusHomeJourneyPalette.lilac.opacity(0.92), lineWidth: 2.5)
                    .animation(.spring(response: 0.55, dampingFraction: 0.82), value: progress)

                ForEach(0..<safeTotal, id: \.self) { index in
                    let point = arcPoint(
                        t: safeTotal == 1 ? 0.5 : CGFloat(index) / CGFloat(safeTotal - 1),
                        in: rect
                    )
                    let isActive = index == safeCompleted - 1
                    let isDone = index < safeCompleted

                    Circle()
                        .fill(
                            isActive
                                ? Color.white
                                : (isDone
                                   ? VenusHomeJourneyPalette.lilac.opacity(0.75)
                                   : (colorScheme == .dark
                                      ? Color.white.opacity(0.28)
                                      : Color.white.opacity(0.80)))
                        )
                        .frame(width: isActive ? 11 : 7, height: isActive ? 11 : 7)
                        .shadow(
                            color: isActive ? VenusHomeJourneyPalette.lilac.opacity(0.55) : .clear,
                            radius: isActive ? 8 : 0,
                            y: isActive ? 1 : 0
                        )
                        .position(point)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: safeCompleted)
                }
            }
        }
        .frame(height: 32)
        .accessibilityHidden(true)
    }

    private func arcPoint(t: CGFloat, in rect: CGRect) -> CGPoint {
        let p0 = CGPoint(x: rect.minX + 6, y: rect.maxY - 6)
        let p1 = CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + 2)
        let p2 = CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + 2)
        let p3 = CGPoint(x: rect.maxX - 6, y: rect.maxY - 6)
        let mt = 1 - t
        return CGPoint(
            x: mt * mt * mt * p0.x + 3 * mt * mt * t * p1.x + 3 * mt * t * t * p2.x + t * t * t * p3.x,
            y: mt * mt * mt * p0.y + 3 * mt * mt * t * p1.y + 3 * mt * t * t * p2.y + t * t * t * p3.y
        )
    }
}

/// Toque com resposta spring suave — o mesmo princípio da tela de check-in.
struct VenusHomePressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
