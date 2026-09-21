//
//  VenusChatViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

@Observable
@MainActor
final class VenusChatViewModel {
    var messages: [ChatMessage] = []
    var isVenusThinking: Bool = false
    var isRecording: Bool = false
    var particleAnimation: Bool = false
    var waveAnimation: Bool = false
    var showError: Bool = false
    var errorMessage: String = ""
    var currentEmotionalState: EmotionalState?
    var replyingToMessage: ChatMessage?
    
    let openedFromMirror: Bool
    
    private var currentSession: ChatSession
    private let repository: ChatRepositoryProtocol
    private let venusAI: GeminiServiceProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let profileRepository: UserProfileRepositoryProtocol
    private let speechService: SpeechRecognitionServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var userProfile: UserProfile?
    
    init(
        openedFromMirror: Bool = false,
        session: ChatSession? = nil,
        repository: ChatRepositoryProtocol? = nil,
        venusAI: GeminiServiceProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil,
        profileRepository: UserProfileRepositoryProtocol? = nil,
        speechService: SpeechRecognitionServiceProtocol? = nil,
        notificationService: NotificationServiceProtocol? = nil
    ) {
        self.openedFromMirror = openedFromMirror
        self.repository = repository ?? DependencyContainer.shared.makeChatRepository()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeGeminiService()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.profileRepository = profileRepository ?? DependencyContainer.shared.makeUserProfileRepository()
        self.speechService = speechService ?? DependencyContainer.shared.makeSpeechRecognitionService()
        self.notificationService = notificationService ?? DependencyContainer.shared.makeNotificationService()
        
        if let session = session {
            self.currentSession = session
            self.messages = session.messages
        } else {
            self.currentSession = ChatSession()
            self.messages = []
        }
    }
    
    func startAnimations() {
        particleAnimation = true
    }
    
    func requestPermissions() {
        speechService.requestPermissions()
    }
    
    func loadInitialData() {
        Task {
            do {
                if let profile = try await profileRepository.load() {
                    self.userProfile = profile
                }
                
                let allMoods = try await moodRepository.getAllMoods()
                
                if openedFromMirror && messages.isEmpty {
                    isVenusThinking = true
                    
                    do {
                        let resumeText = try await venusAI.generateMirrorResume(
                            checkInHistory: allMoods,
                            userProfile: userProfile
                        )
                        
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            self.isVenusThinking = false
                            let venusMessage = ChatMessage(content: resumeText, isFromUser: false)
                            self.messages.append(venusMessage)
                            self.currentSession.addMessage(venusMessage)
                        }
                    } catch {
                        print("Error generating mirror resume: \(error)")
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            self.isVenusThinking = false
                            let greeting = "Olá! Percebi que você veio do seu Espelho. Analisando seus registros recentes, vejo que estamos passando por algumas oscilações. Como posso te ajudar a organizar esses sentimentos agora?"
                            let venusMessage = ChatMessage(content: greeting, isFromUser: false)
                            self.messages.append(venusMessage)
                            self.currentSession.addMessage(venusMessage)
                        }
                    }
                }
            } catch {
                print("Error loading initial data: \(error)")
            }
        }
    }
    
    func sendMessage(_ content: String) {
        let replyMsg = replyingToMessage
        
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            let userMessage = ChatMessage(
                content: content,
                isFromUser: true,
                replyToId: replyMsg?.id,
                replyToContent: replyMsg?.content
            )
            messages.append(userMessage)
            currentSession.addMessage(userMessage)
            replyingToMessage = nil
        }
        
        isVenusThinking = true
        
        Task {
            do {
                let emotionalState = try await venusAI.analyzeEmotionalState(message: content)
                self.currentEmotionalState = emotionalState
                
                let allMoods = try await moodRepository.getAllMoods()
                
                let venusResponse = try await venusAI.generateResponse(
                    userMessage: content,
                    conversationHistory: messages,
                    userProfile: userProfile,
                    checkInHistory: allMoods
                )
                
                let (parsedContent, summary, tags, reminder) = self.parseResponse(venusResponse)
                
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    self.isVenusThinking = false
                    let venusMessage = ChatMessage(
                        content: parsedContent,
                        isFromUser: false,
                        summary: summary,
                        tags: tags,
                        reminder: reminder
                    )
                    self.messages.append(venusMessage)
                    self.currentSession.addMessage(venusMessage)
                }
                
                await saveCurrentSession()
            } catch {
                print("❌ ERRO na chamada do Gemini: \(error)")
                
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    self.isVenusThinking = false
                    
                    let fallbackResponse = self.generateFallbackResponse(for: content)
                    let (parsedContent, summary, tags, reminder) = self.parseResponse(fallbackResponse)
                    let venusMessage = ChatMessage(
                        content: parsedContent,
                        isFromUser: false,
                        summary: summary,
                        tags: tags,
                        reminder: reminder
                    )
                    self.messages.append(venusMessage)
                    self.currentSession.addMessage(venusMessage)
                }
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
    
    func toggleVoiceRecording() {
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            waveAnimation = false
        } else {
            do {
                try speechService.startRecording(
                    onTextRecognized: { [weak self] text in
                        Task { @MainActor in
                            guard let self else { return }
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                self.sendMessage(text)
                            }
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor in
                            self?.showErrorAlert(message: error.localizedDescription)
                        }
                    }
                )
                isRecording = true
                waveAnimation = true
            } catch {
                showErrorAlert(message: "Reconhecimento de voz indisponível")
            }
        }
    }
    
    func clearChat() {
        Task {
            await saveCurrentSession()
        }
        messages.removeAll()
        currentSession = ChatSession()
    }
    
    func loadSession(_ session: ChatSession) {
        currentSession = session
        messages = session.messages
    }
    
    func loadUserProfile(_ profile: UserProfile) {
        userProfile = profile
    }
    
    func scheduleReminderNotification(text: String) {
        Task {
            let scheduled = await notificationService.scheduleReminder(text: text, inSeconds: 3600)
            if scheduled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func saveCurrentSession() async {
        guard !currentSession.messages.isEmpty else { return }
        
        do {
            var sessions = try await repository.loadSessions()
            
            if let index = sessions.firstIndex(where: { $0.id == currentSession.id }) {
                sessions[index] = currentSession
            } else {
                sessions.append(currentSession)
            }
            
            try await repository.saveSessions(sessions)
        } catch {
            print("Error saving session: \(error)")
        }
    }
    
    private func showErrorAlert(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func parseResponse(_ response: String) -> (content: String, summary: String?, tags: [String]?, reminder: String?) {
        guard let data = response.data(using: .utf8) else {
            return (response, nil, nil, nil)
        }
        
        do {
            let json = try JSONDecoder().decode(AIChatResponse.self, from: data)
            return (json.response, json.summary, json.tags, json.reminder)
        } catch {
            return (response, nil, nil, nil)
        }
    }
    
    private func generateFallbackResponse(for userMessage: String) -> String {
        let lowercased = userMessage.lowercased()
        
        if lowercased.contains("olá") || lowercased.contains("oi") {
            return "Olá! É um prazer conversar com você. Como você está se sentindo hoje? Que tal começarmos com uma respiração profunda? 😊"
        }
        
        if lowercased.contains("ansiedade") || lowercased.contains("ansioso") {
            return "Entendo sua ansiedade. Vamos tentar juntos: respire fundo por 4 segundos, segure por 4, e solte por 6. Isso pode ajudar a acalmar. 🌸"
        }
        
        if lowercased.contains("triste") || lowercased.contains("tristeza") {
            return "Sua tristeza é válida. Às vezes precisamos sentir para curar. Que tal escrever sobre o que está sentindo ou ouvir uma música reconfortante? 💙"
        }
        
        if lowercased.contains("obrigado") || lowercased.contains("obrigada") {
            return "Fico muito feliz em estar aqui com você! Lembre-se: você é mais forte do que imagina. 💜"
        }
        
        let responses = [
            "Obrigada por compartilhar isso comigo. Como você está se sentindo? Que tal fazermos uma respiração consciente juntos? 🌱",
            "Entendo. Às vezes ajuda colocar os pensamentos para fora. Que tal escrever sobre o que está passando pela sua mente? ✍️",
            "Estou aqui para você. Que tal começarmos com três respirações profundas para nos centrarmos? 💙"
        ]
        
        return responses.randomElement() ?? "Como posso te ajudar hoje? 💜"
    }
}
