//
//  VenusHomeTopControlsView.swift
//  Venus
//
//  F19 — itens da Toolbar nativa da Home: histórico/Meu Dia à esquerda,
//  Galaxy/Chat/Perfil à direita. Sem overlay customizado sobre o conteúdo.
//

import SwiftUI

/// Lado esquerdo da toolbar: histórico de conversas e Meu Dia.
struct VenusHomeToolbarLeading: View {
    let onHistoryTap: () -> Void
    let onMyDayTap: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                iconButton(
                    systemImage: "clock.arrow.circlepath",
                    label: "Histórico",
                    action: onHistoryTap
                )
                iconButton(
                    systemImage: "calendar.badge.clock",
                    label: "Meu Dia",
                    action: onMyDayTap
                )
            }
        }
    }

    private func iconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(VenusTheme.text)
                .frame(width: 34, height: 34)
        }
        .accessibilityLabel(label)
    }
}

/// Lado direito da toolbar: Galaxy, Chat e Perfil.
struct VenusHomeToolbarTrailing: View {
    let userName: String
    let onGalaxyTap: () -> Void
    let onChatTap: () -> Void
    let onProfileTap: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 6) {
            HStack(spacing: 6) {
                iconButton(
                    systemImage: "sparkles.rectangle.stack",
                    label: "Galaxy emocional",
                    action: onGalaxyTap
                )
                iconButton(
                    systemImage: "bubble.left.and.bubble.right",
                    label: "Conversar com a Venus",
                    action: onChatTap
                )

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onProfileTap()
                } label: {
                    Text(avatarInitials)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)
                        .frame(width: 34, height: 34)
                }
                .accessibilityLabel("Abrir meu perfil")
            }
        }
    }

    private func iconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(VenusTheme.text)
                .frame(width: 34, height: 34)
        }
        .accessibilityLabel(label)
    }

    private var avatarInitials: String {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "V" : String(trimmed.prefix(2)).uppercased()
    }
}

#Preview {
    VStack(spacing: 20) {
        VenusHomeToolbarLeading(onHistoryTap: {}, onMyDayTap: {})
        VenusHomeToolbarTrailing(
            userName: "Kauã",
            onGalaxyTap: {},
            onChatTap: {},
            onProfileTap: {}
        )
    }
    .padding()
}
