//
//  PlannedBlockCardView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct PlannedBlockCardView: View {
    let block: PlannedBlock
    let onStart: () -> Void
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onReset: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Category Icon & Status indicator
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(block.category.color.opacity(0.18))
                        .frame(width: 38, height: 38)
                    
                    Image(systemName: block.category.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(block.category.color)
                }
                
                // Vertical Timeline connector (line)
                Rectangle()
                    .fill(block.status == .completed ? Color.green.opacity(0.4) : VenusTheme.textSecondary.opacity(0.2))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 38)
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Time Range & Category badge & Menu
                HStack(spacing: 8) {
                    Text(block.formattedTimeRange)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Text("•")
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.5))
                    
                    Text(block.category.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(block.category.color)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(block.category.color.opacity(0.14), in: Capsule())
                    
                    Spacer()
                    
                    statusBadge
                    
                    // Options menu
                    Menu {
                        if let onEdit = onEdit {
                            Button {
                                onEdit()
                            } label: {
                                Label("Editar bloco", systemImage: "pencil")
                            }
                        }
                        if let onDelete = onDelete {
                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                Label("Excluir bloco", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(VenusTheme.textSecondary.opacity(0.8))
                            .padding(4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Title
                Text(block.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(block.status == .completed ? VenusTheme.textSecondary : VenusTheme.text)
                    .strikethrough(block.status == .completed, color: VenusTheme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEdit?()
                    }
                
                // Note if present
                if let note = block.note, !note.isEmpty {
                    Text(note)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .lineLimit(2)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onEdit?()
                        }
                }
                
                // Action Buttons
                HStack(spacing: 10) {
                    switch block.status {
                    case .planned:
                        Button {
                            onStart()
                        } label: {
                            Label("Iniciar", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(VenusTheme.primary, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onComplete()
                        } label: {
                            Label("Concluir", systemImage: "checkmark")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(VenusTheme.surface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onSkip()
                        } label: {
                            Label("Pular", systemImage: "forward.fill")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        
                    case .inProgress:
                        Button {
                            onComplete()
                        } label: {
                            Label("Concluir", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(Color.green, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button {
                            onSkip()
                        } label: {
                            Label("Pular", systemImage: "forward.fill")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                        
                    case .completed:
                        Button {
                            onReset()
                        } label: {
                            Label("Desfazer", systemImage: "arrow.uturn.backward")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        
                    case .skipped:
                        Button {
                            onReset()
                        } label: {
                            Label("Reativar", systemImage: "arrow.uturn.left")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
            .background(cardBackground)
            .cornerRadius(16)
            .overlay(cardBorder)
        }
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        switch block.status {
        case .planned:
            Text("Pendente")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
        case .inProgress:
            HStack(spacing: 4) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text("Em andamento")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.orange)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.12), in: Capsule())
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                Text("Feito")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.14), in: Capsule())
        case .skipped:
            Text("Pulado")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary.opacity(0.7))
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        if block.status == .inProgress {
            Color.orange.opacity(0.06)
        } else if block.status == .completed {
            VenusTheme.cardSurface.opacity(0.5)
        } else {
            VenusTheme.cardSurface
        }
    }
    
    @ViewBuilder
    private var cardBorder: some View {
        if block.status == .inProgress {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1.5)
        } else if block.status == .completed {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}
