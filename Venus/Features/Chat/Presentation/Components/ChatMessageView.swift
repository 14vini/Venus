//
//  ChatMessageView.swift
//  Venus
//
//  Célula estilo ChatGPT: conversa em foco, balão arejado com material leve,
//  avatar da Venus ao lado das respostas e ações discretas reveladas ao toque
//  (copiar, reagir, responder, regenerar). Arrastar para responder e duplo toque
//  para reagir continuam disponíveis.
//
//  Nada de GeometryReader ou fixedSize na raiz: a altura é intrínseca, então
//  cada mensagem recebe a sua no LazyVStack — sem sobreposição (correção F30).
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
    /// Ação aditiva: quem ainda não oferece regeneração não precisa mudar a chamada.
    var onRegenerate: (() -> Void)? = nil

    @State private var dragOffset: CGFloat = 0
    @State private var isHeartPopping = false
    @State private var showActions = false
    @Environment(\.colorScheme) private var colorScheme

    /// Recuo lateral da row — usado também no cálculo da largura do balão.
    private static let horizontalInset: CGFloat = 16
    /// Calçada fixa à esquerda: avatar da Venus ou seta de resposta ao arrastar.
    private static let gutterWidth: CGFloat = 32
    private static let gutterSpacing: CGFloat = 8
    private static let trailingGutter: CGFloat = 36

    private var isDark: Bool { colorScheme == .dark }

    private var visibleContent: String {
        VenusChatVisualStyle.displayText(message.content)
    }

    /// Largura estável por container (sem GeometryReader). Desconta a calçada
    /// para que avatar + balão nunca empurrem a row além da largura útil.
    private func bubbleWidth(_ length: CGFloat) -> CGFloat {
        let usable = max(0, length - 2 * Self.horizontalInset)
        let preferred = usable * VenusChatVisualStyle.bubbleWidthRatio
        let limit = usable - Self.gutterWidth - Self.gutterSpacing - Self.trailingGutter
        return min(preferred, max(limit, 160))
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Self.gutterSpacing) {
            leadingGutter

            if message.isFromUser {
                Spacer(minLength: 0)
            }

            messageColumn()

            if !message.isFromUser {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .offset(x: dragOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    guard value.translation.width > 0,
                          abs(value.translation.width) > abs(value.translation.height) * 1.3 else { return }
                    dragOffset = min(value.translation.width, 56)
                }
                .onEnded { value in
                    if dragOffset >= 40 {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showActions = false
                        }
                        onReply()
                    }
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        dragOffset = 0
                    }
                }
        )
        .padding(.horizontal, Self.horizontalInset)
        .padding(.top, isPrevSame ? 6 : 18)
        .onChange(of: isStreaming) { _, streaming in
            if streaming {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showActions = false
                }
            }
        }
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.96, anchor: message.isFromUser ? .trailing : .leading)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: 8)),
                removal: .opacity
            )
        )
    }

    // MARK: - Calçada (avatar / resposta)

    @ViewBuilder
    private var leadingGutter: some View {
        ZStack {
            if dragOffset > 0 {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(VenusChatVisualStyle.lilac)
                    .opacity(Double(min(1, dragOffset / 40)))
                    .scaleEffect(min(1.12, dragOffset / 40))
            } else if !message.isFromUser && !isPrevSame {
                VenusMoodOrb(
                    state: .idle,
                    size: 28,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
            }
        }
        .frame(width: Self.gutterWidth, height: 32)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Coluna da mensagem

    @ViewBuilder
    private func messageColumn() -> some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 7) {
            if let replyContent = message.replyToContent {
                quote(text: VenusChatVisualStyle.displayText(replyContent))
            }

            bubble

            if showActions && !isStreaming {
                actionBar
            }

            // Proposta e lembrete continuam em acesso secundário: só um convite
            // discreto, sem competir com a conversa.
            if let proposal = message.planningProposal,
               !proposal.proposedBlocks.isEmpty,
               !message.isFromUser {
                planLink
            }

            if let reminder = message.reminder, !reminder.isEmpty, !message.isFromUser {
                reminderLink(VenusChatVisualStyle.displayText(reminder))
            }

            if !isNextSame {
                Text(VenusChatVisualStyle.timestampLabel(for: message.timestamp))
                    .font(.system(size: 10, weight: .light, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary.opacity(0.8))
                    .padding(.horizontal, 4)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: message.timestamp)
            }
        }
        .containerRelativeFrame(.horizontal) { length, _ in
            bubbleWidth(length)
        }
    }

    private func quote(text: String) -> some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(VenusChatVisualStyle.lilac)
                .frame(width: 2.5, height: 20)

            Text(text)
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

    // MARK: - Balão

    private var bubble: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text(visibleContent)
                .font(.system(size: message.isFromUser ? 15 : 15.5, weight: .light, design: .rounded))
                .lineSpacing(message.isFromUser ? 5 : 7)
                .foregroundStyle(VenusTheme.text)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: message.content)

            if !message.isFromUser && isStreaming && !visibleContent.isEmpty {
                Capsule()
                    .fill(VenusChatVisualStyle.lilac)
                    .frame(width: 2, height: 16)
                    .offset(y: -2)
                    .phaseAnimator([false, true], trigger: isStreaming) { cursor, isLit in
                        cursor.opacity(isLit ? 0.9 : 0.12)
                    } animation: { _ in
                        .spring(response: 0.5, dampingFraction: 0.8)
                    }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .glassEffect(
            .clear.tint(VenusChatVisualStyle.bubbleTint(
                isFromUser: message.isFromUser,
                isDark: isDark
            )),
            in: RoundedRectangle(cornerRadius: VenusChatVisualStyle.bubbleRadius, style: .continuous)
        )
        .overlay(alignment: message.isFromUser ? .topLeading : .topTrailing) {
            reactionChip
        }
        .contentShape(RoundedRectangle(cornerRadius: VenusChatVisualStyle.bubbleRadius, style: .continuous))
        .onTapGesture(count: 2) {
            react()
        }
        .onTapGesture {
            guard !isStreaming else { return }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                showActions.toggle()
            }
        }
    }

    @ViewBuilder
    private var reactionChip: some View {
        if let reaction = message.reaction {
            Button(action: react) {
                Text(reaction)
                    .font(.system(size: 13))
                    .padding(7)
                    .background(VenusChatVisualStyle.surfaceFill(isDark: isDark))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(VenusChatVisualStyle.surfaceBorder(isDark: isDark), lineWidth: 0.5))
                    .scaleEffect(isHeartPopping ? 1.25 : 1)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Circle())
            .offset(x: message.isFromUser ? -9 : 9, y: -9)
            .accessibilityLabel("Reação: \(reaction). Toque para remover")
        }
    }

    // MARK: - Ações ao tocar

    private var actionBar: some View {
        HStack(spacing: 2) {
            actionButton(
                systemImage: "doc.on.doc",
                label: "Copiar texto",
                action: copyText
            )

            actionButton(
                systemImage: message.reaction == nil ? "heart" : "heart.fill",
                label: message.reaction == nil ? "Reagir" : "Remover reação",
                action: react
            )

            actionButton(
                systemImage: "arrowshape.turn.up.left",
                label: "Responder",
                action: reply
            )

            if let onRegenerate {
                actionButton(
                    systemImage: "arrow.clockwise",
                    label: "Regenerar resposta",
                    action: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showActions = false
                        }
                        onRegenerate()
                    }
                )
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(VenusChatVisualStyle.controlFill(isDark: isDark), in: Capsule(style: .continuous))
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.9, anchor: message.isFromUser ? .trailing : .leading)
                    .combined(with: .opacity),
                removal: .opacity
            )
        )
    }

    private func actionButton(
        systemImage: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(VenusChatVisualStyle.lilac)
                .frame(width: 34, height: 34)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func copyText() {
        UIPasteboard.general.string = visibleContent
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            showActions = false
        }
    }

    private func react() {
        isHeartPopping = true
        onReact()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
            isHeartPopping = false
        }
    }

    private func reply() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            showActions = false
        }
        onReply()
    }

    // MARK: - Acesso secundário

    private var planLink: some View {
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
            .foregroundStyle(VenusChatVisualStyle.lilac)
            .padding(.horizontal, 13)
            .frame(minHeight: 40)
            .background(VenusChatVisualStyle.controlFill(isDark: isDark))
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func reminderLink(_ text: String) -> some View {
        Button {
            onScheduleReminder?(text)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 10))
                Text(text)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(VenusTheme.text)
            .padding(.horizontal, 13)
            .frame(minHeight: 40)
            .background(VenusChatVisualStyle.controlFill(isDark: isDark))
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VStack {
            ChatMessageView(
                message: ChatMessage(content: "Oi! Como posso cuidar de você hoje?", isFromUser: false),
                isPrevSame: false,
                isNextSame: false,
                onReact: {},
                onReply: {}
            )
            ChatMessageView(
                message: ChatMessage(content: "Quero acalmar a mente", isFromUser: true),
                isPrevSame: false,
                isNextSame: false,
                onReact: {},
                onReply: {}
            )
        }
    }
}
