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
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Fechar") { dismiss() }
                        .foregroundColor(VenusTheme.primary)
                    
                    Spacer()
                    
                    Text("Insights da Conversa")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(VenusTheme.text)
                    
                    Spacer()
                    
                    Spacer().frame(width: 50) // Balance
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Session Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Informações da Sessão")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(VenusTheme.text)
                            
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
                            .font(.body)
                            .foregroundColor(VenusTheme.textSecondary)
                        }
                        .padding()
                        .background(VenusTheme.surface)
                        .cornerRadius(16)
                        
                        // User Insights
                        if !session.userInsights.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Temas Identificados")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(VenusTheme.text)
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(session.userInsights, id: \.self) { insight in
                                        HStack {
                                            Circle()
                                                .fill(VenusTheme.primary)
                                                .frame(width: 8, height: 8)
                                            
                                            Text(insight)
                                                .font(.body)
                                                .foregroundColor(VenusTheme.textSecondary)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(VenusTheme.surface)
                            .cornerRadius(16)
                        }
                        
                        // Message Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resumo da Conversa")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(VenusTheme.text)
                            
                            Text(generateSummary())
                                .font(.body)
                                .foregroundColor(VenusTheme.textSecondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(VenusTheme.surface)
                        .cornerRadius(16)
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

#Preview {
    UserInsightsView(session: ChatSession(title: "Conversa sobre Ansiedade"))
}