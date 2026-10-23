//
//  VenusChatView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusChatView: View {
    @State private var viewModel: VenusChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(openedFromMirror: Bool = false, session: ChatSession? = nil) {
        _viewModel = State(initialValue: VenusChatViewModel(openedFromMirror: openedFromMirror, session: session))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                VenusReadingBackground(dayMoment: .current, isAnimated: true)
                
                ZStack(alignment: .bottom) {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                // Banner do Radar de Contradições se detectado
                                if let dissonance = viewModel.lastDiagnosis?.dissonance {
                                    HStack(spacing: 8) {
                                        Image(systemName: "bolt.shield.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 13, weight: .bold))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dissonance.type.badgeLabel)
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundColor(VenusTheme.text)
                                            
                                            Text(dissonance.headline)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                                .foregroundColor(VenusTheme.textSecondary)
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
                                                .foregroundColor(VenusTheme.textSecondary)
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
                                        }
                                    )
                                    .id(message.id)
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
                            .padding(.top, 4)
                            .padding(.bottom, 140)
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
                    }
                    
                    // Floating Input Bar
                    VStack(spacing: 10) {
                        if viewModel.isRecording {
                            HStack(spacing: 8) {
                                Image(systemName: "waveform")
                                    .foregroundColor(.red)
                                    .scaleEffect(viewModel.waveAnimation ? 1.2 : 0.8)
                                    .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: viewModel.waveAnimation)
                                
                                Text("Gravando... Toque no microfone para parar")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .glassEffect(.regular, in: Capsule(style: .continuous))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Reply Bar Preview
                        if let replyingTo = viewModel.replyingToMessage {
                            HStack(spacing: 8) {
                                Rectangle()
                                    .fill(VenusTheme.primary)
                                    .frame(width: 3)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(replyingTo.isFromUser ? "Você" : "Venus")
                                        .font(.caption2.bold())
                                        .foregroundColor(VenusTheme.primary)
                                    
                                    Text(replyingTo.content)
                                        .font(.caption)
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Button {
                                    viewModel.replyingToMessage = nil
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundColor(VenusTheme.textSecondary)
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
                                .foregroundColor(VenusTheme.text)
                                .focused($isTextFieldFocused)
                            
                            // Clear text button (only shows when user has typed something)
                            if !inputText.isEmpty {
                                Button {
                                    inputText = ""
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(VenusTheme.textSecondary)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Dismiss keyboard button (right next to textfield when keyboard is active)
                            if isTextFieldFocused {
                                Button {
                                    isTextFieldFocused = false
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "keyboard.chevron.compact.down")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(VenusTheme.textSecondary)
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
                                            .foregroundColor(viewModel.isRecording ? .red : VenusTheme.textSecondary)
                                    }
                                }
                                
                                Button {
                                    guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                                    let text = inputText
                                    inputText = ""
                                    viewModel.sendMessage(text: text)
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? VenusTheme.primary.opacity(0.4) : VenusTheme.primary)
                                            .frame(width: 34, height: 34)
                                        
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
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
            }
            .navigationTitle("Venus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(VenusTheme.text)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section("Lentes de Autoconhecimento") {
                            ForEach(SelfKnowledgeLens.allCases) { lens in
                                Button {
                                    viewModel.setSelfKnowledgeLens(lens)
                                } label: {
                                    Label(lens.title, systemImage: lens.iconName)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: viewModel.activeLens.iconName)
                                .font(.system(size: 11, weight: .bold))
                            Text(viewModel.activeLens.shortTitle)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(viewModel.activeLens.badgeColor.opacity(0.18), in: Capsule())
                        .foregroundColor(viewModel.activeLens.badgeColor)
                    }
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
    }
}

#Preview {
    VenusChatView()
}
