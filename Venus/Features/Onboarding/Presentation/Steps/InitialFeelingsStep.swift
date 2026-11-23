//
//  InitialFeelingsStep.swift
//  Venus
//
//  Created by Kaua on 06/10/26.
//

import SwiftUI

struct InitialFeelingsStep: View {
    @Binding var userProfile: UserProfile
    var onContinue: (() -> Void)? = nil
    
    @State private var textInput: String = ""
    @FocusState private var isTextFocused: Bool
    
    private var displayName: String {
        userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "hoje" : userProfile.name
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Pergunta curta: sem explicações longas ao lado da máquina de escrever.
            Text("Como tem sido sua rotina, \(displayName)?")
                .font(.system(size: 26, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: displayName)
            
            // Clean Borderless Input Area (sem background, sem voz)
            ZStack(alignment: .topLeading) {
                if textInput.isEmpty {
                    Text("Conte um pouco sobre os seus dias...")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.55))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $textInput)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .tint(OnboardingVisualPalette.lilac)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 180, maxHeight: 300)
                    .submitLabel(.done)
                    .keyboardDoneToolbar(primaryTitle: onContinue == nil ? nil : "Avançar", primaryAction: onContinue)
                    .focused($isTextFocused)
                    .onChange(of: textInput) { _, newValue in
                        userProfile.contextNote = newValue
                    }
                    .accessibilityLabel("Sua rotina e ocupações")
                    .accessibilityHint("O botão OK fecha o teclado; Avançar segue para a próxima etapa.")
            }
            
            .padding(.top, 8)
             
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            textInput = userProfile.contextNote
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            isTextFocused = true
        }
    }
}

#Preview {
    InitialFeelingsStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
