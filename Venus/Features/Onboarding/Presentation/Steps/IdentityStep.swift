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
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var inputName: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingStepHeader(
                eyebrow: "identidade",
                title: "Como posso te chamar?",
                subtitle: "Para criar conversas mais acolhedoras e naturais com você.",
                systemImage: "person.crop.circle.fill",
                tint: VenusTheme.primary,
                accessory: !inputName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "pronto" : nil
            )
            
            VenusCard(cornerRadius: 24, padding: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Seu nome ou apelido")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                    
                    TextField("Digite como prefere ser chamado(a)", text: $inputName)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .opacity(colorScheme == .dark ? 0.70 : 0.95)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(VenusTheme.primary.opacity(isInputFocused ? 0.6 : 0.15), lineWidth: 1.5)
                                )
                        )
                        .foregroundColor(VenusTheme.text)
                        .tint(VenusTheme.primary)
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
                    
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(VenusTheme.primary)
                        
                        Text("100% privado. Seu refúgio emocional é confidencial.")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onAppear {
            inputName = userProfile.name
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
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
