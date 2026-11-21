//
//  VenusChatView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

/// Tela de conversa. Hierarquia: (a) cabeçalho discreto, (b) mensagens,
/// (c) campo de entrada sempre visível. Insights e planejamento ficam atrás
/// de um único acesso secundário no cabeçalho.
struct VenusChatView: View {
    @State private var viewModel: VenusChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showDetails = false

    init(
        openedFromMirror: Bool = false,
        openedForPlanning: Bool = false,
        initialPrompt: String? = nil,
        session: ChatSession? = nil
    ) {
        _viewModel = State(initialValue: VenusChatViewModel(
            openedFromMirror: openedFromMirror,
            openedForPlanning: openedForPlanning,
            initialPlanningPrompt: initialPrompt,
            session: session
        ))
    }

    var body: some View {
        ZStack {
            VenusChatBackground()

            VStack(spacing: 0) {
                // (a) Cabeçalho discreto
                VenusChatHeaderView(
                    lens: viewModel.activeLens,
                    isThinking: viewModel.isVenusThinking,
                    hasPendingReview: hasPendingPlan
                ) {
                    isTextFieldFocused = false
                    dismiss()
                } onShowDetails: {
                    isTextFieldFocused = false
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showDetails = true
                }

                // (b) Mensagens + (c) entrada
                conversationArea
            }
        }
        // Quando apresentada dentro de um NavigationStack externo (ex.: Meu Dia),
        // o cabeçalho próprio substitui a barra nativa.
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showDetails) {
            VenusChatDetailsSheet(
                lens: viewModel.activeLens,
                emotionalState: viewModel.currentEmotionalState,
                session: viewModel.currentSession,
                planMessage: latestPlanMessage
            ) { lens in
                viewModel.setSelfKnowledgeLens(lens)
            } onSuggestion: { text in
                showDetails = false
                viewModel.sendMessage(text: text)
            } onConfirmPlan: { messageId in
                viewModel.confirmPlanningProposal(for: messageId)
            }
        }
        .onAppear {
            viewModel.startAnimations()
            viewModel.requestPermissions()
            viewModel.loadInitialData()
        }
        .alert("Aviso", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Conversa

    private var conversationArea: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        // Aviso do Radar de Contradições (transitório e dispensável)
                        if let dissonance = viewModel.lastDiagnosis?.dissonance {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.shield.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.system(size: 13, weight: .bold))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(dissonance.type.badgeLabel)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(VenusTheme.text)

                                    Text(dissonance.headline)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundStyle(VenusTheme.textSecondary)
                                        .lineLimit(1)
                                }

                                Spacer()

                                Button {
                                    withAnimation(.spring(duration: 0.25)) {
                                        viewModel.lastDiagnosis = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(VenusTheme.textSecondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                            let isPrevSame = index > 0 && viewModel.messages[index - 1].isFromUser == message.isFromUser
                            let isNextSame = index < viewModel.messages.count - 1 && viewModel.messages[index + 1].isFromUser == message.isFromUser
                            let isStreamingThis = viewModel.currentlyStreamingMessageId == message.id

                            ChatMessageView(
                                message: message,
                                isPrevSame: isPrevSame,
                                isNextSame: isNextSame,
                                isStreaming: isStreamingThis,
                                onReact: {
                                    viewModel.toggleReaction(for: message.id)
                                },
                                onReply: {
                                    viewModel.replyingToMessage = message
                                    isTextFieldFocused = true
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                },
                                onScheduleReminder: { reminder in
                                    viewModel.scheduleReminderNotification(text: reminder)
                                },
                                onShowPlan: {
                                    isTextFieldFocused = false
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    showDetails = true
                                }
                            )
                            .id(message.id)
                        }
                        .animation(
                            .spring(response: 0.42, dampingFraction: 0.86),
                            value: viewModel.messages.count
                        )

                        if viewModel.isVenusThinking {
                            VenusThinkingView()
                                .id("thinking")
                                .padding(.vertical, 6)
                                .transition(
                                    .asymmetric(
                                        insertion: .opacity.combined(with: .offset(y: 6)),
                                        removal: .opacity
                                    )
                                )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 150)
                }
                .scrollDismissesKeyboard(.interactively)
                .onTapGesture {
                    if isTextFieldFocused {
                        isTextFieldFocused = false
                    }
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.messages.last?.content) { _, _ in
                    if let last = viewModel.messages.last, !last.isFromUser {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isVenusThinking) { _, isThinking in
                    if isThinking {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("thinking", anchor: .bottom)
                        }
                    }
                }
                // Haptic de conclusão quando a resposta final chega (fim do
                // streaming ou conclusão sem streaming, ex.: planejamento).
                .onChange(of: viewModel.currentlyStreamingMessageId) { oldValue, newValue in
                    if oldValue != nil && newValue == nil {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                .onChange(of: viewModel.isVenusThinking) { oldValue, newValue in
                    if oldValue && !newValue && viewModel.currentlyStreamingMessageId == nil {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
            }

            inputBar
        }
    }

    // MARK: - Entrada

    private var inputBar: some View {
        VStack(spacing: 10) {
            if viewModel.isRecording {
                HStack(spacing: 8) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.red)
                        .scaleEffect(viewModel.waveAnimation ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.3).repeatForever(autoreverses: true),
                            value: viewModel.waveAnimation
                        )

                    Text("Gravando... Toque no microfone para parar")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: Capsule(style: .continuous))
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Prévia da mensagem respondida
            if let replyingTo = viewModel.replyingToMessage {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(VenusTheme.primary)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyingTo.isFromUser ? "Você" : "Venus")
                            .font(.caption2.bold())
                            .foregroundStyle(VenusTheme.primary)

                        Text(replyingTo.content)
                            .font(.caption)
                            .foregroundStyle(VenusTheme.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        viewModel.replyingToMessage = nil
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
            }

            HStack(spacing: 12) {
                TextField("Converse com Venus...", text: $inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .focused($isTextFieldFocused)

                if !inputText.isEmpty {
                    Button {
                        inputText = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                if isTextFieldFocused {
                    Button {
                        isTextFieldFocused = false
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(VenusTheme.textSecondary)
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                HStack(spacing: 8) {
                    if inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button {
                            viewModel.toggleRecording()
                        } label: {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(viewModel.isRecording ? .red : VenusTheme.textSecondary)
                        }
                    }

                    Button {
                        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let text = inputText
                        inputText = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.sendMessage(text: text)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                      ? VenusTheme.primary.opacity(0.4)
                                      : VenusTheme.primary)
                                .frame(width: 34, height: 34)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 12)
    }

    // MARK: - Estado derivado

    /// Há uma proposta de rotina aguardando confirmação — sinalizada no cabeçalho.
    private var hasPendingPlan: Bool {
        viewModel.messages.contains { message in
            !message.isFromUser &&
            message.planningProposal != nil &&
            !(message.planningProposal?.proposedBlocks.isEmpty ?? true) &&
            !(message.isPlanningConfirmed ?? false)
        }
    }

    /// Última proposta de rotina exibida no painel de detalhes.
    private var latestPlanMessage: ChatMessage? {
        viewModel.messages.last { message in
            !message.isFromUser &&
            message.planningProposal != nil &&
            !(message.planningProposal?.proposedBlocks.isEmpty ?? true)
        }
    }
}

#Preview {
    VenusChatView()
}
