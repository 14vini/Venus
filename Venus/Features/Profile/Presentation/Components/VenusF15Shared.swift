//
//  VenusF15Shared.swift
//  Venus
//
//  F15 — pequenos componentes compartilhados por Galáxia, Perfil e Ajustes.
//

import SwiftUI
import UIKit

// MARK: - Soft Background

/// Gradiente suave azul → lilás → rosa (versão noturna de baixo contraste).
/// Substitui o fundo neutro antigo nas telas de Perfil, Ajustes e Galáxia.
struct VenusSoftGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                stops: colorScheme == .dark ? darkStops : lightStops,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.40),
                    Color.clear
                ],
                center: UnitPoint(x: 0.24, y: 0.06),
                startRadius: 0,
                endRadius: 260
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var lightStops: [Gradient.Stop] {
        [
            .init(color: Color(hex: "CBDDF5"), location: 0.0),
            .init(color: Color(hex: "E3DCF4"), location: 0.42),
            .init(color: Color(hex: "F2DDEB"), location: 0.74),
            .init(color: Color(hex: "FBE7E4"), location: 1.0)
        ]
    }

    private var darkStops: [Gradient.Stop] {
        [
            .init(color: Color(hex: "202B44"), location: 0.0),
            .init(color: Color(hex: "312942"), location: 0.46),
            .init(color: Color(hex: "3C2A3E"), location: 0.78),
            .init(color: Color(hex: "2C2231"), location: 1.0)
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
