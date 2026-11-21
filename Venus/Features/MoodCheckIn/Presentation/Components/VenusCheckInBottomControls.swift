//
//  VenusCheckInBottomControls.swift
//  Venus
//
//  Barra inferior minimalista com indicador de etapas em pílula
//  e botão flutuante de avançar, adaptado para modo claro e escuro.
//

import SwiftUI

struct VenusCheckInBottomControls: View {
    let currentStep: Int
    let totalSteps: Int
    var isNextEnabled: Bool = true
    var isLoading: Bool = false
    var onNext: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var accentColor: Color {
        colorScheme == .dark ? Color(hex: "60A5FA") : Color(hex: "4B72C7")
    }

    private var buttonBackground: Color {
        colorScheme == .dark ? Color(hex: "1C2A3E").opacity(0.92) : Color.white.opacity(0.92)
    }

    private var iconColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "233A66")
    }

    var body: some View {
        HStack {
            // Indicador de Progresso (Pill + Dots)
            HStack(spacing: 6) {
                ForEach(1...totalSteps, id: \.self) { step in
                    if step == currentStep {
                        Capsule()
                            .fill(accentColor)
                            .frame(width: 22, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                    } else {
                        Circle()
                            .fill(
                                step < currentStep
                                    ? accentColor.opacity(0.65)
                                    : accentColor.opacity(0.24)
                            )
                            .frame(width: 6, height: 6)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentStep)
                    }
                }
            }
            .padding(.leading, 8)

            Spacer()

            // Botão Flutuante de Avançar
            Button {
                guard isNextEnabled && !isLoading else { return }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onNext()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(buttonBackground)
                        .frame(width: 54, height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(
                            color: colorScheme == .dark ? Color.black.opacity(0.35) : Color(hex: "4A6EB0").opacity(0.18),
                            radius: 10,
                            x: 0,
                            y: 4
                        )

                    if isLoading {
                        ProgressView()
                            .tint(iconColor)
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(isNextEnabled ? iconColor : iconColor.opacity(0.35))
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!isNextEnabled || isLoading)
            .opacity(isNextEnabled ? 1.0 : 0.6)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }
}
