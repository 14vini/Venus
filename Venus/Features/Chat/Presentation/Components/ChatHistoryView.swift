//
//  ChatHistoryView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//
//  Histórico sem botões aninhados: o card inteiro abre a conversa e as ações
//  secundárias vivem no menu de contexto. "Limpar Tudo" pede confirmação.
//

import SwiftUI

@Observable
@MainActor
final class ChatHistoryViewModel {
    var sessions: [ChatSession] = []
    private let repository: ChatRepositoryProtocol

    init(repository: ChatRepositoryProtocol? = nil) {
        self.repository = repository ?? DependencyContainer.shared.makeChatRepository()
    }

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

struct ChatHistoryView: View {
    @State private var viewModel = ChatHistoryViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedSessionForInsights: ChatSession?
    @State private var showClearConfirmation = false
    let onSelectSession: (ChatSession) -> Void

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

                    Text("Histórico")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Spacer()

                    Button {
                        guard !viewModel.sessions.isEmpty else { return }
                        showClearConfirmation = true
                    } label: {
                        Text("Limpar Tudo")
                            .font(.system(size: 14, weight: .light, design: .rounded))
                            .foregroundStyle(.red)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.sessions.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

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

                        if viewModel.sessions.isEmpty {
                            Text("Suas conversas aparecem aqui.")
                                .font(.system(size: 14, weight: .light, design: .rounded))
                                .foregroundStyle(VenusTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 48)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedSessionForInsights) { session in
            UserInsightsView(session: session)
        }
        .alert("Limpar todo o histórico?", isPresented: $showClearConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Limpar Tudo", role: .destructive) {
                viewModel.clearAllSessions()
            }
        } message: {
            Text("As conversas salvas neste dispositivo serão removidas. Esta ação não pode ser desfeita.")
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

    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: VenusChatVisualStyle.cardRadius, style: .continuous)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(VenusChatVisualStyle.displayText(session.title))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .lineLimit(1)

                Text(VenusChatVisualStyle.displayText(session.summary))
                    .font(.system(size: 12, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)

                Text(session.lastMessageAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(VenusTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(16)
        .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
        .clipShape(cardShape)
        .overlay(cardShape.stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5))
        .contentShape(cardShape)
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button {
                onShowInsights()
            } label: {
                Label("Ver insights", systemImage: "chart.bar")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Excluir conversa", systemImage: "trash")
            }
        }
    }
}
