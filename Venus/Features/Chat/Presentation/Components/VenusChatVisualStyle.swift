//
//  VenusChatVisualStyle.swift
//  Venus
//
//  Paleta e métricas locais do Chat — linguagem visual da jornada
//  (lilás → rosa → branco, tons profundos no escuro), aplicada sem depender
//  de nenhuma API da F32. Fica restrita à Presentation do Chat.
//
//  Hierarquia: o balão é a ÚNICA superfície com material de vidro. Todo o resto
//  (cabeçalho, detalhes, histórico, insights) usa preenchimento plano e borda
//  sutil — sem empilhamento de glass effects.
//

import SwiftUI

// MARK: - Métricas

enum VenusChatVisualStyle {
    /// Raio único dos balões, com curva contínua (sem arcos costurados).
    static let bubbleRadius: CGFloat = 24
    /// Raio dos cartões grandes (proposta, insights, histórico).
    static let cardRadius: CGFloat = 28
    /// Raio dos controles pequenos (pílulas, linhas de detalhes).
    static let controlRadius: CGFloat = 16
    /// Fração da largura disponível ocupada por um balão (preserva o layout F30).
    static let bubbleWidthRatio: CGFloat = 0.82

    // MARK: - Cores da jornada

    /// Lilás da jornada — acento principal do chat.
    static let lilac = journeyColor(light: "#B39CE8", dark: "#C6B4F2")
    /// Rosa da jornada — calor dos balões e do brilho ambiente.
    static let rose = journeyColor(light: "#F0A6BE", dark: "#E794B0")
    /// Céu da jornada — terceiro ponto do arco.
    static let sky = journeyColor(light: "#9FC6F2", dark: "#82AEEA")

    /// Acento usado por ícones e detalhes de interface.
    static let accent = lilac

    /// Pílula escura dos controles de ação (CTA da linguagem jornada).
    static func darkPill(isDark: Bool) -> Color {
        isDark ? Color(hex: "3B3442") : Color(hex: "241E2B")
    }

    private static func journeyColor(light: String, dark: String) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    // MARK: - Fundo

    /// Gradiente suave lilás → rosa → branco (tons profundos no escuro).
    static func background(isDark: Bool) -> LinearGradient {
        LinearGradient(
            colors: isDark
                ? [Color(hex: "2B2340"), Color(hex: "3A2639"), Color(hex: "17131F")]
                : [Color(hex: "DCD0F4"), Color(hex: "F4CBD8"), Color(hex: "FDF8FB")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Brilho ambiente discreto no canto superior, em lilás.
    static func ambientGlow(isDark: Bool) -> RadialGradient {
        RadialGradient(
            colors: [
                lilac.opacity(isDark ? 0.24 : 0.38),
                Color.clear
            ],
            center: .topLeading,
            startRadius: 12,
            endRadius: 340
        )
    }

    /// Segundo brilho ambiente, em rosa, no canto inferior.
    static func ambientRoseGlow(isDark: Bool) -> RadialGradient {
        RadialGradient(
            colors: [
                rose.opacity(isDark ? 0.18 : 0.34),
                Color.clear
            ],
            center: .bottomTrailing,
            startRadius: 20,
            endRadius: 320
        )
    }

    // MARK: - Superfícies

    /// Tint dos balões — a única superfície com material da tela.
    /// Mais leve e arejado: lilás suave para o usuário, branco quase translúcido
    /// para a Venus.
    static func bubbleTint(isFromUser: Bool, isDark: Bool) -> Color {
        if isFromUser {
            return isDark
                ? lilac.opacity(0.30)
                : lilac.opacity(0.34)
        }
        return isDark
            ? Color.white.opacity(0.07)
            : Color.white.opacity(0.58)
    }

    /// Preenchimento plano usado por cartões e controles sem vidro.
    static func surfaceFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.52)
    }

    /// Borda quase invisível que dá contorno aos cartões sem material.
    static func surfaceBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.10) : Color.white.opacity(0.62)
    }

    /// Tinta sutil de botões secundários (removida dos cartões grandes).
    static func controlFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.46)
    }

    /// Aura do mascot em estado de espera.
    static var aura: Color { lilac }

    // MARK: - Texto

    /// Rótulo discreto abaixo do último balão de um grupo: "Hoje · 14:32".
    static func timestampLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let day: String
        if calendar.isDateInToday(date) {
            day = "Hoje"
        } else if calendar.isDateInYesterday(date) {
            day = "Ontem"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.dateFormat = "d MMM"
            day = formatter.string(from: date).replacingOccurrences(of: ".", with: "")
        }
        return "\(day) · \(date.formatted(date: .omitted, time: .shortened))"
    }

    /// Última barra antes da exibição: nunca mostrar pensamento, tags internas
    /// ou JSON bruto, mesmo que algo escape do filtro da camada de IA.
    static func displayText(_ raw: String) -> String {
        var text = VenusTextSanitizer.sanitize(raw)

        let labels = [
            "pensamento:", "raciocínio:", "raciocinio:", "reasoning:",
            "análise:", "analise:", "thought:", "thinking:", "chain of thought:"
        ]
        var lines = text
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map(String.init)

        while let first = lines.first {
            let normalized = first
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: Locale(identifier: "pt_BR"))
            if normalized.isEmpty || labels.contains(where: { normalized.hasPrefix($0) }) {
                lines.removeFirst()
            } else {
                break
            }
        }

        text = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return text
    }
}

// MARK: - Fundo

/// Fundo gradiente suave do chat, com respiração lenta — a mesma linguagem da
/// tela de check-in. Sem sombras e sem material fingindo vidro.
struct VenusChatBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isBreathing = false

    var body: some View {
        ZStack {
            VenusChatVisualStyle.background(isDark: colorScheme == .dark)
                .ignoresSafeArea()

            VenusChatVisualStyle.ambientGlow(isDark: colorScheme == .dark)
                .ignoresSafeArea()
                .scaleEffect(isBreathing ? 1.08 : 1)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: isBreathing)

            VenusChatVisualStyle.ambientRoseGlow(isDark: colorScheme == .dark)
                .ignoresSafeArea()
                .scaleEffect(isBreathing ? 0.94 : 1)
                .animation(.easeInOut(duration: 9).repeatForever(autoreverses: true), value: isBreathing)
        }
        .allowsHitTesting(false)
        .onAppear { isBreathing = true }
    }
}
