//
//  VenusWelcomeMessage.swift
//  Venus
//
//  Superfície de boas-vindas reutilizável: Venus acolhedora, saudação curta e
//  sugestões no vocabulário da Home. Coerente com o estado vazio do chat, mas
//  independente dele — nenhum ponto de uso conflitante (hoje só preview).
//
//  Sem GeometryReader/fixedSize na raiz: altura intrínseca e largura limitada.
//

import SwiftUI

struct VenusWelcomeMessage: View {
    /// Chamada quando o usuário escolhe uma das sugestões.
    var onSuggestion: (String) -> Void = { _ in }

    @Environment(\.colorScheme) private var colorScheme

    /// Textos curtos, no vocabulário redondo que já funciona no onboarding.
    private let suggestions: [String] = [
        "Quero acalmar a mente",
        "Me ajude a respirar melhor",
        "Vamos organizar o meu dia"
    ]

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(VenusChatVisualStyle.aura.opacity(isDark ? 0.16 : 0.24))
                    .frame(width: 126, height: 126)
                    .blur(radius: 16)

                VenusMoodOrb(
                    mood: .happy,
                    state: .welcoming,
                    size: 100,
                    showShadow: false,
                    isInteractive: false
                )
            }
            .frame(height: 126)
            .accessibilityLabel("Venus")

            VStack(spacing: 6) {
                Text("Oi, eu sou a Venus")
                    .font(.system(size: 26, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Text("Como posso cuidar de você hoje?")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        onSuggestion(suggestion)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: index == 0 ? "sparkles" : "circle")
                                .font(.system(size: index == 0 ? 12 : 5, weight: .semibold))
                                .foregroundStyle(index == 0 ? .white : VenusChatVisualStyle.lilac)

                            Text(suggestion)
                                .font(.system(size: 14, weight: .light, design: .rounded))
                                .foregroundStyle(index == 0 ? .white : VenusTheme.text)

                            Spacer(minLength: 4)

                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(index == 0 ? .white.opacity(0.8) : VenusTheme.textSecondary)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 50)
                        .background(
                            index == 0
                                ? AnyShapeStyle(VenusChatVisualStyle.darkPill(isDark: isDark))
                                : AnyShapeStyle(VenusChatVisualStyle.controlFill(isDark: isDark))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: 380)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 28)
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusWelcomeMessage { _ in }
    }
}
