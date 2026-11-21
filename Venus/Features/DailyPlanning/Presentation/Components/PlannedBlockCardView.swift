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
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(block.category.color.opacity(0.16))
                        .frame(width: 38, height: 38)

                    Image(systemName: block.category.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(block.category.color)
                }

                Rectangle()
                    .fill(block.status == .completed ? Color.green.opacity(0.36) : VenusTheme.textSecondary.opacity(0.18))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 38)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(block.formattedTimeRange)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(VenusTheme.textSecondary)

                    Text("•")
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.5))

                    Text(block.category.displayName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(block.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .glassEffect(.regular, in: Capsule(style: .continuous))

                    Spacer()

                    statusBadge

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

                Text(block.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(block.status == .completed ? VenusTheme.textSecondary : VenusTheme.text)
                    .strikethrough(block.status == .completed, color: VenusTheme.textSecondary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onEdit?()
                    }

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

                HStack(spacing: 8) {
                    switch block.status {
                    case .planned:
                        Button {
                            onStart()
                        } label: {
                            Label("Iniciar", systemImage: "play.fill")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                        }
                        .buttonStyle(.glass)
                        .tint(VenusTheme.primary)

                        Button {
                            onComplete()
                        } label: {
                            Label("Concluir", systemImage: "checkmark")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .buttonStyle(.glass)

                        Button {
                            onSkip()
                        } label: {
                            Label("Pular", systemImage: "forward.fill")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        .buttonStyle(.glass)

                    case .inProgress:
                        Button {
                            onComplete()
                        } label: {
                            Label("Concluir", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.green)

                        Button {
                            onSkip()
                        } label: {
                            Label("Pular", systemImage: "forward.fill")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        .buttonStyle(.glass)

                    case .completed:
                        Button {
                            onReset()
                        } label: {
                            Label("Desfazer", systemImage: "arrow.uturn.backward")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.textSecondary)
                        }
                        .buttonStyle(.glass)

                    case .skipped:
                        Button {
                            onReset()
                        } label: {
                            Label("Reativar", systemImage: "arrow.uturn.left")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(VenusTheme.primary)
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
        .background(statusWash, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.spring(response: 0.42, dampingFraction: 0.84), value: block.status)
        .transition(.scale(scale: 0.97).combined(with: .opacity))
    }

    // MARK: - Status

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
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular, in: Capsule(style: .continuous))
        case .completed:
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                Text("Feito")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassEffect(.regular, in: Capsule(style: .continuous))
        case .skipped:
            Text("Pulado")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary.opacity(0.7))
        }
    }

    private var statusWash: Color {
        switch block.status {
        case .inProgress:
            return Color.orange.opacity(0.07)
        case .completed:
            return Color.green.opacity(0.05)
        case .planned, .skipped:
            return Color.clear
        }
    }
}
