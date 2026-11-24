//
//  VenusChatView.swift
//  Venus
//
//  Shell do Chat no estilo da conversa: cabeçalho limpo, coluna centralizada
//  de mensagens e composer fixo no rodapé. Insights e planejamento continuam
//  atrás de um único acesso secundário no cabeçalho.
//
//  O composer usa `safeAreaInset` em vez de sobrepor o ScrollView: a última
//  mensagem nunca fica escondida, inclusive com teclado aberto.
//

import SwiftUI

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

    /// Stop aparece desde o "pensando" até o último caractere revelado.
    private var isGenerating: Bool {
        viewModel.isVenusThinking || viewModel.currentlyStreamingMessageId != nil
    }

    var body: some View {
        ZStack {
            VenusChatBackground()

            VStack(spacing: 0) {
                chatHeader
                conversationArea
            }
        }
        // Quando apresentada dentro de um NavigationStack externo (ex.: Meu Dia),
        // o cabeçalho próprio substitui a barra nativa.
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
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

    // MARK: - Cabeçalho

    private var chatHeader: some View {
        VenusChatHeaderView(
            lens: viewModel.activeLens,
            isThinking: viewModel.isVenusThinking,
            hasPendingReview: hasPendingPlan || viewModel.lastDiagnosis?.dissonance != nil,
            isModal: isModalPresentation,
            onNewChat: startNewConversation,
            onBack: {
                isTextFieldFocused = false
                dismiss()
            },
            onShowDetails: {
                isTextFieldFocused = false
                VenusChatHaptics.light()
                showDetails = true
            }
        )
    }

    /// Sessão nova sem tocar no ViewModel: troca a instância de estado, que já
    /// traz sessão, mensagens e lente zerados, e dispara o carregamento inicial.
    /// A resposta ativa é cancelada pelo próprio ViewModel antes da troca.
    private func startNewConversation() {
        isTextFieldFocused = false
        inputText = ""
        viewModel.stopStreaming()

        let freshViewModel = VenusChatViewModel()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
            viewModel = freshViewModel
            isNearBottom = true
        }
        freshViewModel.loadInitialData()
    }

    /// Envio centralizado (composer e sugestões do estado vazio).
    private func send(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isTextFieldFocused = false
        viewModel.sendMessage(text: text)
    }

    // MARK: - Conversa

    private var conversationArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if viewModel.messages.isEmpty {
                        VenusChatEmptyStateView { suggestion in
                            send(suggestion)
                        }
                    } else {
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
                    }

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
                .padding(.bottom, 24)
                .frame(maxWidth: VenusChatVisualStyle.conversationMaxWidth)
                .frame(maxWidth: .infinity)
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
                VenusChatHaptics.success()
                scrollToLatest(proxy)
            }
        }
    }

    /// Rola para a última mensagem — chamado em blocos, nunca por caractere.
    private func scrollToLatest(_ proxy: ScrollViewProxy) {
        guard let last = viewModel.messages.last else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VenusChatComposerView(
            text: $inputText,
            isFocused: $isTextFieldFocused,
            isStreaming: isGenerating,
            isRecording: viewModel.isRecording,
            waveAnimation: viewModel.waveAnimation,
            replyingTo: viewModel.replyingToMessage,
            onSend: send,
            onStop: { viewModel.stopStreaming() },
            onToggleRecording: { viewModel.toggleRecording() },
            onCancelReply: { viewModel.replyingToMessage = nil },
            onDismissKeyboard: { isTextFieldFocused = false }
        )
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
