//
//  IdentityStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

struct IdentityStep: View {
    @Binding var userProfile: UserProfile
    var onSubmit: (() -> Void)? = nil
    
    @State private var inputName: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header / Question
            OnboardingStepHeader(
                eyebrow: "apresentação",
                title: "Como posso te chamar?",
                subtitle: "Para conversarmos com intimidade e carinho.",
                systemImage: "person.crop.circle.fill",
                tint: VenusTheme.primary
            )
            
            // Clean Borderless Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Digite seu nome ou apelido...", text: $inputName)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .tint(VenusTheme.primary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.done)
                    .focused($isInputFocused)
                    .onChange(of: inputName) { _, newValue in
                        userProfile.name = newValue
                    }
                    .onSubmit {
                        commitName()
                        onSubmit?()
                    }
                
                Rectangle()
                    .fill(isInputFocused ? VenusTheme.primary : VenusTheme.textSecondary.opacity(0.25))
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            }
            .padding(.top, 12)
            
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(VenusTheme.primary.opacity(0.8))
                
                Text("100% privado. Seu refúgio emocional é confidencial.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
            }
            .padding(.top, 4)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .onAppear {
            inputName = userProfile.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
        }
        .onDisappear {
            commitName()
        }
    }
    
    private func commitName() {
        userProfile.name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    IdentityStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
