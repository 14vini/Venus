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
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            // Clean Borderless Name Input
            VStack(alignment: .leading, spacing: 8) {
                TextField("Digite seu nome...", text: $inputName)
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
                        commitIdentity()
                        if !userProfile.gender.isEmpty {
                            onSubmit?()
                        }
                    }
                
                Rectangle()
                    .fill(isInputFocused ? VenusTheme.primary : VenusTheme.textSecondary.opacity(0.25))
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            }
            .padding(.top, 8)
            
            // Pronouns & Gender Identity Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Como você se identifica?")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.textSecondary)
                
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
                                .font(.system(.subheadline, design: .rounded).weight(isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? .white : VenusTheme.text)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    isSelected ? VenusTheme.primaryGradient : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .shadow(color: isSelected ? VenusTheme.primary.opacity(0.25) : .clear, radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(option)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isInputFocused = true
            }
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
