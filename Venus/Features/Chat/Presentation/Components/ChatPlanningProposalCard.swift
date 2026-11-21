//
//  ChatPlanningProposalCard.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct ChatPlanningProposalCard: View {
    let proposal: AIPlanningResponse
    let isConfirmed: Bool
    let onConfirm: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(VenusTheme.primary)
                    .font(.system(size: 14, weight: .bold))
                
                Text(isConfirmed ? "Plano Diário Ativo" : "Proposta de Rotina")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                
                Spacer()
                
                if isConfirmed {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                        Text("Confirmado")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Reasoning summary
            if let reasoning = proposal.reasoningSummary, !reasoning.isEmpty {
                Text(reasoning)
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .lineLimit(2)
            }
            
            // Blocks list preview
            VStack(spacing: 6) {
                ForEach(Array(proposal.proposedBlocks.prefix(5).enumerated()), id: \.offset) { _, block in
                    let category = BlockCategory(rawValue: block.category.lowercased()) ?? .personal
                    HStack(spacing: 8) {
                        Image(systemName: category.iconName)
                            .font(.system(size: 11))
                            .foregroundColor(category.color)
                            .frame(width: 18)
                        
                        Text(block.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text("\(block.startTime) - \(block.endTime)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(VenusTheme.surface.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                if proposal.proposedBlocks.count > 5 {
                    Text("+ mais \(proposal.proposedBlocks.count - 5) blocos no dia")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .padding(.top, 2)
                }
            }
            
            // Action button
            if !isConfirmed && proposal.requiresConfirmation && !proposal.proposedBlocks.isEmpty {
                Button {
                    onConfirm()
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                        Text("Confirmar e Salvar Plano")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                    .foregroundColor(VenusTheme.text)
                    .padding(.vertical, 10)
                    .glassEffect(
                        .regular.tint(VenusChatVisualStyle.panelTint(isDark: colorScheme == .dark)),
                        in: Capsule(style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .glassEffect(
            .regular.tint(VenusChatVisualStyle.panelTint(isDark: colorScheme == .dark)),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.85)
    }
}
