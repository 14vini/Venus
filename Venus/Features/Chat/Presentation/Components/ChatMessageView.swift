//
//  ChatMessageView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//
//  O balão é a única superfície com material do chat. Curva contínua de 22pt,
//  largura limitada pelo container (sem GeometryReader na raiz) e um selo de
//  tempo discreto no fim de cada grupo de mensagens do mesmo autor.
//

import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    let isPrevSame: Bool
    let isNextSame: Bool
    var isStreaming: Bool = false
    let onReact: () -> Void
    let onReply: () -> Void
    var onScheduleReminder: ((String) -> Void)? = nil
    var onShowPlan: (() -> Void)? = nil

    @State private var dragOffset: CGFloat = 0
    @State private var isHeartPopping = false
    @Environment(\.colorScheme) private var colorScheme

    /// Recuo lateral da row; também usado para descontar a largura útil no
    /// cálculo do balão, mantendo as duas medidas sempre em sincronia.
    private static let horizontalInset: CGFloat = 16

    private var visibleContent: String {
        VenusChatVisualStyle.displayText(message.content)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Resposta que aparece ao arrastar para a direita.
            if dragOffset > 0 {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(VenusTheme.primary)
                    .frame(width: 32)
                    .opacity(Double(min(1.0, dragOffset / 40.0)))
                    .scaleEffect(min(1.15, dragOffset / 40.0))
                    .padding(.trailing, 6)
            }

            HStack(alignment: .bottom, spacing: 0) {
                if message.isFromUser {
                    Spacer(minLength: 36)
                }

                messageColumn()

                if !message.isFromUser {
                    Spacer(minLength: 36)
                }
            }
            // A row precisa ocupar toda a largura para que o Spacer empurre
            // o balão até a borda correta (direita do usuário, esquerda da Venus).
            .frame(maxWidth: .infinity)
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        if value.translation.width > 0 &&
                            abs(value.translation.width) > abs(value.translation.height) * 1.3 {
                            dragOffset = min(value.translation.width, 60)
                        }
                    }
                    .onEnded { value in
                        if dragOffset >= 40 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onReply()
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
            .onTapGesture(count: 2) {
                isHeartPopping = true
                onReact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                    isHeartPopping = false
                }
            }
            .contextMenu {
                Button {
                    onReply()
                } label: {
                    Label("Responder", systemImage: "arrowshape.turn.up.left")
                }

                Button {
                    UIPasteboard.general.string = visibleContent
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Copiar Texto", systemImage: "doc.on.doc")
                }

                Button {
                    onReact()
                } label: {
                    Label(
                        message.reaction != nil ? "Remover Reação" : "Reagir com ❤️",
                        systemImage: "heart.fill"
                    )
                }
            }
        }
        .padding(.horizontal, Self.horizontalInset)
        .padding(.top, isPrevSame ? 6 : 18)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.94, anchor: message.isFromUser ? .trailing : .leading)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: 8)),
                removal: .opacity
            )
        )
    }

    // MARK: - Coluna da mensagem

    @ViewBuilder
    private func messageColumn() -> some View {
        let isDark = colorScheme == .dark

        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
            // Citação de uma mensagem respondida.
            if let replyContent = message.replyToContent {
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(VenusTheme.primary)
                        .frame(width: 2.5)

                    Text(VenusChatVisualStyle.displayText(replyContent))
                        .font(.system(size: 11, weight: .light, design: .rounded))
                        .italic()
                        .foregroundStyle(VenusTheme.textSecondary)
                        .lineLimit(1)
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                .clipShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.controlRadius, style: .continuous))
            }

            // Única superfície de vidro da tela: o balão.
            HStack(alignment: .bottom, spacing: 3) {
                Text(visibleContent)
                    .font(message.isFromUser
                          ? .system(size: 15, weight: .light, design: .rounded)
                          : .system(size: 16, weight: .light, design: .rounded))
                    .lineSpacing(message.isFromUser ? 5 : 8)
                    .foregroundStyle(VenusTheme.text)
                    .contentTransition(.opacity)
                    .animation(
                        .spring(response: 0.42, dampingFraction: 0.8),
                        value: message.content
                    )

                if !message.isFromUser && isStreaming && !visibleContent.isEmpty {
                    // Blink orientado por fase: para sozinho quando o texto
                    // termina, sem estado extra nem animação presa na view.
                    Capsule()
                        .fill(VenusChatVisualStyle.lilac)
                        .frame(width: 2, height: 17)
                        .offset(y: -2)
                        .phaseAnimator([false, true], trigger: isStreaming) { cursor, isLit in
                            cursor.opacity(isLit ? 0.9 : 0.12)
                        } animation: { _ in
                            .spring(response: 0.5, dampingFraction: 0.8)
                        }
                }
            }
            .padding(.horizontal, 19)
            .padding(.vertical, 16)
            .glassEffect(
                .regular.tint(VenusChatVisualStyle.bubbleTint(
                    isFromUser: message.isFromUser,
                    isDark: isDark
                )),
                in: RoundedRectangle(cornerRadius: VenusChatVisualStyle.bubbleRadius, style: .continuous)
            )

            // A proposta de rotina vive no acesso secundário; aqui fica só
            // um convite discreto, para não competir com a conversa.
            if let proposal = message.planningProposal,
               !proposal.proposedBlocks.isEmpty,
               !message.isFromUser {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onShowPlan?()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11, weight: .semibold))

                        Text(message.isPlanningConfirmed == true
                             ? "Plano ativo · ver detalhes"
                             : "Ver proposta de rotina")
                            .font(.system(size: 12, weight: .light, design: .rounded))

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(VenusTheme.primary)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 44)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 2)
            }

            // Lembrete agendado pela Venus.
            if let reminder = message.reminder, !reminder.isEmpty, !message.isFromUser {
                Button {
                    onScheduleReminder?(reminder)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 10))
                        Text(VenusChatVisualStyle.displayText(reminder))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(VenusTheme.text)
                    .padding(.horizontal, 13)
                    .frame(minHeight: 44)
                    .background(VenusChatVisualStyle.controlFill(isDark: isDark))
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 2)
            }

            // Data e hora só no último balão do grupo — sem poluir a conversa.
            if !isNextSame {
                Text(VenusChatVisualStyle.timestampLabel(for: message.timestamp))
                    .font(.system(size: 10, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary.opacity(0.8))
                    .padding(.horizontal, 4)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: message.timestamp)
            }
        }
        // Limite de largura relativo ao container (ScrollView), sem
        // GeometryReader na raiz: a altura permanece intrínseca, então cada
        // mensagem recebe sua própria altura no LazyVStack (sem sobreposição).
        .containerRelativeFrame(.horizontal) { length, _ in
            (length - 2 * Self.horizontalInset) * VenusChatVisualStyle.bubbleWidthRatio
        }
        .overlay(alignment: message.isFromUser ? .bottomLeading : .bottomTrailing) {
            if let reaction = message.reaction {
                Button {
                    onReact()
                } label: {
                    Text(reaction)
                        .font(.system(size: 13))
                        .padding(8)
                        .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5))
                        .scaleEffect(isHeartPopping ? 1.3 : 1.0)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Circle())
                .offset(x: message.isFromUser ? -8 : 8, y: 16)
            }
        }
    }
}
