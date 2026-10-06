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
        VStack(alignment: .leading, spacing: 20) {
            // Question Header (sem subtítulo)
            Text("Como posso te chamar?")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)
            
            // Clean Borderless Input
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
                        commitName()
                        onSubmit?()
                    }
                
                Rectangle()
                    .fill(isInputFocused ? VenusTheme.primary : VenusTheme.textSecondary.opacity(0.25))
                    .frame(height: 1.5)
                    .animation(.easeInOut(duration: 0.2), value: isInputFocused)
            }
            .padding(.top, 16)
            
            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
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
