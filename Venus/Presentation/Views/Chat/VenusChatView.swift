//
//  VenusChatView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI
import Combine
import Speech
import AVFoundation

struct VenusChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VenusChatViewModel()
    @State private var messageText = ""
    @State private var showHistory = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            // Background gradient
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            // Floating particles
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(VenusTheme.primary.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...800)
                    )
                    .scaleEffect(viewModel.particleAnimation ? 1.5 : 0.5)
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: viewModel.particleAnimation
                    )
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Circle()
                            .fill(VenusTheme.surface)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(VenusTheme.text)
                            )
                    }
                    
                    Spacer()
                    
                    // Venus Avatar
                    HStack(spacing: 12) {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [VenusTheme.primary, VenusTheme.secondary],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                            .scaleEffect(viewModel.isVenusThinking ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: viewModel.isVenusThinking)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Venus")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(VenusTheme.text)
                            
                            Text(viewModel.isVenusThinking ? "Pensando..." : "Online")
                                .font(.caption)
                                .foregroundColor(viewModel.isVenusThinking ? VenusTheme.primary : .green)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { showHistory = true }) {
                        Circle()
                            .fill(VenusTheme.surface)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(VenusTheme.text)
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.messages.isEmpty {
                                VenusWelcomeMessage()
                                    .padding(.top, 40)
                            }
                            
                            ForEach(viewModel.messages) { message in
                                ChatMessageView(message: message)
                                    .id(message.id)
                            }
                            
                            // Emotional insights
                            if let emotionalState = viewModel.currentEmotionalState {
                                EmotionalInsightsView(
                                    emotionalState: emotionalState
                                ) { suggestion in
                                    messageText = suggestion
                                    sendMessage()
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            if viewModel.isVenusThinking {
                                VenusThinkingView()
                                    .id("thinking")
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            if let lastMessage = viewModel.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isVenusThinking) { isThinking in
                        if isThinking {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo("thinking", anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        // Text input
                        HStack {
                            TextField("Digite aqui", text: $messageText, axis: .vertical)
                                .focused($isTextFieldFocused)
                                .font(.body)
                                .foregroundColor(VenusTheme.text)
                                .lineLimit(1...4)
                            
                            if !messageText.isEmpty {
                                Button(action: sendMessage) {
                                    Circle()
                                        .fill(VenusTheme.primaryGradient)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "arrow.up")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(VenusTheme.surface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(VenusTheme.chipBorder, lineWidth: 1)
                                )
                        )
                        
                        // Voice input button
                        Button(action: viewModel.toggleVoiceRecording) {
                            Circle()
                                .fill(viewModel.isRecording ? AnyShapeStyle(Color.red) : AnyShapeStyle(VenusTheme.primaryGradient))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                                .scaleEffect(viewModel.isRecording ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: viewModel.isRecording)
                        }
                    }
                    
                    // Voice recording indicator
                    if viewModel.isRecording {
                        HStack(spacing: 8) {
                            Image(systemName: "waveform")
                                .foregroundColor(.red)
                                .scaleEffect(viewModel.waveAnimation ? 1.2 : 0.8)
                                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: viewModel.waveAnimation)
                            
                            Text("Gravando... Toque para parar")
                                .font(.subheadline)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(VenusTheme.surface)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            viewModel.startAnimations()
            viewModel.requestPermissions()
        }
        .sheet(isPresented: $showHistory) {
            ChatHistoryView { session in
                viewModel.loadSession(session)
                showHistory = false
            }
        }
        .alert("Erro", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        viewModel.sendMessage(messageText)
        messageText = ""
        isTextFieldFocused = false
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                Text(message.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(VenusTheme.primaryGradient)
                    .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                    .frame(maxWidth: 300, alignment: .trailing)
            } else {
                HStack(alignment: .top, spacing: 12) {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [VenusTheme.primary, VenusTheme.secondary],
                                center: .center,
                                startRadius: 5,
                                endRadius: 15
                            )
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "sparkles")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(VenusTheme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(VenusTheme.surface)
                        )
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                        .frame(maxWidth: 300, alignment: .leading)
                }
                
                Spacer()
            }
        }
    }
}

struct VenusWelcomeMessage: View {
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [VenusTheme.primary, VenusTheme.secondary, VenusTheme.tertiary],
                        center: .center,
                        startRadius: 20,
                        endRadius: 60
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                )
                .scaleEffect(animateText ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateText)
            
            VStack(spacing: 12) {
                Text("Olá! Sou a Venus ✨")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(VenusTheme.text)
                
                Text("Estou aqui para conversar sobre bem-estar, mindfulness e te ajudar em sua jornada de autoconhecimento. Como posso te ajudar hoje?")
                    .font(.body)
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            animateText = true
        }
    }
}

struct VenusThinkingView: View {
    @State private var animateDots = false
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [VenusTheme.primary, VenusTheme.secondary],
                            center: .center,
                            startRadius: 5,
                            endRadius: 15
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(VenusTheme.primary.opacity(0.6))
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateDots ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animateDots
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(VenusTheme.surface)
                )
            }
            
            Spacer()
        }
        .onAppear {
            animateDots = true
        }
    }
}

@MainActor
class VenusChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isVenusThinking = false
    @Published var isRecording = false
    @Published var particleAnimation = false
    @Published var waveAnimation = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var currentEmotionalState: EmotionalState?
    
    private var currentSession = ChatSession()
    private let repository: ChatRepositoryProtocol = DependencyContainer.shared.makeChatRepository()
    private let venusAI = VenusAIService()
    private var userProfile: UserProfile?
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pt-BR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func startAnimations() {
        particleAnimation = true
        
        // Testar API Key na inicialização
        Task {
            print("🔑 Testando conexão com Gemini...")
            await APIKeyTester.testAPIKey()
        }
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }
    
    func sendMessage(_ content: String) {
        let userMessage = ChatMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        currentSession.addMessage(userMessage)
        
        isVenusThinking = true
        
        Task {
            do {
                // Analyze emotional state
                let emotionalState = try await venusAI.analyzeEmotionalState(message: content)
                await MainActor.run {
                    self.currentEmotionalState = emotionalState
                }
                
                // Generate AI response
                let venusResponse = try await venusAI.generateResponse(
                    userMessage: content,
                    conversationHistory: messages,
                    userProfile: userProfile
                )
                
                await MainActor.run {
                    self.isVenusThinking = false
                    let venusMessage = ChatMessage(content: venusResponse, isFromUser: false)
                    self.messages.append(venusMessage)
                    self.currentSession.addMessage(venusMessage)
                }
                
                await saveCurrentSession()
                
            } catch {
                print("❌ ERRO na chamada do Gemini: \(error)")
                
                await MainActor.run {
                    self.isVenusThinking = false
                    
                    // Mostrar erro específico para debug
                    if error.localizedDescription.contains("API_KEY_INVALID") {
                        self.showError(message: "API Key inválida. Verifique a configuração.")
                    } else if error.localizedDescription.contains("quota") {
                        self.showError(message: "Limite de quota excedido.")
                    } else {
                        print("🔄 Tentando resposta de fallback...")
                    }
                    
                    let fallbackResponse = self.generateFallbackResponse(for: content)
                    let venusMessage = ChatMessage(content: fallbackResponse, isFromUser: false)
                    self.messages.append(venusMessage)
                    self.currentSession.addMessage(venusMessage)
                }
            }
        }
    }
    
    func toggleVoiceRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            showError(message: "Reconhecimento de voz não disponível")
            return
        }
        
        try? AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try? audioEngine.start()
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if result != nil {
                DispatchQueue.main.async {
                    // We'll handle the final result when stopping
                }
            }
            
            if error != nil {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        isRecording = true
        waveAnimation = true
    }
    
    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        
        // Get the final transcription
        // Get final transcription from stored result
        // Note: In a real implementation, you'd store the final result
        let finalTranscription = "Texto transcrito" // Placeholder
        if !finalTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sendMessage(finalTranscription)
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecording = false
        waveAnimation = false
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
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
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



extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VenusChatView()
}
