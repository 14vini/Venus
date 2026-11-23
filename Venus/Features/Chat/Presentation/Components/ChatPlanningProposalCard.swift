//
//  ChatPlanningProposalCard.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//
//  Cartão grande (raio 28), sem material de vidro e sem qualquer exibição de
//  raciocínio: apenas os blocos da rotina e a confirmação.
//

import SwiftUI

struct ChatPlanningProposalCard: View {
    let proposal: AIPlanningResponse
    let isConfirmed: Bool
    let onConfirm: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 10) {
                // Cabeçalho
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(VenusChatVisualStyle.lilac)
                        .font(.system(size: 14, weight: .bold))

                    Text(isConfirmed ? "Plano Diário Ativo" : "Proposta de Rotina")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Spacer()

                    if isConfirmed {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 11))
                            Text("Confirmado")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
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
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(VenusTheme.text)
                                .lineLimit(1)

                            Spacer()

                            Text("\(block.startTime) - \(block.endTime)")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(VenusTheme.textSecondary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                        .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
                    }

                    if proposal.proposedBlocks.count > 5 {
                        Text("+ mais \(proposal.proposedBlocks.count - 5) blocos no dia")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                            .padding(.top, 2)
                    }
                }

                // Ação
                if !isConfirmed && proposal.requiresConfirmation && !proposal.proposedBlocks.isEmpty {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onConfirm()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Confirmar e Salvar Plano")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(VenusChatVisualStyle.darkPill(isDark: isDark))
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
            .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
                    .stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5)
            )
            .frame(maxWidth: min(geometry.size.width, 420))
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
