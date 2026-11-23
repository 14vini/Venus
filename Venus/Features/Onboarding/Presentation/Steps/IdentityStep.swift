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
    @State private var selectedGender: String = ""
    @FocusState private var isInputFocused: Bool
    
    private let genderOptions = [
        "Feminino",
        "Masculino",
        "Não-binário",
        "Outro",
        "Prefiro não dizer"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question Header
            Text("Como posso te chamar?")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
                .contentTransition(.opacity)
                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: userProfile.name)
            
            // Clean Borderless Name Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Digite seu nome...", text: $inputName)
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .tint(OnboardingVisualPalette.lilac)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.continue)
                    .focused($isInputFocused)
                    .onChange(of: inputName) { _, newValue in
                        userProfile.name = newValue
                    }
                    .onSubmit {
                        commitIdentity()
                        // Return avança quando o passo estiver completo; o container valida.
                        onSubmit?()
                    }
                    .accessibilityLabel("Seu nome")
                    .accessibilityHint("Pressione Return para continuar.")
                
                Rectangle()
                    .fill(isInputFocused ? OnboardingVisualPalette.lilac : VenusTheme.textSecondary.opacity(0.25))
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            }
            .padding(.top, 8)
            
            // Pronouns & Gender Identity Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Como você se identifica?")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.42, dampingFraction: 0.8), value: selectedGender)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(genderOptions, id: \.self) { option in
                        let isSelected = selectedGender == option
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedGender = option
                                userProfile.gender = option
                            }
                        } label: {
                            Text(option)
                                .font(.system(.subheadline, design: .rounded).weight(isSelected ? .semibold : .regular))
                                .foregroundColor(isSelected ? .white : VenusTheme.text)
                                .contentTransition(.opacity)
                                .animation(.spring(response: 0.42, dampingFraction: 0.8), value: isSelected)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(minHeight: 44)
                                .background {
                                    if isSelected {
                                        Capsule(style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [OnboardingVisualPalette.lilac, OnboardingVisualPalette.rose],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    } else {
                                        Capsule(style: .continuous)
                                            .glassEffect(.regular.interactive(), in: Capsule(style: .continuous))
                                    }
                                }
                        }
                        .buttonStyle(OnboardingPressableButtonStyle())
                        .accessibilityLabel(option)
                        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    }
                }
            }
            .padding(.top, 10)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .onAppear {
            inputName = userProfile.name
            selectedGender = userProfile.gender
        }
        .task {
            // Foco estável: cancelado se a pessoa sair da etapa antes disso.
            try? await Task.sleep(nanoseconds: 300_000_000)
            isInputFocused = true
        }
        .onDisappear {
            commitIdentity()
        }
    }
    
    private func commitIdentity() {
        userProfile.name = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.gender = selectedGender
    }
}

#Preview {
    IdentityStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
