//
//  VenusChatHeaderView.swift
//  Venus
//
//  Cabeçalho discreto do Chat — (a) da hierarquia: cabeçalho, mensagens, entrada.
//  Mantém a Venus em foco sem competir com a conversa.
//

import SwiftUI

/// Cabeçalho minimalista do chat: a Venus pequena, nome/estado e o único
/// acesso secundário aos detalhes da conversa.
struct VenusChatHeaderView: View {
    let lens: SelfKnowledgeLens
    let isThinking: Bool
    let hasPendingReview: Bool
    let onBack: () -> Void
    let onShowDetails: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(VenusTheme.text)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Voltar")

            HStack(spacing: 10) {
                VenusMoodOrb(
                    state: isThinking ? .thinking : .idle,
                    size: 30,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text("Venus")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Text(lens.shortTitle)
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                }
            }

            Spacer(minLength: 8)

            Button(action: onShowDetails) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VenusTheme.text)
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if hasPendingReview {
                            Circle()
                                .fill(VenusTheme.primary)
                                .frame(width: 7, height: 7)
                                .padding(.trailing, 4)
                                .padding(.top, 4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Detalhes da conversa")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusChatHeaderView(
            lens: .socratic,
            isThinking: false,
            hasPendingReview: true,
            onBack: {},
            onShowDetails: {}
        )
    }
}
