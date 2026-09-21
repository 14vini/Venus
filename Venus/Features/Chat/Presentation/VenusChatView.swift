//
//  VenusChatView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: VenusChatViewModel
    @State private var messageText = ""
    @State private var showHistory = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(openedFromMirror: Bool = false, session: ChatSession? = nil) {
        _viewModel = State(initialValue: VenusChatViewModel(openedFromMirror: openedFromMirror, session: session))
    }
    
    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
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
                    
                    HStack(spacing: 12) {
                        VenusMoodOrb(
                            mood: headerMascotMood,
                            state: headerMascotState,
                            size: 40,
                            showFace: true,
                            isInteractive: true
                        )
                        
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
                
                // Messages & Input container
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                if viewModel.messages.isEmpty {
                                    VenusWelcomeMessage()
                                        .padding(.top, 40)
                                        .padding(.bottom, 16)
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                                
                                ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, message in
                                    let isPrevSame = index > 0 && viewModel.messages[index - 1].isFromUser == message.isFromUser
                                    let isNextSame = index < viewModel.messages.count - 1 && viewModel.messages[index + 1].isFromUser == message.isFromUser
                                    
                                    ChatMessageView(
                                        message: message,
                                        isPrevSame: isPrevSame,
                                        isNextSame: isNextSame,
                                        onReact: {
                                            viewModel.toggleReaction(for: message.id)
                                        },
                                        onReply: {
                                            viewModel.replyingToMessage = message
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        },
                                        onScheduleReminder: { reminder in
                                            viewModel.scheduleReminderNotification(text: reminder)
                                        }
                                    )
                                    .id(message.id)
                                }
                                
                                if let emotionalState = viewModel.currentEmotionalState {
                                    EmotionalInsightsView(
                                        emotionalState: emotionalState
                                    ) { suggestion in
                                        messageText = suggestion
                                        sendMessage()
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                                
                                if viewModel.isVenusThinking {
                                    VenusThinkingView()
                                        .id("thinking")
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .leading)
                                                .combined(with: .scale(scale: 0.4, anchor: .topLeading))
                                                .combined(with: .opacity),
                                            removal: .opacity
                                        ))
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 140)
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                if let lastMessage = viewModel.messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isVenusThinking) { _, isThinking in
                            if isThinking {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                                    proxy.scrollTo("thinking", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Floating Input Bar Overlay
                    VStack(spacing: 12) {
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
                            .glassEffect(.regular, in: Capsule(style: .continuous))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        if let replyMsg = viewModel.replyingToMessage {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Respondendo a \(replyMsg.isFromUser ? "Você" : "Venus")")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(VenusTheme.primary)
                                    
                                    Text(replyMsg.content)
                                        .font(.caption)
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.replyingToMessage = nil
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(VenusTheme.textSecondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        HStack(spacing: 8) {
                            if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                HStack(spacing: 12) {
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(VenusTheme.textSecondary)
                                    }
                                    
                                    Button(action: {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 18))
                                            .foregroundColor(VenusTheme.textSecondary)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            HStack(spacing: 8) {
                                TextField("Fale com Venus...", text: $messageText, axis: .vertical)
                                    .font(.body)
                                    .foregroundColor(VenusTheme.text)
                                    .lineLimit(1...5)
                                    .focused($isTextFieldFocused)
                                    .onSubmit {
                                        sendMessage()
                                    }
                                
                                if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button(action: {
                                        viewModel.toggleVoiceRecording()
                                    }) {
                                        Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(viewModel.isRecording ? .red : VenusTheme.textSecondary)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .scaleEffect(isTextFieldFocused ? 1.015 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTextFieldFocused)
                            
                            if !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button(action: sendMessage) {
                                    Text("Enviar")
                                        .font(.body)
                                        .fontWeight(.bold)
                                        .foregroundColor(VenusTheme.primary)
                                        .padding(.horizontal, 8)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                VenusTheme.background.opacity(0.15),
                                VenusTheme.background.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    )
                    .allowsHitTesting(true)
                }
            }
        }
        .onAppear {
            viewModel.startAnimations()
            viewModel.requestPermissions()
            viewModel.loadInitialData()
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
    
    private var headerMascotMood: MoodType {
        guard let state = viewModel.currentEmotionalState else { return .calm }
        switch state.primaryEmotion {
        case .happy, .excited, .grateful: return .happy
        case .sad, .lonely: return .sad
        case .anxious, .stressed, .angry, .frustrated: return .stressed
        case .neutral: return .calm
        }
    }
    
    private var headerMascotState: VenusMascotState {
        if viewModel.isVenusThinking { return .thinking }
        guard let state = viewModel.currentEmotionalState else { return .idle }
        switch state.primaryEmotion {
        case .happy, .excited, .grateful: return .celebrating
        case .sad, .lonely, .anxious, .stressed, .angry, .frustrated: return .empathetic
        case .neutral: return .idle
        }
    }
}
