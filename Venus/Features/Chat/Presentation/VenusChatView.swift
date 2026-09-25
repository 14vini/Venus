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
                                    Text(replyingTo.isFromUser ? "Respondendo a você" : "Respondendo à Venus")
                                        .font(.caption2)
                                        .bold()
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
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(VenusTheme.surface.opacity(0.8))
                            .cornerRadius(8)
                            .padding(.horizontal, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        // Input Field Card
                        HStack(spacing: 8) {
                            TextField("Como posso te apoiar hoje?", text: $inputText, axis: .vertical)
                                .lineLimit(1...4)
                                .focused($isTextFieldFocused)
                                .font(.body)
                            
                            // Clear text button (inside TextField)
                            if !inputText.isEmpty {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        inputText = ""
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 17))
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
