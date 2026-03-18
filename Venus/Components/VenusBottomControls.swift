//
//  VenusBottomControls.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusBottomControls: View {
    let currentStep: Int
    let canProceed: Bool
    let validationMessage: String
    let onBack: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Validation Message - Fixed Height
            Text(canProceed ? "" : validationMessage)
                .font(.caption)
                .foregroundColor(VenusTheme.textSecondary)
                .frame(height: 16)
                .multilineTextAlignment(.center)
            
            // Buttons
            HStack(spacing: 12) {
                // Back Button
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Voltar")
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(currentStep == 1 ? 0.1 : 0.25))
                    .foregroundColor(currentStep == 1 ? .gray : .primary)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(currentStep == 1 ? 0.2 : 0.5), lineWidth: 1)
                    )
                }
                .disabled(currentStep == 1)
                
                // Next Button
                Button(action: onNext) {
                    HStack(spacing: 6) {
                        Text(currentStep == 7 ? "Concluir" : "Próximo")
                            .font(.callout)
                            .fontWeight(.semibold)
                        Image(systemName: currentStep == 7 ? "checkmark.circle.fill" : "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        canProceed ? VenusTheme.darkGreen : Color.gray.opacity(0.5)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                }
                .disabled(!canProceed)
            }
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
    }
}

#Preview {
    VStack {
        Spacer()
        VenusBottomControls(
            currentStep: 1,
            canProceed: false,
            validationMessage: "Digite seu nome para continuar",
            onBack: {},
            onNext: {}
        )
    }
    .background(VenusTheme.backgroundGradient)
}