//
//  VenusF15Shared.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//
//  F15 — pequenos componentes compartilhados por Galáxia, Perfil e Ajustes.
//  F36 — linguagem visual da jornada mantida localmente (sem depender da F32).
//

import SwiftUI
import UIKit

// MARK: - Paleta local da jornada (F36)

/// Tons lilás / rosa / céu usados por Galáxia, Perfil e Ajustes.
/// Ficam aqui para esta frente não depender do design system criado na F32.
enum VenusF36Palette {
    static let lilac = adaptiveColor(light: "B39CE8", dark: "C6B4F2")
    static let rose = adaptiveColor(light: "F0A6BE", dark: "E794B0")
    static let sky = adaptiveColor(light: "9FC6F2", dark: "82AEEA")

    private static func adaptiveColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

// MARK: - Soft Background

/// Gradiente suave lilás → rosa → branco, com respiração lenta.
/// A versão noturna usa tons profundos. Substitui o fundo neutro antigo
/// nas telas de Perfil, Ajustes e Galáxia.
struct VenusSoftGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            LinearGradient(
                stops: colorScheme == .dark ? darkStops : lightStops,
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [
                    VenusF36Palette.lilac.opacity(colorScheme == .dark ? 0.26 : 0.42),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 20,
                endRadius: 340
            )
            .scaleEffect(isBreathing ? 1.10 : 1)
            .animation(
                .easeInOut(duration: 8).repeatForever(autoreverses: true),
                value: isBreathing
            )

            RadialGradient(
                colors: [
                    VenusF36Palette.rose.opacity(colorScheme == .dark ? 0.20 : 0.36),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 320
            )
            .scaleEffect(isBreathing ? 0.94 : 1)
            .animation(
                .easeInOut(duration: 10).repeatForever(autoreverses: true),
                value: isBreathing
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { isBreathing = true }
    }

    private var lightStops: [Gradient.Stop] {
        [
            .init(color: Color(hex: "DCD0F4"), location: 0.0),
            .init(color: Color(hex: "F4CBD8"), location: 0.48),
            .init(color: Color(hex: "FDF8FB"), location: 1.0)
        ]
    }

    private var darkStops: [Gradient.Stop] {
        [
            .init(color: Color(hex: "2B2340"), location: 0.0),
            .init(color: Color(hex: "3A2639"), location: 0.48),
            .init(color: Color(hex: "17131F"), location: 1.0)
        ]
    }
}

// MARK: - Haptic Binding

/// Envolve uma Binding existente e dispara um haptic leve apenas quando o valor muda.
/// Preserva a origem do dado (@State, @AppStorage ou @Environment) intacta.
func venusHapticBinding<Value: Equatable>(
    _ binding: Binding<Value>,
    style: UIImpactFeedbackGenerator.FeedbackStyle = .light
) -> Binding<Value> {
    Binding(
        get: { binding.wrappedValue },
        set: { newValue in
            guard newValue != binding.wrappedValue else { return }
            UIImpactFeedbackGenerator(style: style).impactOccurred()
            binding.wrappedValue = newValue
        }
    )
}

// MARK: - Arco de progresso (F36)

/// Curva suave usada nos cabeçalhos da jornada.
struct VenusF36JourneyArcShape: Shape {
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

/// Pontos ao longo do arco. `current` é 1-based; zero significa "sem marco ativo".
struct VenusF36JourneyDots: View {
    let count: Int
    var current: Int = 0
    var tint: Color = VenusF36Palette.lilac
    var caption: String? = nil

    @Environment(\.colorScheme) private var colorScheme

    private var safeCount: Int { max(count, 1) }

    private var progress: CGFloat {
        guard safeCount > 1 else { return 1 }
        return CGFloat(min(max(current, 0), safeCount)) / CGFloat(safeCount - 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                let rect = geometry.frame(in: .local)

                ZStack {
                    VenusF36JourneyArcShape()
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.16) : Color.white.opacity(0.60),
                            lineWidth: 1.5
                        )

                    VenusF36JourneyArcShape()
                        .trim(from: 0, to: progress)
                        .stroke(tint.opacity(0.95), lineWidth: 2.5)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: progress)

                    ForEach(0..<safeCount, id: \.self) { index in
                        let isCurrent = current > 0 && index == current - 1

                        Circle()
                            .fill(dotFill(for: index))
                            .frame(width: isCurrent ? 11 : 7, height: isCurrent ? 11 : 7)
                            .shadow(
                                color: isCurrent ? tint.opacity(0.55) : .clear,
                                radius: isCurrent ? 8 : 0,
                                y: isCurrent ? 1 : 0
                            )
                            .position(point(at: index, in: rect))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
                    }
                }
            }
            .frame(height: 32)

            if let caption {
                Text(caption)
                    .font(.system(size: 10, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: caption)
            }
        }
    }

    private func dotFill(for index: Int) -> Color {
        if current > 0 && index == current - 1 { return .white }
        if current > 0 && index < current - 1 { return tint.opacity(0.75) }
        return colorScheme == .dark ? Color.white.opacity(0.28) : Color.white.opacity(0.85)
    }

    private func point(at index: Int, in rect: CGRect) -> CGPoint {
        let t = safeCount == 1 ? 0.5 : CGFloat(index) / CGFloat(safeCount - 1)
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

// MARK: - Cabeçalho da jornada (F36)

/// Cabeçalho com arco e pontos, tipografia fina e negrito apenas no eyebrow.
struct VenusF36JourneyHeader: View {
    let eyebrow: String
    let title: String
    var subtitle: String? = nil
    var dotCount: Int = 5
    var currentDot: Int = 1
    var dotCaption: String? = nil
    var tint: Color = VenusF36Palette.lilac

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(eyebrow.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.6)
                .foregroundStyle(tint)

            VenusF36JourneyDots(
                count: dotCount,
                current: currentDot,
                tint: tint,
                caption: dotCaption
            )

            Text(title)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CTA escuro em pill (F36)

/// Botão principal escuro em cápsula, com resposta spring ao toque.
struct VenusF36DarkPillStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule(style: .continuous).fill(Color(hex: "241E2B")))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
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
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
