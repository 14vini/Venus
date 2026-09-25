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
    
    private let chatRepository: ChatRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let notificationService: NotificationServiceProtocol
    private let venusAI: VenusAIServiceProtocol
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var userProfile: UserProfile?
    private let openedFromMirror: Bool
    private let lightHaptic = UIImpactFeedbackGenerator(style: .soft)
    
    init(
        openedFromMirror: Bool = false,
        session: ChatSession? = nil,
        chatRepository: ChatRepositoryProtocol? = nil,
        userProfileRepository: UserProfileRepositoryProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil,
        venusAI: VenusAIServiceProtocol? = nil
    ) {
        self.openedFromMirror = openedFromMirror
        self.currentSession = session ?? ChatSession()
        self.chatRepository = chatRepository ?? DependencyContainer.shared.makeChatRepository()
        self.userProfileRepository = userProfileRepository ?? DependencyContainer.shared.makeUserProfileRepository()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.notificationService = notificationService ?? DependencyContainer.shared.makeNotificationService()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeVenusAIService()
        
        if let session = session {
            self.messages = session.messages
        }
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
                
                // If it's a new empty session, generate welcome message
                if messages.isEmpty {
                    if openedFromMirror {
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
        
        await animateTypewriter(text: welcomeText, speed: 0.016)
    }
    
    private func generateMirrorInitialMessage() async {
        isVenusThinking = true
        do {
            let allMoods = try await moodRepository.getAllMoods()
            let mirrorText = try await venusAI.generateMirrorResume(checkInHistory: allMoods, userProfile: userProfile)
            
            self.isVenusThinking = false
            let cleanText = ThinkingStreamFilter.clean(mirrorText)
            await animateTypewriter(text: cleanText, speed: 0.018)
        } catch {
            print("Erro ao gerar resumo do espelho: \(error)")
            self.isVenusThinking = false
            await animateTypewriter(text: "Olá! Notei que você veio pelo Espelho de Autocuidado. Como posso te apoiar com suas reflexões de hoje?", speed: 0.018)
        }
    }
    
    private func animateTypewriter(text: String, speed: Double = 0.018) async {
        let messageId = UUID()
        let initialMessage = ChatMessage(id: messageId, content: "", isFromUser: false)
        
        self.currentlyStreamingMessageId = messageId
        withAnimation(.easeOut(duration: 0.25)) {
            self.messages.append(initialMessage)
            self.currentSession.addMessage(initialMessage)
        }
        
        var current = ""
        let chars = Array(text)
        for (i, char) in chars.enumerated() {
            current.append(char)
            if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                self.messages[index].content = current
                if let sessionIdx = self.currentSession.messages.firstIndex(where: { $0.id == messageId }) {
                    self.currentSession.messages[sessionIdx].content = current
                }
            }
            if i % 5 == 0 {
                lightHaptic.impactOccurred(intensity: 0.15)
            }
            try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            self.currentlyStreamingMessageId = nil
        }
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
                
                let stream = venusAI.generateStreamResponse(
                    userMessage: trimmed,
                    conversationHistory: messages,
                    userProfile: userProfile,
                    checkInHistory: allMoods
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
                        checkInHistory: allMoods
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
                }
                let fallbackResponse = self.generateFallbackResponse(for: trimmed)
                await animateTypewriter(text: fallbackResponse, speed: 0.018)
                await saveCurrentSession()
            }
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
            isRecording = true
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
        isRecording = false
        
        try? AVAudioSession.sharedInstance().setActive(false)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func scheduleReminderNotification(text: String) {
        Task {
            _ = await notificationService.scheduleReminder(text: text, inSeconds: 3600)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func saveCurrentSession() async {
        do {
            var sessions = try await chatRepository.loadSessions()
            if let index = sessions.firstIndex(where: { $0.id == currentSession.id }) {
                sessions[index] = currentSession
            } else {
                sessions.append(currentSession)
            }
            try await chatRepository.saveSessions(sessions)
        } catch {
            print("Erro ao salvar sessão: \(error)")
        }
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func generateFallbackResponse(for input: String) -> String {
        let lowercased = input.lowercased()
        
        if lowercased.contains("ansios") || lowercased.contains("ansiedade") {
            return "Sinto muito que você esteja sentindo isso. A ansiedade pode ser desafiadora. Que tal fazermos um exercício de respiração juntos? Inspire profundamente por 4 segundos, segure por 4 e expire por 6. Estou aqui com você. 🌿"
        } else if lowercased.contains("triste") || lowercased.contains("mal") {
            return "É completamente compreensível se sentir assim às vezes. Acolha seus sentimentos sem julgamentos. Se quiser desabafar mais, estou ouvindo com todo carinho. 💜"
        } else if lowercased.contains("cansa") || lowercased.contains("exaust") {
            return "Parece que seu corpo ou sua mente estão pedindo uma pausa. Lembre-se de ser gentil consigo mesmo hoje e priorizar o descanso quando possível. 🌙"
        } else {
            return "Estou te ouvindo com muita atenção. Cada emoção que você sente tem um propósito e faz parte da sua jornada. Me conte mais sobre isso se quiser. ✨"
        }
    }
}
