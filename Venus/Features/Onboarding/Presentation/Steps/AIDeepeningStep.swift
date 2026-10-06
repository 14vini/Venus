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
    
    @FocusState private var isTextFocused: Bool
    
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
        .padding(.top, 20)
        .onAppear {
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
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            HStack {
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(VenusTheme.primary)
                    
                    Text("Conectando com o que você me contou...")
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
            
            // Dynamic Question Header (sem subtítulo)
            Text(aiQuestion?.nextQuestion ?? defaultQuestion)
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            // Clean Borderless Input Area (sem background, sem voz)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.55))
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
        }
    }
}

#Preview {
    AIDeepeningStep(
        text: .constant(""),
        aiQuestion: AIOnboardingQuestionResponse(
            empathyReaction: "Entender seu ritmo ajuda muito a calibrar seus picos de energia ⚡",
            nextQuestion: "Como costuma ser a qualidade do seu sono e descanso?",
            suggestedTone: "Prático"
        ),
        isLoadingAI: false,
        defaultQuestion: "Como costuma ser o seu sono e descanso?",
        placeholder: "Conte sobre seu sono e momentos de recarregar a bateria..."
    )
    .background(VenusTheme.backgroundGradient)
}
