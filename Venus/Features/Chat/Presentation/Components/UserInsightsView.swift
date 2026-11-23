//
//  UserInsightsView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct UserInsightsView: View {
    let session: ChatSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            VenusChatBackground()

            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button("Fechar") { dismiss() }
                        .font(.system(size: 15, weight: .light, design: .rounded))
                        .foregroundStyle(VenusTheme.primary)
                        .frame(minHeight: 44)

                    Spacer()

                    Text("Insights da Conversa")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Spacer()

                    Spacer().frame(width: 56)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Informações da Sessão")
                                .font(.system(size: 20, weight: .light, design: .rounded))
                                .foregroundStyle(VenusTheme.text)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Data:")
                                        .fontWeight(.semibold)
                                    Text(session.createdAt.formatted(date: .complete, time: .shortened))
                                }

                                HStack {
                                    Text("Mensagens:")
                                        .fontWeight(.semibold)
                                    Text("\(session.messages.count)")
                                }

                                HStack {
                                    Text("Duração:")
                                        .fontWeight(.semibold)
                                    Text(formatDuration())
                                }
                            }
                            .font(.system(size: 14, weight: .light, design: .rounded))
                            .foregroundStyle(VenusTheme.textSecondary)
                        }
                        .cardSurface(isDark: isDark)

                        if !session.userInsights.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Temas Identificados")
                                    .font(.system(size: 20, weight: .light, design: .rounded))
                                    .foregroundStyle(VenusTheme.text)

                                LazyVStack(spacing: 8) {
                                    ForEach(session.userInsights, id: \.self) { insight in
                                        HStack {
                                            Circle()
                                                .fill(VenusTheme.primary)
                                                .frame(width: 8, height: 8)

                                            Text(VenusChatVisualStyle.displayText(insight))
                                                .font(.body)
                                                .foregroundStyle(VenusTheme.textSecondary)

                                            Spacer()
                                        }
                                        .frame(minHeight: 44)
                                    }
                                }
                            }
                            .cardSurface(isDark: isDark)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resumo da Conversa")
                                .font(.system(size: 20, weight: .light, design: .rounded))
                                .foregroundStyle(VenusTheme.text)

                            Text(VenusChatVisualStyle.displayText(generateSummary()))
                                .font(.body)
                                .foregroundStyle(VenusTheme.textSecondary)
                                .lineLimit(nil)
                        }
                        .cardSurface(isDark: isDark)
                    }
                    .padding()
                }
            }
        }
    }

    private func formatDuration() -> String {
        guard let firstMessage = session.messages.first,
              let lastMessage = session.messages.last else {
            return "N/A"
        }

        let duration = lastMessage.timestamp.timeIntervalSince(firstMessage.timestamp)
        let minutes = Int(duration / 60)

        if minutes < 1 {
            return "Menos de 1 minuto"
        } else if minutes == 1 {
            return "1 minuto"
        } else {
            return "\(minutes) minutos"
        }
    }

    private func generateSummary() -> String {
        let userMessages = session.messages.filter { $0.isFromUser }
        let totalMessages = session.messages.count

        var summary = "Conversa com \(totalMessages) mensagens, sendo \(userMessages.count) do usuário. "

        if !session.userInsights.isEmpty {
            summary += "Principais temas abordados: \(session.userInsights.joined(separator: ", ").lowercased()). "
        }

        summary += "A Venus ofereceu suporte e orientações personalizadas durante toda a conversa."
        return summary
    }
}

// MARK: - Superfície plana reutilizável

private extension View {
    func cardSurface(isDark: Bool) -> some View {
        self
            .padding(20)
            .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
            .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
                    .stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5)
            )
    }
}
