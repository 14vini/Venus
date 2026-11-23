//
//  VenusWelcomeMessage.swift
//  Venus
//
//  Estado vazio de verdade: Venus acolhedora, saudação curta e sugestões
//  inspiradas nos modos de bem-estar da Home (textos locais e curtos).
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
        GeometryReader { geometry in
            VStack(spacing: 18) {
                VenusMoodOrb(
                    mood: .happy,
                    state: .welcoming,
                    size: 110,
                    showShadow: false,
                    isInteractive: false
                )
                .frame(height: 122)

                VStack(spacing: 6) {
                    Text("Oi, eu sou a Venus")
                        .font(.system(size: 27, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Text("Como posso cuidar de você hoje?")
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onSuggestion(suggestion)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(VenusTheme.primary)

                                Text(suggestion)
                                    .font(.system(size: 14, weight: .light, design: .rounded))
                                    .foregroundStyle(VenusTheme.text)

                                Spacer(minLength: 4)

                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(VenusTheme.textSecondary)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 50)
                            .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
                            .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
                                    .stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: min(geometry.size.width * 0.86, 380))
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
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
