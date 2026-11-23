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
    var onContinue: (() -> Void)? = nil
    
    @FocusState private var isTextFocused: Bool
    
    private var targetQuestion: String {
        VenusTextSanitizer.sanitize(aiQuestion?.nextQuestion ?? defaultQuestion)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            questionContentView
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
    }
    
    private var questionContentView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Empathy Reaction from Venus (limpo, sem emojis, sem travessao)
            if let reaction = aiQuestion?.empathyReaction, !reaction.isEmpty {
                Text(VenusTextSanitizer.sanitize(reaction))
                    .font(.system(.subheadline, design: .rounded).weight(.regular))
                    .foregroundColor(VenusTheme.text)
                    .lineSpacing(2)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: reaction)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Pergunta dinâmica com a mesma máquina de escrever das demais etapas.
            // Enquanto a IA responde, só o cursor aparece — nunca "gerando...".
            OnboardingTypewriterText(
                text: targetQuestion,
                font: .system(size: 26, weight: .light, design: .rounded),
                color: VenusTheme.text,
                cursorColor: tintColor,
                showCursorWhenEmpty: isLoadingAI,
                onRevealCompleted: focusEditorAfterReveal
            )
            
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
                    .submitLabel(.done)
                    .keyboardDoneToolbar(
                        primaryTitle: onContinue == nil ? nil : "Avançar",
                        primaryAction: onContinue
                    )
                    .focused($isTextFocused)
                    .accessibilityLabel("Sua resposta")
                    .accessibilityHint("Toque para escrever; o botão OK fecha o teclado.")
            }
            .padding(.top, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFocused = true
            }
        }
    }
    
    /// Foca o campo quando a pergunta termina de aparecer (ou é revelada com um toque).
    private func focusEditorAfterReveal() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            isTextFocused = true
        }
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
