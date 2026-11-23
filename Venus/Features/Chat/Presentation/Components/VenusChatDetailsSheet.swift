//
//  VenusChatDetailsSheet.swift
//  Venus
//
//  Acesso secundário único do Chat. Reúne lentes, estado emocional e insights
//  sem competir com a conversa. Sem seções vazias e sem empilhamento de vidro.
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
    let diagnosis: SelfKnowledgeDiagnosis?
    let messageCount: Int
    let onSelectLens: (SelfKnowledgeLens) -> Void
    let onSuggestion: (String) -> Void
    let onConfirmPlan: (UUID) -> Void
    let onDismissDiagnosis: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSessionInsights = false

    private var isDark: Bool { colorScheme == .dark }

    /// A proposta de rotina aparece somente quando existe algo para mostrar.
    private var hasPlan: Bool {
        guard let planMessage, let proposal = planMessage.planningProposal else { return false }
        return !proposal.proposedBlocks.isEmpty
    }

    var body: some View {
        ZStack {
            VenusChatBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
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

                    if let dissonance = diagnosis?.dissonance {
                        section(title: "Radar de contradições", systemImage: "bolt.shield") {
                            dissonanceCard(dissonance)
                        }
                    }

                    section(title: "Insights da conversa", systemImage: "chart.bar") {
                        sessionInsightsLink
                    }

                    if hasPlan {
                        section(title: "Seu plano", systemImage: "calendar.badge.clock") {
                            planningContent
                        }
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

                // Número discreto com a mesma transição da Home: só muda quando
                // a conversa cresce, sem afetar o foco da tela principal.
                Text("\(messageCount) mensagens")
                    .font(.system(size: 11, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary.opacity(0.8))
                    .contentTransition(.numericText(value: Double(messageCount)))
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: messageCount)
            }

            Spacer()

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .frame(width: 44, height: 44)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(Circle())
                    .contentShape(Circle())
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
                                .foregroundStyle(VenusChatVisualStyle.lilac)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(minHeight: 50)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
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
            .frame(minHeight: 50)
            .background(VenusChatVisualStyle.controlFill(isDark: isDark))
            .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Radar de contradições

    /// O aviso saiu da conversa e vive aqui: o insight é consultado, não imposto.
    private func dissonanceCard(_ dissonance: DissonanceDetection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Text(VenusChatVisualStyle.displayText(dissonance.type.badgeLabel))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusChatVisualStyle.lilac)

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onDismissDiagnosis()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .frame(width: 30, height: 30)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dispensar aviso")
            }

            Text(VenusChatVisualStyle.displayText(dissonance.headline))
                .font(.system(size: 14, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)

            Text(VenusChatVisualStyle.displayText(dissonance.explanation))
                .font(.system(size: 12, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(VenusChatVisualStyle.controlFill(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
        .contentTransition(.opacity)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: dissonance.id)
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
                    .foregroundStyle(VenusChatVisualStyle.lilac)

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
        diagnosis: nil,
        messageCount: 0,
        onSelectLens: { _ in },
        onSuggestion: { _ in },
        onConfirmPlan: { _ in },
        onDismissDiagnosis: {}
    )
}
