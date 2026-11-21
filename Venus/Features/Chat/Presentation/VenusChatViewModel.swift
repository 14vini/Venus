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
    private let lightHaptic = UIImpactFeedbackGenerator(style: .soft)
    
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
    
    func startAnimations() {
        withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
            particleAnimation = true
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            waveAnimation = true
        }
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
    }
    
    func loadInitialData() {
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
        
        withAnimation(.easeOut(duration: 0.25)) {
            messages.append(userMessage)
            currentSession.addMessage(userMessage)
        }
        
        withAnimation(.easeOut(duration: 0.25)) {
            isVenusThinking = true
        }
        
        Task {
            // Asynchronously refine emotional state if needed
            Task {
                if let refined = try? await venusAI.analyzeEmotionalState(message: trimmed) {
                    self.currentEmotionalState = refined
                }
            }
            
            do {
                let allMoods = (try? await moodRepository.getAllMoods()) ?? []
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
                
                // Refresh todayPlan before processing
                if let currentPlan = try? await dailyPlanRepository.getPlan(for: Date()) {
                    self.todayPlan = currentPlan
                }
                
                // Check if user is confirming a pending planning proposal from previous message
                let isConfirmation = DailyPlanEngine.shared.isPlanningConfirmationIntent(trimmed)
                if isConfirmation,
                   let pendingMessageIndex = self.messages.lastIndex(where: {
                       $0.planningProposal != nil &&
                       !($0.planningProposal?.proposedBlocks.isEmpty ?? true) &&
                       !($0.isPlanningConfirmed ?? false)
                   }) {
                    let pendingMessage = self.messages[pendingMessageIndex]
                    withAnimation(.easeOut(duration: 0.25)) {
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
                    
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.isVenusThinking = false
                    }
                    
                    let venusMessageId = UUID()
                    let initialVenusMessage = ChatMessage(
                        id: venusMessageId,
                        content: "",
                        isFromUser: false,
                        planningProposal: planningResponse.proposedBlocks.isEmpty ? nil : planningResponse
                    )
                    
                    withAnimation(.easeOut(duration: 0.25)) {
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
                var messageCreated = false
                let venusMessageId = UUID()
                var fullReceivedText = ""
                var displayedCharacterCount = 0
                var streamFinished = false
                
                // Concurrent typing engine that smoothly discharges characters
                let typingTask = Task { @MainActor in
                    while !Task.isCancelled {
                        let cleanFull = ThinkingStreamFilter.clean(fullReceivedText)
                        
                        if displayedCharacterCount < cleanFull.count {
                            if !messageCreated {
                                messageCreated = true
                                withAnimation(.easeOut(duration: 0.25)) {
                                    self.isVenusThinking = false
                                    let initialVenusMessage = ChatMessage(id: venusMessageId, content: "", isFromUser: false)
                                    self.currentlyStreamingMessageId = venusMessageId
                                    self.messages.append(initialVenusMessage)
                                    self.currentSession.addMessage(initialVenusMessage)
                                }
                            }
                            
                            displayedCharacterCount += 1
                            let prefixString = String(cleanFull.prefix(displayedCharacterCount))
                            
                            if let index = self.messages.firstIndex(where: { $0.id == venusMessageId }) {
                                self.messages[index].content = prefixString
                                if let sessionIndex = self.currentSession.messages.firstIndex(where: { $0.id == venusMessageId }) {
                                    self.currentSession.messages[sessionIndex].content = prefixString
                                }
                            }
                            
                            if displayedCharacterCount % 5 == 0 {
                                self.lightHaptic.impactOccurred(intensity: 0.15)
                            }
                            
                            let pending = cleanFull.count - displayedCharacterCount
                            let sleepNs: UInt64 = pending > 40 ? 4_000_000 : (pending > 15 ? 9_000_000 : 16_000_000)
                            try? await Task.sleep(nanoseconds: sleepNs)
                        } else if streamFinished {
                            break
                        } else {
                            try? await Task.sleep(nanoseconds: 15_000_000)
                        }
                    }
                }
                
                for try await chunk in stream {
                    streamReceivedAny = true
                    fullReceivedText += chunk
                }
                
                streamFinished = true
                await typingTask.value
                
                // Final clean-up of the message content
                if let index = self.messages.firstIndex(where: { $0.id == venusMessageId }) {
                    let cleaned = ThinkingStreamFilter.clean(self.messages[index].content)
                    self.messages[index].content = cleaned
                    if let sessionIndex = self.currentSession.messages.firstIndex(where: { $0.id == venusMessageId }) {
                        self.currentSession.messages[sessionIndex].content = cleaned
                    }
                }
                
                withAnimation(.easeOut(duration: 0.2)) {
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
                    let cleanResponse = ThinkingStreamFilter.clean(rawResponse)
                    
                    withAnimation(.easeOut(duration: 0.25)) {
                        self.isVenusThinking = false
                    }
                    await animateTypewriter(text: cleanResponse, speed: 0.018)
                }
                
                await saveCurrentSession()
            } catch {
                print("❌ ERRO na chamada da IA (OpenRouter Streaming): \(error)")
                
                withAnimation(.easeOut(duration: 0.25)) {
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
            withAnimation(.easeOut(duration: 0.25)) {
                self.messages.append(confirmationMessage)
                self.currentSession.addMessage(confirmationMessage)
            }
            await saveCurrentSession()
        }
    }
    
    private func animateTypewriter(text: String, speed: Double) async {
        let venusMessageId = UUID()
        let initialMessage = ChatMessage(id: venusMessageId, content: "", isFromUser: false)
        
        withAnimation(.easeOut(duration: 0.25)) {
            messages.append(initialMessage)
            currentSession.addMessage(initialMessage)
        }
        
        await animateTypewriterForMessage(id: venusMessageId, text: text, speed: speed)
    }
    
    private func animateTypewriterForMessage(id: UUID, text: String, speed: Double) async {
        var currentText = ""
        for char in text {
            currentText.append(char)
            if let index = messages.firstIndex(where: { $0.id == id }) {
                messages[index].content = currentText
                if let sessionIndex = currentSession.messages.firstIndex(where: { $0.id == id }) {
                    currentSession.messages[sessionIndex].content = currentText
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
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
            startRecording()
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
