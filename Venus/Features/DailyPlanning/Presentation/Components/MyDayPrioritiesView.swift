//
//  MyDayPrioritiesView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct MyDayPrioritiesView: View {
    let priorities: [PlannedBlock]
    let onComplete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Prioridades de Hoje", systemImage: "flag.fill")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                Text("Máximo 3")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }

            VStack(spacing: 8) {
                ForEach(Array(priorities.prefix(3).enumerated()), id: \.element.id) { index, block in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(block.category.color.opacity(0.16))
                                .frame(width: 26, height: 26)

                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(block.category.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(block.status == .completed ? VenusTheme.textSecondary : VenusTheme.text)
                                .strikethrough(block.status == .completed)
                                .lineLimit(1)

                            Text(block.formattedTimeRange)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(VenusTheme.textSecondary)
                        }

                        Spacer()

                        Button {
                            onComplete(block.id)
                        } label: {
                            Image(systemName: block.status == .completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(block.status == .completed ? .green : VenusTheme.textSecondary)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(block.status == .completed ? "Desmarcar prioridade" : "Concluir prioridade")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .animation(.spring(response: 0.4, dampingFraction: 0.82), value: block.status)
                }
            }
        }
    }
}
