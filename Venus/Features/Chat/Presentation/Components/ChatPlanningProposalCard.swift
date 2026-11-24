//
//  ChatPlanningProposalCard.swift
//  Venus
//
//  Cartão da proposta de rotina, exibido apenas no acesso secundário (sheet de
//  detalhes). Visual jornada: lilás/rosa discretos e CTA escuro. Nenhum campo
//  bruto ou texto de raciocínio é exibido — só os blocos e a confirmação.
//
//  A raiz não usa GeometryReader nem fixedSize: a altura é intrínseca dentro
//  do ScrollView do sheet, mantendo a correção de layout do chat.
//

import SwiftUI

struct ChatPlanningProposalCard: View {
    let proposal: AIPlanningResponse
    let isConfirmed: Bool
    let onConfirm: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Traço lilás → rosa: assinatura da jornada, sem vidro extra.
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [VenusChatVisualStyle.lilac, VenusChatVisualStyle.rose],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 54, height: 3)

            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(VenusChatVisualStyle.lilac)
                    .font(.system(size: 14, weight: .semibold))

                Text(isConfirmed ? "Plano diário ativo" : "Proposta de rotina")
                    .font(.system(size: 15, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.text)

                Spacer(minLength: 4)

                if isConfirmed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VenusChatVisualStyle.lilac)
                            .font(.system(size: 11))
                        Text("Confirmado")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(VenusChatVisualStyle.lilac)
                    }
                }
            }

            // Blocos do dia — nenhum campo bruto ou resumo interno é exibido.
            VStack(spacing: 6) {
                ForEach(Array(proposal.proposedBlocks.prefix(5).enumerated()), id: \.offset) { _, block in
                    let category = BlockCategory(rawValue: block.category.lowercased()) ?? .personal
                    HStack(spacing: 8) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 11))
                            .foregroundStyle(category.color)
                            .frame(width: 18)

                        Text(VenusChatVisualStyle.displayText(block.title))
                            .font(.system(size: 12, weight: .light, design: .rounded))
                            .foregroundStyle(VenusTheme.text)
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        Text("\(block.startTime) – \(block.endTime)")
                            .font(.system(size: 11, weight: .light, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
                }

                if proposal.proposedBlocks.count > 5 {
                    Text("+ mais \(proposal.proposedBlocks.count - 5) blocos no dia")
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .padding(.top, 2)
                }
            }

            if !isConfirmed && proposal.requiresConfirmation && !proposal.proposedBlocks.isEmpty {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onConfirm()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Confirmar e salvar plano")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(VenusChatVisualStyle.darkPill(isDark: isDark))
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
        .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
                .stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5)
        )
        .frame(maxWidth: 420)
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        ChatPlanningProposalCard(
            proposal: AIPlanningResponse(
                message: "",
                intent: .createPlan,
                proposedBlocks: [],
                requiresConfirmation: true
            ),
            isConfirmed: false,
            onConfirm: {}
        )
        .padding()
    }
}
