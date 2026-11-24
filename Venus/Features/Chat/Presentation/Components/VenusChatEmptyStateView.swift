//
//  VenusChatEmptyStateView.swift
//  Venus
//
//  Estado vazio do Chat: a Venus em destaque, uma saudação curta e sugestões em
//  pílulas que já disparam a pergunta. Sem parágrafos, sem instruções longas.
//

import SwiftUI

struct VenusChatEmptyStateView: View {
    /// Envia a sugestão como se o usuário tivesse digitado e tocado em enviar.
    let onSuggestion: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var didAppear = false

    private var isDark: Bool { colorScheme == .dark }

    private let suggestions: [String] = [
        "Como estou me sentindo hoje?",
        "Quero planejar meu dia",
        "Preciso de uma pausa",
        "O que aprendi sobre mim?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VenusMoodOrb(
                state: .welcoming,
                size: 132,
                showHands: false,
                showShadow: false,
                isInteractive: true
            )
            .scaleEffect(didAppear ? 1 : 0.92)
            .opacity(didAppear ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.78), value: didAppear)

            VStack(spacing: 8) {
                Text("Olá, eu sou a Venus.")
                    .font(.system(size: 27, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Text("Como posso te ajudar hoje?")
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .padding(.top, 12)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 8)
            .animation(.spring(response: 0.55, dampingFraction: 0.84).delay(0.08), value: didAppear)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 156), spacing: 10)],
                spacing: 10
            ) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        VenusChatHaptics.light()
                        onSuggestion(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 13, weight: .light, design: .rounded))
                            .foregroundStyle(VenusTheme.text)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(VenusChatVisualStyle.suggestionFill(isDark: isDark))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(VenusChatVisualStyle.suggestionBorder(isDark: isDark), lineWidth: 0.6)
                            )
                            .contentShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(VenusChatSpringPressStyle())
                    .accessibilityLabel(suggestion)
                }
            }
            .padding(.top, 28)
            .frame(maxWidth: 480)
            .opacity(didAppear ? 1 : 0)
            .offset(y: didAppear ? 0 : 12)
            .animation(.spring(response: 0.55, dampingFraction: 0.84).delay(0.14), value: didAppear)

            Spacer(minLength: 24)
        }
        .frame(maxWidth: .infinity)
        .onAppear { didAppear = true }
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusChatEmptyStateView { _ in }
    }
}
