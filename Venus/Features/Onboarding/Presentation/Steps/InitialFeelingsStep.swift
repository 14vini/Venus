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
            // Question Header (sem subtítulo)
            Text("Como você está se sentindo, \(displayName)?")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            // Clean Borderless Input Area (sem background, sem voz)
            ZStack(alignment: .topLeading) {
                if textInput.isEmpty {
                    Text("Escreva aqui o que está passando pela sua cabeça ou como seu corpo está se sentindo hoje...")
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary.opacity(0.55))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $textInput)
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .tint(VenusTheme.accentBlue)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 180, maxHeight: 300)
                    .focused($isTextFocused)
                    .onChange(of: textInput) { _, newValue in
                        userProfile.contextNote = newValue
                        userProfile.primaryGoal = newValue
                    }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            textInput = userProfile.contextNote
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTextFocused = true
            }
        }
    }
}

#Preview {
    InitialFeelingsStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
