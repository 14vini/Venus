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
    /// Inset horizontal compartilhado por header, composer e células: garante que
    /// a borda da bolha do usuário e a do campo de texto estejam na mesma linha.
    static let chromeHorizontalInset: CGFloat = 16
    /// Teto de leitura confortável para um balão em telas largas (iPad/paisagem).
    static let bubbleMaxWidth: CGFloat = 560

    // MARK: - Shell (F39)

    /// Largura máxima da coluna de conversa. Centralizada: a leitura fica
    /// confortável em iPad e em iPhone em paisagem sem perder o layout F30.
    static let conversationMaxWidth: CGFloat = 760
    /// Largura máxima do cabeçalho e do composer — alinhados à conversa.
    static let chromeMaxWidth: CGFloat = 780
    /// Raio do composer (mais generoso que o dos controles pequenos).
    static let composerRadius: CGFloat = 26

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

    /// Superfície do composer — a segunda (e última) superfície elevada da tela,
    /// discreta o suficiente para não competir com o balão.
    static func composerFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.07) : Color.white.opacity(0.60)
    }

    static func composerBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.72)
    }

    /// Pílulas de sugestão do estado vazio: vidro leve, sem borda dura.
    static func suggestionFill(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.56)
    }

    static func suggestionBorder(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.12) : Color.white.opacity(0.70)
    }

    /// Aura do mascot em estado de espera.
    static var aura: Color { lilac }

    // MARK: - Texto

    /// Placeholder do composer. Contraste reforçado sobre a cápsula clara.
    static let composerPlaceholder = "Digite aqui"

    /// Timestamp discreto, mas legível sobre o lilás/rosa do fundo.
    static func timestampColor(isDark: Bool) -> Color {
        VenusTheme.text.opacity(isDark ? 0.74 : 0.72)
    }

    /// Cor do placeholder — mais escura que o cinza padrão do sistema.
    static func placeholderColor(isDark: Bool) -> Color {
        isDark ? VenusTheme.text.opacity(0.70) : VenusTheme.textSecondary
    }

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

// MARK: - Feedback (F39)

/// Haptics do shell — curtos e com propósito, nunca repetidos em cascata.
enum VenusChatHaptics {
    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Pressagem com resposta spring, compartilhada por header, composer e
/// estado vazio. Substitui o estilo privado que vivia em `VenusChatView`.
struct VenusChatSpringPressStyle: ButtonStyle {
    var scale: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
