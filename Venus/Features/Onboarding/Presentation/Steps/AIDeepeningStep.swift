//
//  AIDeepeningStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI

struct AIDeepeningStep: View {
    @Binding var text: String
    let aiQuestion: AIOnboardingQuestionResponse?
    let isLoadingAI: Bool
    let defaultQuestion: String
    let placeholder: String
    var tintColor: Color = VenusTheme.accentPurple
    
    @State private var displayedQuestion: String = ""
    @State private var isTyping: Bool = false
    @State private var cursorBlink: Bool = true
    @FocusState private var isTextFocused: Bool
    
    private var targetQuestion: String {
        aiQuestion?.nextQuestion ?? defaultQuestion
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            questionContentView
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .onAppear {
            cursorBlink = true
        }
        .task(id: "\(isLoadingAI)_\(targetQuestion)") {
            if !isLoadingAI && !targetQuestion.isEmpty {
                await runTypewriter(for: targetQuestion)
            }
        }
    }
    
    private var questionContentView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Empathy Reaction from Venus (limpo, sem emojis, sem travessao)
            if let reaction = aiQuestion?.empathyReaction, !reaction.isEmpty {
                Text(reaction)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(VenusTheme.text)
                    .lineSpacing(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Dynamic Question with Typewriter & Blinking Cursor (Sem texto de pensando)
            HStack(alignment: .top, spacing: 2) {
                if !displayedQuestion.isEmpty {
                    Text(displayedQuestion)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                
                if isTyping || isLoadingAI || displayedQuestion.isEmpty {
                    Text("|")
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(tintColor)
                        .opacity(cursorBlink ? 1 : 0)
                        .animation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true), value: cursorBlink)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Skip typing instantly on tap
                if isTyping {
                    displayedQuestion = targetQuestion
                    isTyping = false
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextFocused = true
                    }
                }
            }
            
            // Clean Borderless Floating Input Area (Always clear & focused)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.65))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .tint(tintColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 180, maxHeight: 300)
                    .focused($isTextFocused)
            }
            .padding(.top, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFocused = true
            }
        }
    }
    
    @MainActor
    private func runTypewriter(for fullText: String) async {
        guard !fullText.isEmpty else { return }
        
        displayedQuestion = ""
        isTyping = true
        cursorBlink = true
        
        // Haptic feedback on start loading/typing text
        let startHaptic = UIImpactFeedbackGenerator(style: .medium)
        startHaptic.prepare()
        startHaptic.impactOccurred()
        
        let typingHaptic = UIImpactFeedbackGenerator(style: .light)
        typingHaptic.prepare()
        
        var charCount = 0
        for char in fullText {
            guard isTyping else { break }
            displayedQuestion.append(char)
            charCount += 1
            
            // Subtle rhythmic vibration as text loads
            if char == " " || charCount % 7 == 0 {
                typingHaptic.impactOccurred(intensity: 0.6)
            }
            
            try? await Task.sleep(nanoseconds: 14_000_000) // 14ms per character (fluent & natural)
        }
        
        isTyping = false
        
        // Soft completion feedback
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        
        try? await Task.sleep(nanoseconds: 150_000_000)
        isTextFocused = true
    }
}

#Preview {
    AIDeepeningStep(
        text: .constant(""),
        aiQuestion: AIOnboardingQuestionResponse(
            empathyReaction: "Entender seu ritmo ajuda muito a calibrar seus picos de energia.",
            nextQuestion: "Como costuma ser a qualidade do seu sono e descanso?",
            suggestedTone: "Prático",
            hasEnoughContext: false
        ),
        isLoadingAI: false,
        defaultQuestion: "Como costuma ser o seu sono e descanso?",
        placeholder: "Conte sobre seu sono e momentos de recarregar a bateria..."
    )
    .background(VenusTheme.backgroundGradient)
}
