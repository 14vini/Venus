//
//  VenusChatViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Speech
import AVFoundation
import UIKit

/// Snapshot lido pela UI. O texto bruto é acumulado em ator de background;
/// nenhum regex acontece dentro do acumulador.
private struct VenusRawSnapshot: Sendable {
    let text: String
    let isFinished: Bool
}

/// Só concatena chunks — trabalho barato, fora do main actor. O consumidor da
/// API de IA roda aqui, desafogando a thread da UI da leitura do stream.
private actor VenusRawStream {
    private var text = ""
    private var finished = false

    func append(_ chunk: String) {
        guard !finished else { return }
        text += chunk
    }

    func finish() { finished = true }

    func snapshot() -> VenusRawSnapshot {
        VenusRawSnapshot(text: text, isFinished: finished)
    }
}

/// Cache do filtro da F23. `ThinkingStreamFilter`/`VenusTextSanitizer` são
/// implicitamente MainActor neste projeto (`-default-isolation=MainActor`),
/// então o regex fica na UI, mas **no máximo uma vez por janela de 150 ms** e
/// somente se o texto bruto mudou — em vez de ~18x/s por chunk.
@MainActor
private final class VenusVisibleTextCache {
    private var source = ""
    private var visible = ""
    private var lastTick = ContinuousClock.now
    private let interval = Duration.milliseconds(150)

    func text(for raw: String) -> String {
        guard raw != source else { return visible }
        let now = ContinuousClock.now
        guard now - lastTick >= interval else { return visible }
        lastTick = now
        source = raw
        visible = ThinkingStreamFilter.clean(raw)
        return visible
    }
}

/// Resultado das leituras e dos motores aplicado na UI numa única transição.
private struct VenusChatAnalysis {
    let moods: [Mood]
    let plan: DailyPlan?
    let readiness: ReadinessEnergyAssessment
    let diagnosis: SelfKnowledgeDiagnosis
    let pendingProposalId: UUID?
    let isPlanning: Bool
}

@MainActor
@Observable
final class VenusChatViewModel {
    var messages: [ChatMessage] = []
    var isVenusThinking: Bool = false
    var isRecording: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    var replyingToMessage: ChatMessage? = nil
    var particleAnimation: Bool = false
    var waveAnimation: Bool = false
    var currentSession: ChatSession
    var currentEmotionalState: EmotionalState? = nil
    var currentlyStreamingMessageId: UUID? = nil
    var activeLens: SelfKnowledgeLens = .socratic
    var lastDiagnosis: SelfKnowledgeDiagnosis? = nil
    var currentReadiness: ReadinessEnergyAssessment? = nil
    var todayPlan: DailyPlan? = nil
    
    private let chatRepository: ChatRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let venusAI: VenusAIServiceProtocol
    private let readinessEngine: ReadinessEngineProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var userProfile: UserProfile?
    private let openedFromMirror: Bool
    private let openedForPlanning: Bool
    private let initialPlanningPrompt: String?
    private var didLoadInitialData = false
    /// Uma resposta por vez: cancelar a anterior evita tasks órfãs competindo
    /// pela mesma célula e escritas tardias após uma nova pergunta.
    private var activeResponseTask: Task<Void, Never>?
    private var activeEmotionalTask: Task<Void, Never>?

    // Revelação em lotes: o @Observable é tocado ~6x/s (não ~18x/s). Cada
    // escrita altera somente o `content` da mensagem em streaming; a sessão
    // (usada pelo sheet) é atualizada uma única vez, no fim.
    private let flushIntervalNanos: UInt64 = 140_000_000
    private let pollIntervalNanos: UInt64 = 80_000_000
    private let batchCharacterCount = 54
    /// Spring único da Home para estados que mudam na tela do chat.
    private static let uiSpring = Animation.spring(response: 0.42, dampingFraction: 0.8)
    
    init(
        openedFromMirror: Bool = false,
        openedForPlanning: Bool = false,
        initialPlanningPrompt: String? = nil,
        session: ChatSession? = nil,
        chatRepository: ChatRepositoryProtocol? = nil,
        userProfileRepository: UserProfileRepositoryProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        venusAI: VenusAIServiceProtocol? = nil,
        readinessEngine: ReadinessEngineProtocol? = nil,
        dailyPlanRepository: DailyPlanRepositoryProtocol? = nil
    ) {
        self.openedFromMirror = openedFromMirror
        self.openedForPlanning = openedForPlanning
        self.initialPlanningPrompt = initialPlanningPrompt
        self.currentSession = session ?? ChatSession()
        self.chatRepository = chatRepository ?? DependencyContainer.shared.makeChatRepository()
        self.userProfileRepository = userProfileRepository ?? DependencyContainer.shared.makeUserProfileRepository()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.notificationService = notificationService ?? DependencyContainer.shared.makeNotificationService()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeVenusAIService()
        self.readinessEngine = readinessEngine ?? DependencyContainer.shared.makeReadinessEngine()
        self.dailyPlanRepository = dailyPlanRepository ?? DependencyContainer.shared.makeDailyPlanRepository()
        
        if let session = session {
            self.messages = session.messages
        }
    }
    
    func setSelfKnowledgeLens(_ lens: SelfKnowledgeLens) {
        self.activeLens = lens
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    /// Mantido por compatibilidade de API. Não inicia loops infinitos: a animação
    /// da forma de onda é disparada apenas enquanto a gravação está ativa.
    func startAnimations() {
        particleAnimation = true
    }
    
    /// A autorização é pedida somente quando o usuário toca no microfone.
    func requestPermissions(completion: (@MainActor @Sendable (Bool) -> Void)? = nil) {
        SFSpeechRecognizer.requestAuthorization { status in
            let authorized = status == .authorized
            guard let completion else { return }
            Task { @MainActor in completion(authorized) }
        }
    }
    
    func loadInitialData() {
        guard !didLoadInitialData else { return }
        didLoadInitialData = true
        Task {
            do {
                self.userProfile = try await userProfileRepository.load()
                self.todayPlan = try? await dailyPlanRepository.getPlan(for: Date())
                
                if let tone = self.userProfile?.coachingTone.lowercased() {
                    if tone.contains("socrático") || tone.contains("socratico") {
                        self.activeLens = .socratic
                    } else if tone.contains("direto") {
                        self.activeLens = .contradictionRadar
                    }
                }
                
                // If it's a new empty session, generate welcome message or planning prompt
                if messages.isEmpty {
                    if let prompt = initialPlanningPrompt, !prompt.isEmpty {
                        sendMessage(text: prompt)
                    } else if openedForPlanning {
                        sendMessage(text: "Quero planejar minha rotina de hoje com a Venus.")
                    } else if openedFromMirror {
                        await generateMirrorInitialMessage()
                    } else {
                        await generateWelcomeMessage()
                    }
                }
            } catch {
                print("Erro ao carregar dados iniciais: \(error)")
                if messages.isEmpty {
                    await generateWelcomeMessage()
                }
            }
        }
    }
    
    private func generateWelcomeMessage() async {
        let name = userProfile?.name.isEmpty == false ? userProfile!.name : "você"
        let welcomeText = "Olá, \(name)! Sou a Venus, seu refúgio e espelho de bem-estar. Como você está se sentindo hoje? Estou aqui para te ouvir com todo carinho. 💜"
        
        let initialMessage = ChatMessage(
            content: welcomeText,
            isFromUser: false
        )
        
        messages.append(initialMessage)
        currentSession.addMessage(initialMessage)
        await saveCurrentSession()
    }
    
    private func generateMirrorInitialMessage() async {
        let name = userProfile?.name.isEmpty == false ? userProfile!.name : "você"
        let messageText = "Olá \(name), notei padrões interessantes na sua semana através do Espelho Comportamental. O que você gostaria de explorar hoje para transformar sentimentos em ação? 🪞"
        
        let initialMessage = ChatMessage(
            content: messageText,
            isFromUser: false
        )
        
        messages.append(initialMessage)
        currentSession.addMessage(initialMessage)
        await saveCurrentSession()
    }
    
    func sendMessage(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: trimmed,
            isFromUser: true,
            replyToId: replyingToMessage?.id,
            replyToContent: replyingToMessage?.content
        )
        
        replyingToMessage = nil
        
        // A mensagem do usuário e o indicador entram na mesma transição da Home:
        // o envio parece imediato e a resposta começa a chegar sem espera.
        withAnimation(Self.uiSpring) {
            messages.append(userMessage)
            currentSession.addMessage(userMessage)
            isVenusThinking = true
        }

        // Uma resposta por vez: cancela trabalho anterior antes de começar.
        cancelActiveResponse()

        let task = Task { @MainActor in
            // Refinamento emocional corre em paralelo, sem bloquear o stream.
            let emotionalTask = Task {
                if let refined = try? await venusAI.analyzeEmotionalState(message: trimmed) {
                    self.currentEmotionalState = refined
                }
            }
            activeEmotionalTask = emotionalTask

            do {
                // Snapshot imutável usado por todas as rotas desta resposta.
                let history = self.messages
                let lens = self.activeLens
                let profile = self.userProfile
                let planAtStart = self.todayPlan

                // Leituras independentes em paralelo (async let): menos tempo
                // até o primeiro token, sem bloquear o main actor.
                async let fetchedMoods = moodRepository.getAllMoods()
                async let fetchedPlan = dailyPlanRepository.getPlan(for: Date())

                let allMoods = (try? await fetchedMoods) ?? []
                let currentPlan = try? await fetchedPlan
                guard !Task.isCancelled else { return }

                let latestMood = allMoods.last
                let assessment = readinessEngine.evaluate(
                    todayMood: latestMood?.type,
                    todayMoodItem: latestMood,
                    weekMoods: allMoods,
                    hasRecentChat: true,
                    biometrics: nil,
                    chatImpact: nil,
                    aiStateTitle: nil,
                    aiStateSubtitle: nil
                )
                let diagnosis = SelfKnowledgeEngine.shared.diagnose(
                    userMessage: trimmed,
                    readiness: assessment,
                    recentMoods: allMoods,
                    userProfile: profile,
                    currentLens: lens
                )

                let pendingId: UUID?
                if DailyPlanEngine.shared.isPlanningConfirmationIntent(trimmed) {
                    pendingId = history.lastIndex(where: {
                        $0.planningProposal != nil &&
                        !($0.planningProposal?.proposedBlocks.isEmpty ?? true) &&
                        !($0.isPlanningConfirmed ?? false)
                    }).map { history[$0].id }
                } else {
                    pendingId = nil
                }
                let isPlanning = DailyPlanEngine.shared.isPlanningIntent(
                    text: trimmed,
                    hasActivePlan: currentPlan != nil
                )

                let analysis = VenusChatAnalysis(
                    moods: allMoods,
                    plan: currentPlan,
                    readiness: assessment,
                    diagnosis: diagnosis,
                    pendingProposalId: pendingId,
                    isPlanning: isPlanning
                )

                // Estado derivado aplicado de uma vez (uma invalidação só).
                self.todayPlan = analysis.plan ?? planAtStart
                self.currentReadiness = analysis.readiness
                self.lastDiagnosis = analysis.diagnosis

                if let pendingId = analysis.pendingProposalId {
                    withAnimation(Self.uiSpring) {
                        self.isVenusThinking = false
                    }
                    self.confirmPlanningProposal(for: pendingId)
                    return
                }

                if analysis.isPlanning {
                    var planningResponse = try await venusAI.generatePlanningResponse(
                        userMessage: trimmed,
                        conversationHistory: history,
                        userProfile: profile,
                        readiness: analysis.readiness,
                        recentMoods: analysis.moods,
                        currentPlan: self.todayPlan
                    )

                    if planningResponse.proposedBlocks.isEmpty {
                        let starters = DailyPlanEngine.shared.generateDefaultStarterProposedBlocks(
                            startingFrom: Date(),
                            readinessScore: analysis.readiness.score
                        )
                        planningResponse = AIPlanningResponse(
                            message: planningResponse.message.isEmpty ? "Montei uma estrutura de rotina para calibrar seu dia com calma:" : planningResponse.message,
                            intent: .createPlan,
                            proposedBlocks: starters,
                            reasoningSummary: "Rotina adaptada ao seu ritmo, com foco e pausas protegidas.",
                            questions: planningResponse.questions,
                            requiresConfirmation: true
                        )
                    }

                    withAnimation(Self.uiSpring) {
                        self.isVenusThinking = false
                    }

                    let venusMessageId = UUID()
                    let initialVenusMessage = ChatMessage(
                        id: venusMessageId,
                        content: "",
                        isFromUser: false,
                        planningProposal: planningResponse.proposedBlocks.isEmpty ? nil : planningResponse
                    )
                    withAnimation(Self.uiSpring) {
                        self.messages.append(initialVenusMessage)
                        self.currentSession.addMessage(initialVenusMessage)
                    }

                    await animateTypewriterForMessage(id: venusMessageId, text: planningResponse.message, speed: 0.015)
                    await saveCurrentSession()
                    return
                }

                try await streamAssistantResponse(
                    trimmed: trimmed,
                    history: history,
                    analysis: analysis,
                    lens: lens,
                    profile: profile
                )
                await saveCurrentSession()
            } catch {
                print("❌ ERRO na chamada da IA (OpenRouter Streaming): \(error)")
                
                withAnimation(Self.uiSpring) {
                    self.isVenusThinking = false
                    self.currentlyStreamingMessageId = nil
                }
                
                let friendlyErrorMessage: String
                if let aiError = error as? VenusAIError {
                    friendlyErrorMessage = aiError.userFriendlyMessage
                } else {
                    friendlyErrorMessage = "Desculpe, tive uma instabilidade temporária na minha conexão com a inteligência artificial. Logo isso será corrigido. Por favor, tente novamente em instantes. 💜"
                }
                
                await animateTypewriter(text: friendlyErrorMessage, speed: 0.018)
                await saveCurrentSession()
            }
        }
        activeResponseTask = task
    }

    /// Consome o stream em ator de background e publica texto bruto. O main
    /// actor aplica o filtro cacheado no máximo a cada 150 ms e escreve em
    /// `messages` somente quando o texto visível muda (~6x/s). A conclusão é
    /// sinalizada uma única vez — sem `scrollTo` por caractere.
    private func streamAssistantResponse(
        trimmed: String,
        history: [ChatMessage],
        analysis: VenusChatAnalysis,
        lens: SelfKnowledgeLens,
        profile: UserProfile?
    ) async throws {
        let stream = venusAI.generateStreamResponse(
            userMessage: trimmed,
            conversationHistory: history,
            userProfile: profile,
            checkInHistory: analysis.moods,
            readiness: analysis.readiness,
            activeLens: lens
        )

        let accumulator = VenusRawStream()
        let visibleCache = VenusVisibleTextCache()
        let consumer = Task.detached(priority: .utility) { [stream, accumulator] () -> Result<Bool, Error> in
            var receivedAny = false
            do {
                for try await chunk in stream {
                    if Task.isCancelled { break }
                    receivedAny = true
                    await accumulator.append(chunk)
                }
                await accumulator.finish()
                return .success(receivedAny)
            } catch {
                await accumulator.finish()
                return .failure(error)
            }
        }

        let venusMessageId = UUID()
        var messageCreated = false
        var messageIndex: Int?
        var sessionMessageIndex: Int?
        var lastApplied = ""

        defer {
            consumer.cancel()
            if Task.isCancelled {
                // Nova mensagem ou "parar": não deixa cursor/indicador presos.
                currentlyStreamingMessageId = nil
                isVenusThinking = false
            }
        }

        while !Task.isCancelled {
            let snapshot = await accumulator.snapshot()
            let visible = visibleCache.text(for: snapshot.text)

            if !messageCreated && !visible.isEmpty {
                let indices = createStreamingMessage(id: venusMessageId, content: visible)
                messageIndex = indices.message
                sessionMessageIndex = indices.session
                lastApplied = visible
                messageCreated = true
            } else if messageCreated && visible != lastApplied {
                lastApplied = visible
                // Só a célula em streaming muda. `currentSession` fica intacta
                // até a conclusão, para não invalidar o sheet a cada flush.
                setDisplayedContent(visible, messageIndex: messageIndex)
            }

            if snapshot.isFinished {
                let outcome = await consumer.value
                switch outcome {
                case .failure(let error):
                    throw error
                case .success(let receivedAny):
                    let finalText = VenusTextSanitizer.sanitize(snapshot.text)
                    if messageCreated {
                        setMessageContent(
                            finalText,
                            messageIndex: messageIndex,
                            sessionIndex: sessionMessageIndex
                        )
                    } else if !finalText.isEmpty {
                        let indices = createStreamingMessage(id: venusMessageId, content: finalText)
                        messageIndex = indices.message
                        sessionMessageIndex = indices.session
                        messageCreated = true
                    }

                    // Uma única transição de conclusão (haptic/scroll na View).
                    withAnimation(Self.uiSpring) {
                        currentlyStreamingMessageId = nil
                    }

                    if !receivedAny {
                        let rawResponse = try await venusAI.generateResponse(
                            userMessage: trimmed,
                            conversationHistory: history,
                            userProfile: profile,
                            checkInHistory: analysis.moods,
                            readiness: analysis.readiness,
                            activeLens: lens
                        )
                        let cleanResponse = VenusTextSanitizer.sanitize(rawResponse)
                        withAnimation(Self.uiSpring) {
                            isVenusThinking = false
                        }
                        await animateTypewriter(text: cleanResponse, speed: 0.018)
                    }
                }
                return
            }

            try? await Task.sleep(nanoseconds: pollIntervalNanos)
        }
    }

    /// Cancela analysis/stream/emoção anteriores. Chamado no início de cada
    /// envio e pelo botão "parar" do composer (API aditiva).
    func stopStreaming() {
        cancelActiveResponse()
        withAnimation(Self.uiSpring) {
            isVenusThinking = false
            currentlyStreamingMessageId = nil
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func cancelActiveResponse() {
        activeResponseTask?.cancel()
        activeResponseTask = nil
        activeEmotionalTask?.cancel()
        activeEmotionalTask = nil
    }

    func confirmPlanningProposal(for messageId: UUID) {
        guard let messageIndex = messages.firstIndex(where: { $0.id == messageId }),
              let proposal = messages[messageIndex].planningProposal,
              !proposal.proposedBlocks.isEmpty else { return }
        
        Task {
            let domainBlocks = DailyPlanEngine.shared.convertProposedBlocks(proposal.proposedBlocks, baseDate: Date())
            
            let newPlan: DailyPlan
            if let existing = self.todayPlan {
                newPlan = DailyPlanEngine.shared.reorganizeRemainderOfDay(
                    currentPlan: existing,
                    startingFrom: Date(),
                    newBlocks: domainBlocks,
                    readinessScore: self.currentReadiness?.score
                )
            } else {
                newPlan = DailyPlan(
                    date: Date(),
                    state: .active,
                    summary: proposal.reasoningSummary ?? "Plano do dia criado com a Venus",
                    blocks: domainBlocks
                )
            }
            
            try? await dailyPlanRepository.save(plan: newPlan)
            self.todayPlan = newPlan
            
            withAnimation(.spring(duration: 0.3)) {
                self.messages[messageIndex].isPlanningConfirmed = true
                if let sessionIndex = self.currentSession.messages.firstIndex(where: { $0.id == messageId }) {
                    self.currentSession.messages[sessionIndex].isPlanningConfirmed = true
                }
            }
            
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
            let confirmationText = "Plano confirmado e ativado com sucesso! 🌸 Você pode acompanhar, adicionar ou ajustar seus blocos na tela 'Meu dia'."
            let confirmationMessage = ChatMessage(content: confirmationText, isFromUser: false)
            withAnimation(Self.uiSpring) {
                self.messages.append(confirmationMessage)
                self.currentSession.addMessage(confirmationMessage)
            }
            await saveCurrentSession()
        }
    }
    
    // MARK: - Revelação em lotes (streaming, planejamento, fallback e erro)

    /// Cria a mensagem da Venus e devolve os índices já resolvidos, para que
    /// os flushes seguintes não repitam `firstIndex` na UI nem na sessão.
    private func createStreamingMessage(id: UUID, content: String) -> (message: Int?, session: Int?) {
        withAnimation(Self.uiSpring) {
            isVenusThinking = false
            let initialMessage = ChatMessage(id: id, content: content, isFromUser: false)
            currentlyStreamingMessageId = id
            messages.append(initialMessage)
            currentSession.addMessage(initialMessage)
        }
        return (
            messages.firstIndex(where: { $0.id == id }),
            currentSession.messages.firstIndex(where: { $0.id == id })
        )
    }

    /// Escreve só na cópia exibida. Usada a cada flush do streaming: tocar em
    /// `currentSession` aqui invalidaria também o sheet de detalhes.
    private func setDisplayedContent(_ content: String, messageIndex: Int?) {
        if let messageIndex, messages.indices.contains(messageIndex) {
            messages[messageIndex].content = content
        }
    }

    /// Escreve nas duas cópias uma única vez, na conclusão da resposta.
    private func setMessageContent(_ content: String, messageIndex: Int?, sessionIndex: Int?) {
        setDisplayedContent(content, messageIndex: messageIndex)
        if let sessionIndex, currentSession.messages.indices.contains(sessionIndex) {
            currentSession.messages[sessionIndex].content = content
        }
    }

    private func animateTypewriter(text: String, speed: Double) async {
        let venusMessageId = UUID()
        let initialMessage = ChatMessage(id: venusMessageId, content: "", isFromUser: false)
        
        withAnimation(Self.uiSpring) {
            messages.append(initialMessage)
            currentSession.addMessage(initialMessage)
        }
        
        await animateTypewriterForMessage(id: venusMessageId, text: text, speed: speed)
    }
    
    /// Fallback/erro/planejamento: blocos maiores a cada ~140 ms (mesma
    /// velocidade de leitura, ~1/3 das invalidações). O texto é limpo uma
    /// única vez e a sessão só é atualizada no fim.
    private func animateTypewriterForMessage(id: UUID, text: String, speed: Double) async {
        let messageIndex = messages.firstIndex(where: { $0.id == id })
        let sessionIndex = currentSession.messages.firstIndex(where: { $0.id == id })
        let visible = VenusTextSanitizer.sanitize(text)
        let blockSize = max(batchCharacterCount - 6, min(batchCharacterCount + 36, Int((speed * 1000).rounded()) * 3))
        
        withAnimation(Self.uiSpring) {
            currentlyStreamingMessageId = id
        }
        
        var revealed = 0
        var wasCancelled = false
        while revealed < visible.count {
            if Task.isCancelled {
                wasCancelled = true
                break
            }
            revealed = min(revealed + blockSize, visible.count)
            setDisplayedContent(String(visible.prefix(revealed)), messageIndex: messageIndex)
            try? await Task.sleep(nanoseconds: flushIntervalNanos)
        }
        if wasCancelled {
            currentlyStreamingMessageId = nil
            return
        }
        setMessageContent(visible, messageIndex: messageIndex, sessionIndex: sessionIndex)
        
        withAnimation(Self.uiSpring) {
            currentlyStreamingMessageId = nil
        }
    }
    
    func toggleReaction(for messageId: UUID) {
        guard let index = messages.firstIndex(where: { $0.id == messageId }) else { return }
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            if messages[index].reaction == "❤️" {
                messages[index].reaction = nil
            } else {
                messages[index].reaction = "❤️"
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            if let sessionMsgIndex = currentSession.messages.firstIndex(where: { $0.id == messageId }) {
                currentSession.messages[sessionMsgIndex].reaction = messages[index].reaction
            }
        }
        
        Task {
            await saveCurrentSession()
        }
    }
    
    func scheduleReminderNotification(text: String) {
        Task {
            _ = await notificationService.scheduleReminder(text: text, inSeconds: 3600)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            requestPermissions { [weak self] granted in
                guard let self else { return }
                if granted {
                    self.startRecording()
                } else {
                    self.showErrorMessage("Autorize o acesso ao microfone para gravar.")
                }
            }
        }
    }
    
    private func startRecording() {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            showErrorMessage("Reconhecimento de voz indisponível")
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else { return }
            recognitionRequest.shouldReportPartialResults = true
            
            let inputNode = audioEngine.inputNode
            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                guard let self = self else { return }
                
                if let result = result {
                    let transcribedText = result.bestTranscription.formattedString
                    if result.isFinal {
                        self.sendMessage(text: transcribedText)
                        self.stopRecording()
                    }
                }
                
                if error != nil {
                    self.stopRecording()
                }
            }
            
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.recognitionRequest?.append(buffer)
            }
            
            audioEngine.prepare()
            try audioEngine.start()
            
            withAnimation(.spring(response: 0.3)) {
                isRecording = true
                waveAnimation = true
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            showErrorMessage("Erro ao iniciar gravação")
            stopRecording()
        }
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        withAnimation(.spring(response: 0.3)) {
            isRecording = false
            waveAnimation = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    
    private func saveCurrentSession() async {
        do {
            try await chatRepository.saveSession(currentSession)
        } catch {
            print("Erro ao salvar sessão de chat: \(error)")
        }
    }
}
