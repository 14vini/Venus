//
//  ChatHistoryView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine

struct ChatHistoryView: View {
    @StateObject private var viewModel = ChatHistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSessionForInsights: ChatSession?
    let onSelectSession: (ChatSession) -> Void
    
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
                    
                    Text("Histórico")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(VenusTheme.text)
                    
                    Spacer()
                    
                    Button("Limpar Tudo") {
                        viewModel.clearAllSessions()
                    }
                    .foregroundColor(.red)
                }
                .padding()
                
                // Sessions List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sessions) { session in
                            ChatSessionCard(
                                session: session,
                                onTap: { onSelectSession(session) },
                                onDelete: { viewModel.deleteSession(session.id) },
                                onShowInsights: { selectedSessionForInsights = session }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedSessionForInsights) { session in
            UserInsightsView(session: session)
        }
        .onAppear {
            Task { await viewModel.loadSessions() }
        }
    }
}

struct ChatSessionCard: View {
    let session: ChatSession
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShowInsights: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(session.title)
                        .font(.headline)
                        .foregroundColor(VenusTheme.text)
                        .lineLimit(1)
                    
                    Text(session.summary)
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                    
                    Text(session.lastMessageAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: onShowInsights) {
                        Image(systemName: "chart.bar")
                            .foregroundColor(VenusTheme.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(VenusTheme.surface)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
class ChatHistoryViewModel: ObservableObject {
    @Published var sessions: [ChatSession] = []
    private let repository: ChatRepositoryProtocol = DependencyContainer.shared.makeChatRepository()
    
    func loadSessions() async {
        do {
            sessions = try await repository.loadSessions()
                .sorted { $0.lastMessageAt > $1.lastMessageAt }
        } catch {
            print("Error loading sessions: \(error)")
        }
    }
    
    func deleteSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        Task {
            try? await repository.deleteSession(id: id)
        }
    }
    
    func clearAllSessions() {
        sessions.removeAll()
        Task {
            try? await repository.saveSessions([])
        }
    }
}