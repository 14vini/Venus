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
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDetails = false
    @State private var didLoadInitialData = false
    @State private var isNearBottom = true

    private var isDark: Bool { colorScheme == .dark }

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

    /// A tela só oferece "voltar" quando foi apresentada modalmente
    /// (fullScreenCover da Home ou sheet de "Meu Dia"). Como aba raiz da TabView
    /// não há apresentação para dispensar — esconder evita um botão morto.
    private var isModalPresentation: Bool {
        presentationMode.wrappedValue.isPresented
    }

    /// Coalescência do scroll: muda a cada bloco de ~40 caracteres revelados,
    /// não a cada flush (~16/s). O scroll final é feito ao concluir a resposta.
    private var lastMessageBlock: Int {
        (viewModel.messages.last?.content.count ?? 0) / 40
    }

    var body: some View {
        ZStack {
            VenusChatBackground()

            VStack(spacing: 0) {
                // (a) Cabeçalho discreto
                chatHeader

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
                planMessage: latestPlanMessage,
                diagnosis: viewModel.lastDiagnosis,
                messageCount: viewModel.messages.count
            ) { lens in
                viewModel.setSelfKnowledgeLens(lens)
            } onSuggestion: { text in
                showDetails = false
                viewModel.sendMessage(text: text)
            } onConfirmPlan: { messageId in
                viewModel.confirmPlanningProposal(for: messageId)
            } onDismissDiagnosis: {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                    viewModel.lastDiagnosis = nil
                }
            }
        }
        .onAppear {
            guard !didLoadInitialData else { return }
            didLoadInitialData = true
            viewModel.loadInitialData()
        }
        .alert("Aviso", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    /// O cabeçalho é um componente compartilhado: o recorte esconde apenas a
    /// área do botão "voltar" (12pt de padding + 44pt de botão) quando a tela
    /// é raiz de aba, sem duplicar a UI dele neste arquivo.
    private var chatHeader: some View {
        VenusChatHeaderView(
            lens: viewModel.activeLens,
            isThinking: viewModel.isVenusThinking,
            hasPendingReview: hasPendingPlan || viewModel.lastDiagnosis?.dissonance != nil
        ) {
            isTextFieldFocused = false
            dismiss()
        } onShowDetails: {
            isTextFieldFocused = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showDetails = true
        }
        .mask {
            Rectangle()
                .padding(.leading, isModalPresentation ? 0 : 56)
        }
        .overlay(alignment: .leading) {
            if !isModalPresentation {
                Rectangle()
                    .foregroundStyle(.clear)
                    .frame(width: 56)
                    .contentShape(Rectangle())
                    .onTapGesture {}
            }
        }
        .contentTransition(.opacity)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: viewModel.activeLens)
    }

    // MARK: - Conversa

    private var conversationArea: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    // A conversa é a única coisa nesta área: insights, lentes e
                    // propostas vivem no sheet de detalhes, sem competir aqui.
                    LazyVStack(spacing: 0) {
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
                            .spring(response: 0.42, dampingFraction: 0.8),
                            value: viewModel.messages.count
                        )
                        .contentTransition(.opacity)

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
                // Só acompanha a conversa quem já está perto do fim.
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    let distanceFromBottom = geometry.contentSize.height - geometry.visibleRect.maxY
                    return distanceFromBottom < 140
                } action: { _, nearBottom in
                    isNearBottom = nearBottom
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    isNearBottom = true
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let last = viewModel.messages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: lastMessageBlock) { _, _ in
                    guard isNearBottom else { return }
                    scrollToLatest(proxy)
                }
                .onChange(of: viewModel.isVenusThinking) { _, isThinking in
                    guard isThinking, isNearBottom else { return }
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
                // Um único feedback de conclusão por resposta (o ViewModel
                // sinaliza o fim limpando `currentlyStreamingMessageId`).
                .onChange(of: viewModel.currentlyStreamingMessageId) { oldValue, newValue in
                    guard oldValue != nil, newValue == nil else { return }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    scrollToLatest(proxy)
                }
            }

            inputBar
        }
    }

    /// Rola para a última mensagem — chamado em blocos, nunca por caractere.
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(last.id, anchor: .bottom)
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
                        .contentTransition(.opacity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassEffect(.regular, in: Capsule(style: .continuous))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: viewModel.isRecording)
            }

            // Prévia da mensagem respondida
            if let replyingTo = viewModel.replyingToMessage {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(VenusChatVisualStyle.lilac)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(replyingTo.isFromUser ? "Você" : "Venus")
                            .font(.caption2.bold())
                            .foregroundStyle(VenusTheme.primary)

                        Text(replyingTo.content)
                            .font(.caption)
                            .foregroundStyle(VenusTheme.textSecondary)
                            .lineLimit(1)
                            .contentTransition(.opacity)
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
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: viewModel.replyingToMessage?.id)
            }

            HStack(spacing: 12) {
                TextField("Converse com a Venus...", text: $inputText, axis: .vertical)
                    .lineLimit(1...5)
                    .font(.system(size: 15, weight: .light, design: .rounded))
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
                        .buttonStyle(VenusChatPressStyle())
                    }

                    Button {
                        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let text = inputText
                        inputText = ""
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.sendMessage(text: text)
                    } label: {
                        ZStack {
                            Capsule(style: .continuous)
                                .fill(VenusChatVisualStyle.darkPill(isDark: isDark))
                                .frame(width: 40, height: 36)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .overlay(
                            Capsule(style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.14), Color.clear],
                                        startPoint: .top,
                                        endPoint: .center
                                    )
                                )
                        )
                    }
                    .buttonStyle(VenusChatPressStyle())
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
                    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: inputText.isEmpty)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: Capsule(style: .continuous))
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

// MARK: - Toque suave

/// Pressagem com resposta spring para os controles da entrada — sem estado extra.
private struct VenusChatPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

#Preview {
    VenusChatView()
}
