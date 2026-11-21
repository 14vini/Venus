//
//  VenusChatVisualStyle.swift
//  Venus
//
//  Paleta suave e local do Chat (azul → lilás → rosa), alinhada à linguagem
//  visual do restante do app. Fica restrita à Presentation do Chat.
//

import SwiftUI

// MARK: - Paleta

enum VenusChatVisualStyle {
    /// Gradiente de fundo do chat: azul claro → lilás → rosa bem suave.
    static func background(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [Color(hex: "111827"), Color(hex: "1D1A30"), Color(hex: "291C2C")]
                : [Color(hex: "E9F2FC"), Color(hex: "F3EBF8"), Color(hex: "FCEBF0")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Brilho ambiente discreto, apenas para dar profundidade ao gradiente.
    static func ambientGlow(isDark: Bool) -> RadialGradient {
        RadialGradient(
            colors: [
                (isDark ? Color(hex: "6B4E86") : Color(hex: "F6C7DF"))
                    .opacity(isDark ? 0.20 : 0.42),
                Color.clear
            ],
            center: .bottomTrailing,
            startRadius: 10,
            endRadius: 340
        )
    }

    /// Tint dos balões em Liquid Glass — leve o suficiente para manter o texto legível.
    static func bubbleTint(isFromUser: Bool, isDark: Bool) -> Color {
        if isFromUser {
            return isDark
                ? Color(hex: "2E6E9E").opacity(0.34)
                : Color(hex: "BFE0F4").opacity(0.48)
        }
        return isDark
            ? Color.white.opacity(0.05)
            : Color.white.opacity(0.38)
    }

    /// Tinta do cartão de planejamento e dos painéis auxiliares.
    static func panelTint(isDark: Bool) -> Color {
        isDark
            ? Color(hex: "6B4E86").opacity(0.18)
            : Color(hex: "EBD9F3").opacity(0.14)
    }

    /// Aura do mascot em estado de espera.
    static let aura = Color(hex: "AFC9F0")
}

// MARK: - Fundo

/// Fundo gradiente suave do chat, sem sombras e sem material fingindo vidro.
struct VenusChatBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            VenusChatVisualStyle.background(isDark: colorScheme == .dark)
                .ignoresSafeArea()

            VenusChatVisualStyle.ambientGlow(isDark: colorScheme == .dark)
                .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}
