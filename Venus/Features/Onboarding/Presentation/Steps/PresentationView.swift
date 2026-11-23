//
//  PresentationView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct PresentationView: View {
    var onNext: () -> Void

    @State private var appear = false
    @State private var orbAppear = false
    @State private var mascotState: VenusMascotState = .welcoming
    @State private var mascotMood: MoodType = .happy

    /// Número da etapa com o mesmo degradê suave da jornada.
    private var numberGradient: LinearGradient {
        LinearGradient(
            colors: [OnboardingVisualPalette.lilac, OnboardingVisualPalette.rose],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OnboardingJourneyHeader(currentStep: 0)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05), value: appear)

                Spacer(minLength: 16)

                // Hero: Venus em código, com entrada suave.
                VenusMoodOrb(
                    mood: mascotMood,
                    state: mascotState,
                    size: 158,
                    showFace: true,
                    showHands: true,
                    showShadow: false,
                    isInteractive: true
                )
                .frame(width: 158, height: 158)
                .opacity(orbAppear ? 1 : 0)
                .scaleEffect(orbAppear ? 1 : 0.82)
                .animation(.spring(response: 0.7, dampingFraction: 0.68), value: orbAppear)

                Spacer(minLength: 16)

                // MARK: - Número da etapa
                VStack(spacing: 2) {
                    Text("DIA")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingVisualPalette.lilac)
                        .tracking(3.4)

                    Text("1")
                        .font(.system(size: 92, weight: .light, design: .rounded))
                        .foregroundStyle(numberGradient)
                        .contentTransition(.opacity)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.18), value: appear)

                // Uma frase curta: o visual conduz, o texto apenas acompanha.
                Text("No seu tempo, um passo de cada vez.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .padding(.horizontal, 40)
                    .padding(.top, 6)
                    .opacity(appear ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.28), value: appear)

                Spacer(minLength: 24)

                // MARK: - CTA escuro em pill
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onNext()
                } label: {
                    OnboardingJourneyCTALabel(title: "Começar", systemImage: "arrow.right")
                }
                .buttonStyle(OnboardingPressableButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 24)
                .animation(.spring(response: 0.6, dampingFraction: 0.78).delay(0.3), value: appear)
            }
        }
        .onAppear {
            orbAppear = true
            appear = true
        }
    }
}

#Preview {
    PresentationView(onNext: {})
}
