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

/// Estado compartilhado entre a leitura do stream e a revelação em lotes.
/// Mantido num ator isolado para evitar capturas mutáveis em closures Sendable.
@MainActor
private final class VenusStreamBuffer {
    var text = "" {
        didSet { cachedVisible = nil }
    }
    var isFinished = false

    private var cachedVisible: String?

    /// O filtro roda no máximo uma vez por novo chunk — nunca a cada tick do
    /// relógio. Sem cache, o regex de `clean` executaria ~50x/s no main actor.
    func visibleText() -> String {
        if let cachedVisible { return cachedVisible }
        let visible = ThinkingStreamFilter.clean(text)
        cachedVisible = visible
        return visible
    }
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

    // Revelação em lotes: escritas curtas e frequentes (≈18 escritas/s), sem
    // reconstruir a lista a cada caractere. A suavidade espelha a Home.
    private let flushIntervalNanos: UInt64 = 55_000_000
    private let batchCharacterCount = 18
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

        Task {
            // Refinamento emocional corre em paralelo, sem bloquear o stream.
            Task {
                if let refined = try? await venusAI.analyzeEmotionalState(message: trimmed) {
                    self.currentEmotionalState = refined
                }
            }

            do {
                // Duas leituras independentes em paralelo: menos tempo até o
                // primeiro token, sem trabalho extra no main actor.
                async let moods = moodRepository.getAllMoods()
                async let savedPlan = dailyPlanRepository.getPlan(for: Date())

                let allMoods = (try? await moods) ?? []
                if let currentPlan = try? await savedPlan {
                    self.todayPlan = currentPlan
                }

                let todayMood = allMoods.last?.type
                let todayMoodItem = allMoods.last
                let assessment = readinessEngine.evaluate(
                    todayMood: todayMood,
                    todayMoodItem: todayMoodItem,
                    weekMoods: allMoods,
                    hasRecentChat: true,
                    biometrics: nil,
                    chatImpact: nil,
                    aiStateTitle: nil,
                    aiStateSubtitle: nil
                )
                self.currentReadiness = assessment

                let diagnosis = SelfKnowledgeEngine.shared.diagnose(
                    userMessage: trimmed,
                    readiness: assessment,
                    recentMoods: allMoods,
                    userProfile: userProfile,
                    currentLens: activeLens
                )
                self.lastDiagnosis = diagnosis
                
                // Check if user is confirming a pending planning proposal from previous message
                let isConfirmation = DailyPlanEngine.shared.isPlanningConfirmationIntent(trimmed)
                if isConfirmation,
                   let pendingMessageIndex = self.messages.lastIndex(where: {
                       $0.planningProposal != nil &&
                       !($0.planningProposal?.proposedBlocks.isEmpty ?? true) &&
                       !($0.isPlanningConfirmed ?? false)
                   }) {
                    let pendingMessage = self.messages[pendingMessageIndex]
                    withAnimation(Self.uiSpring) {
                        self.isVenusThinking = false
                    }
                    self.confirmPlanningProposal(for: pendingMessage.id)
                    return
                }
                
                let isPlanning = DailyPlanEngine.shared.isPlanningIntent(
                    text: trimmed,
                    hasActivePlan: todayPlan != nil
                )
                
                if isPlanning {
                    // Call structured planning assistant
                    var planningResponse = try await venusAI.generatePlanningResponse(
                        userMessage: trimmed,
                        conversationHistory: messages,
                        userProfile: userProfile,
                        readiness: assessment,
                        recentMoods: allMoods,
                        currentPlan: todayPlan
                    )
                    
                    // If AI returned 0 blocks, supply balanced starter blocks so card is always provided
                    if planningResponse.proposedBlocks.isEmpty {
                        let starters = DailyPlanEngine.shared.generateDefaultStarterProposedBlocks(
                            startingFrom: Date(),
                            readinessScore: assessment.score
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
                
                // Normal streaming emotional / reflective chat
                let stream = venusAI.generateStreamResponse(
                    userMessage: trimmed,
                    conversationHistory: messages,
                    userProfile: userProfile,
                    checkInHistory: allMoods,
                    readiness: assessment,
                    activeLens: activeLens
                )
                
                var streamReceivedAny = false
                let venusMessageId = UUID()
                let streamBuffer = VenusStreamBuffer()
                
                // Revelação em lotes: o filtro e os `firstIndex` acontecem uma
                // vez por chunk; a UI só é tocada a cada ~60 ms.
                let revealTask = Task { @MainActor in
                    var messageCreated = false
                    var displayedCount = 0
                    var pollsSinceFlush = 0
                    var messageIndex: Int?
                    var sessionMessageIndex: Int?
                    
                    while !Task.isCancelled {
                        let visible = streamBuffer.visibleText()
                        
                        if !messageCreated && !visible.isEmpty {
                            let indices = self.createStreamingMessage(id: venusMessageId, content: visible)
                            messageIndex = indices.message
                            sessionMessageIndex = indices.session
                            displayedCount = visible.count
                            messageCreated = true
                        } else if messageCreated {
                            pollsSinceFlush += 1
                            if pollsSinceFlush >= 3 && visible.count != displayedCount {
                                displayedCount = visible.count
                                self.setMessageContent(
                                    visible,
                                    messageIndex: messageIndex,
                                    sessionIndex: sessionMessageIndex
                                )
                                pollsSinceFlush = 0
                            }
                        }
                        
                        if streamBuffer.isFinished {
                            let finalText = VenusTextSanitizer.sanitize(streamBuffer.text)
                            if messageCreated {
                                self.setMessageContent(
                                    finalText,
                                    messageIndex: messageIndex,
                                    sessionIndex: sessionMessageIndex
                                )
                            } else if !finalText.isEmpty {
                                let indices = self.createStreamingMessage(id: venusMessageId, content: finalText)
                                messageIndex = indices.message
                                sessionMessageIndex = indices.session
                                messageCreated = true
                            }
                            break
                        }
                        
                        try? await Task.sleep(nanoseconds: 20_000_000)
                    }
                }
                
                for try await chunk in stream {
                    streamReceivedAny = true
                    streamBuffer.text += chunk
                }
                
                streamBuffer.isFinished = true
                await revealTask.value
                
                withAnimation(Self.uiSpring) {
                    self.currentlyStreamingMessageId = nil
                }
                
                if !streamReceivedAny {
                    let rawResponse = try await venusAI.generateResponse(
                        userMessage: trimmed,
                        conversationHistory: messages,
                        userProfile: userProfile,
                        checkInHistory: allMoods,
                        readiness: assessment,
                        activeLens: activeLens
                    )
                    let cleanResponse = VenusTextSanitizer.sanitize(rawResponse)
                    
                    withAnimation(Self.uiSpring) {
                        self.isVenusThinking = false
                    }
                    await animateTypewriter(text: cleanResponse, speed: 0.018)
                }
                
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

    /// Escreve nas duas cópias da mensagem sem voltar a procurá-la pelo id.
    private func setMessageContent(_ content: String, messageIndex: Int?, sessionIndex: Int?) {
        if let messageIndex, messages.indices.contains(messageIndex) {
            messages[messageIndex].content = content
        }
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
    
    /// Texto completo revelado em blocos curtos a cada ~55 ms: a leitura flui
    /// sem travar a UI. Limpa uma única vez (pensamento, JSON e markdown cru
    /// nunca entram na mensagem) e sinaliza o cursor só no fim.
    private func animateTypewriterForMessage(id: UUID, text: String, speed: Double) async {
        let messageIndex = messages.firstIndex(where: { $0.id == id })
        let sessionIndex = currentSession.messages.firstIndex(where: { $0.id == id })
        let visible = VenusTextSanitizer.sanitize(text)
        let blockSize = max(batchCharacterCount - 4, min(batchCharacterCount + 12, Int((speed * 1000).rounded()) + 6))
        
        withAnimation(Self.uiSpring) {
            currentlyStreamingMessageId = id
        }
        
        var revealed = 0
        while revealed < visible.count {
            revealed = min(revealed + blockSize, visible.count)
            setMessageContent(
                String(visible.prefix(revealed)),
                messageIndex: messageIndex,
                sessionIndex: sessionIndex
            )
            try? await Task.sleep(nanoseconds: flushIntervalNanos)
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
