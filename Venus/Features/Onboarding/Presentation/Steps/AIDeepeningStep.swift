//
//  AIDeepeningStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI
import Speech
import AVFoundation

struct AIDeepeningStep: View {
    @Binding var userProfile: UserProfile
    let aiQuestion: AIOnboardingQuestionResponse?
    let isLoadingAI: Bool
    
    @State private var answerText: String = ""
    @State private var isRecording: Bool = false
    @State private var recordingPulse: Bool = false
    @FocusState private var isTextFocused: Bool
    
    private let speechService: SpeechRecognitionServiceProtocol = DependencyContainer.shared.makeSpeechRecognitionService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoadingAI {
                loadingView
            } else {
                questionContentView
            }
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .onAppear {
            if let existing = userProfile.improvementAreas.first {
                answerText = existing
            }
            speechService.requestPermissions()
            if !isLoadingAI {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFocused = true
                }
            }
        }
        .onChange(of: isLoadingAI) { _, loading in
            if !loading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFocused = true
                }
            }
        }
        .onDisappear {
            if isRecording {
                speechService.stopRecording()
                isRecording = false
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 30)
            
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(VenusTheme.primary)
                    
                    Text("Ouvindo com carinho o que você me contou...")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
        }
    }
    
    private var questionContentView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Empathy Reaction from Venus
            if let reaction = aiQuestion?.empathyReaction, !reaction.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(VenusTheme.primary)
                    
                    Text(reaction)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundColor(VenusTheme.text)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Dynamic Question Header
            OnboardingStepHeader(
                eyebrow: "aprofundando",
                title: aiQuestion?.nextQuestion ?? "O que mais tem ocupado seus pensamentos ultimamente?",
                subtitle: "Pode escrever com calma. Isso me ajuda a entender onde te dar mais apoio.",
                systemImage: "wand.and.stars",
                tint: VenusTheme.accentPurple
            )
            
            // Clean Borderless Input Area
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if answerText.isEmpty && !isRecording {
                        Text("Conte o que você gostaria de mudar, aliviar ou focar nos seus dias...")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $answerText)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .tint(VenusTheme.accentPurple)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 140, maxHeight: 220)
                        .focused($isTextFocused)
                        .onChange(of: answerText) { _, newValue in
                            userProfile.improvementAreas = [newValue]
                        }
                }
                
                // Voice and Clear Buttons
                HStack(spacing: 12) {
                    Button {
                        toggleVoiceRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text(isRecording ? "Ouvindo... Toque para parar" : "Falar por voz")
                                .font(.system(.footnote, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(isRecording ? VenusTheme.accentOrange : VenusTheme.accentPurple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: Capsule())
                        .scaleEffect(recordingPulse ? 1.05 : 1.0)
                        .animation(isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: recordingPulse)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    if !answerText.isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            answerText = ""
                            userProfile.improvementAreas = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(VenusTheme.textSecondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    private func toggleVoiceRecording() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if isRecording {
            speechService.stopRecording()
            isRecording = false
            recordingPulse = false
        } else {
            isTextFocused = false
            do {
                try speechService.startRecording(
                    onTextRecognized: { recognizedText in
                        DispatchQueue.main.async {
                            self.answerText = recognizedText
                            self.userProfile.improvementAreas = [recognizedText]
                        }
                    },
                    onError: { _ in
                        DispatchQueue.main.async {
                            self.isRecording = false
                            self.recordingPulse = false
                        }
                    }
                )
                isRecording = true
                recordingPulse = true
            } catch {
                isRecording = false
                recordingPulse = false
            }
        }
    }
}

#Preview {
    AIDeepeningStep(
        userProfile: .constant(UserProfile()),
        aiQuestion: AIOnboardingQuestionResponse(
            empathyReaction: "Entendo bem... demandas acumuladas pesam muito 💙",
            nextQuestion: "O que mais tem te impedido de desacelerar à noite?",
            suggestedTone: "Gentil"
        ),
        isLoadingAI: false
    )
    .background(VenusTheme.backgroundGradient)
}
