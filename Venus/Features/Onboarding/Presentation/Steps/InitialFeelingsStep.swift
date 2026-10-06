//
//  InitialFeelingsStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI
import Speech
import AVFoundation

struct InitialFeelingsStep: View {
    @Binding var userProfile: UserProfile
    var onContinue: (() -> Void)? = nil
    
    @State private var textInput: String = ""
    @State private var isRecording: Bool = false
    @State private var recordingPulse: Bool = false
    @FocusState private var isTextFocused: Bool
    
    private let speechService: SpeechRecognitionServiceProtocol = DependencyContainer.shared.makeSpeechRecognitionService()
    
    private let suggestionPrompts = [
        "Semana corrida e mente cheia",
        "Noites mal dormidas e cansaço",
        "Ansiedade e autocobrança",
        "Buscando mais leveza e paz"
    ]
    
    private var displayName: String {
        userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "hoje" : userProfile.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question Header
            OnboardingStepHeader(
                eyebrow: "como você está",
                title: "Como você está se sentindo, \(displayName)?",
                subtitle: "Sem filtro e sem julgamentos. Pode desabafar o que estiver no seu coração.",
                systemImage: "heart.fill",
                tint: VenusTheme.accentBlue
            )
            
            // Clean Borderless Input Area
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topLeading) {
                    if textInput.isEmpty && !isRecording {
                        Text("Conte como tem sido seus dias, o que está na sua cabeça ou como seu corpo está se sentindo...")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary.opacity(0.6))
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $textInput)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .tint(VenusTheme.accentBlue)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 140, maxHeight: 220)
                        .focused($isTextFocused)
                        .onChange(of: textInput) { _, newValue in
                            userProfile.contextNote = newValue
                            userProfile.primaryGoal = newValue
                        }
                }
                
                // Minimal Voice and Clear Row
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
                        .foregroundStyle(isRecording ? VenusTheme.accentOrange : VenusTheme.accentBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .glassEffect(.regular, in: Capsule())
                        .scaleEffect(recordingPulse ? 1.05 : 1.0)
                        .animation(isRecording ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: recordingPulse)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    if !textInput.isEmpty {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            textInput = ""
                            userProfile.contextNote = ""
                            userProfile.primaryGoal = ""
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
            
            // Quick suggestions chips
            VStack(alignment: .leading, spacing: 8) {
                Text("Inspirações rápidas:")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestionPrompts, id: \.self) { prompt in
                            Button {
                                UISelectionFeedbackGenerator().selectionChanged()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    textInput = prompt
                                    userProfile.contextNote = prompt
                                    userProfile.primaryGoal = prompt
                                }
                            } label: {
                                Text(prompt)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundColor(textInput == prompt ? .white : VenusTheme.text)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(
                                        textInput == prompt ? VenusTheme.accentBlue : Color.clear,
                                        in: Capsule()
                                    )
                                    .glassEffect(textInput == prompt ? .clear : .regular.interactive(), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .onAppear {
            textInput = userProfile.contextNote
            speechService.requestPermissions()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFocused = true
            }
        }
        .onDisappear {
            if isRecording {
                speechService.stopRecording()
                isRecording = false
            }
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
                            self.textInput = recognizedText
                            self.userProfile.contextNote = recognizedText
                            self.userProfile.primaryGoal = recognizedText
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
    InitialFeelingsStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
