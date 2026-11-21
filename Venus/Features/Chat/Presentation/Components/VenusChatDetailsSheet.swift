//
//  VenusChatDetailsSheet.swift
//  Venus
//
//  Acesso secundário único do Chat. Reúne o que não deve competir com a
//  conversa: lentes, estado emocional, insights e proposta de rotina.
//

import SwiftUI

/// Sheet único do botão de detalhes do cabeçalho. Preserva o acesso a lentes,
/// EmotionalInsights, UserInsights e ao cartão de planejamento sem poluir a tela
/// principal, onde a conversa é a função em foco.
struct VenusChatDetailsSheet: View {
    let lens: SelfKnowledgeLens
    let emotionalState: EmotionalState?
    let session: ChatSession
    let planMessage: ChatMessage?
    let onSelectLens: (SelfKnowledgeLens) -> Void
    let onSuggestion: (String) -> Void
    let onConfirmPlan: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSessionInsights = false

    var body: some View {
        ZStack {
            VenusChatBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header

                    section(title: "Lente ativa", systemImage: "sparkles") {
                        lenses
                    }

                    if emotionalState != nil {
                        section(title: "Como você está", systemImage: "heart") {
                            EmotionalInsightsView(
                                emotionalState: emotionalState,
                                onSuggestionTap: onSuggestion
                            )
                        }
                    }

                    section(title: "Insights da conversa", systemImage: "chart.bar") {
                        sessionInsightsLink
                    }

                    section(title: "Seu plano", systemImage: "calendar.badge.clock") {
                        planningContent
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showSessionInsights) {
            UserInsightsView(session: session)
        }
    }

    // MARK: - Cabeçalho

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sobre esta conversa")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Text("Um olhar gentil, sem interromper a conversa")
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar detalhes")
        }
    }

    // MARK: - Lentes

    private var lenses: some View {
        VStack(spacing: 8) {
            ForEach(SelfKnowledgeLens.allCases) { item in
                Button {
                    onSelectLens(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.iconName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(item.badgeColor)
                            .frame(width: 22)

                        Text(item.title)
                            .font(.system(
                                size: 14,
                                weight: item == lens ? .semibold : .light,
                                design: .rounded
                            ))
                            .foregroundStyle(VenusTheme.text)

                        Spacer()

                        if item == lens {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(VenusTheme.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .glassEffect(
                        .regular.tint(VenusChatVisualStyle.panelTint(isDark: colorScheme == .dark)),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Insights da sessão

    private var sessionInsightsLink: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showSessionInsights = true
        } label: {
            HStack {
                Text("Ver resumo e temas desta conversa")
                    .font(.system(size: 14, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassEffect(
                .regular.tint(VenusChatVisualStyle.panelTint(isDark: colorScheme == .dark)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Planejamento

    @ViewBuilder
    private var planningContent: some View {
        if let planMessage,
           let proposal = planMessage.planningProposal,
           !proposal.proposedBlocks.isEmpty {
            ChatPlanningProposalCard(
                proposal: proposal,
                isConfirmed: planMessage.isPlanningConfirmed == true,
                onConfirm: {
                    onConfirmPlan(planMessage.id)
                }
            )
        } else {
            Text("Quando pedir uma rotina, a proposta aparece aqui.")
                .font(.system(size: 13, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassEffect(
                    .regular.tint(VenusChatVisualStyle.panelTint(isDark: colorScheme == .dark)),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
        }
    }

    // MARK: - Seção

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(VenusTheme.primary)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .textCase(.uppercase)
                    .kerning(0.6)
            }

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VenusChatDetailsSheet(
        lens: .socratic,
        emotionalState: nil,
        session: ChatSession(),
        planMessage: nil,
        onSelectLens: { _ in },
        onSuggestion: { _ in },
        onConfirmPlan: { _ in }
    )
}
