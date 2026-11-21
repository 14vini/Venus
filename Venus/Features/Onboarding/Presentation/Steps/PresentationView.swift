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

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                OnboardingJourneyHeader(currentStep: 0)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : -10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.82).delay(0.05), value: appear)

                Spacer(minLength: 12)

                // Hero: Venus em código, com entrada suave.
                VenusMoodOrb(
                    mood: mascotMood,
                    state: mascotState,
                    size: 148,
                    showFace: true,
                    showHands: true,
                    showShadow: false,
                    isInteractive: true
                )
                .frame(width: 148, height: 148)
                .opacity(orbAppear ? 1 : 0)
                .scaleEffect(orbAppear ? 1 : 0.82)
                .animation(.spring(response: 0.7, dampingFraction: 0.68), value: orbAppear)

                VStack(spacing: 6) {
                    Text("Dia 1")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)

                    Text("SUA JORNADA COMEÇA")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(OnboardingVisualPalette.lilac)
                        .tracking(1.6)
                }
                .opacity(appear ? 1 : 0)
                .offset(y: appear ? 0 : 12)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.18), value: appear)
                .padding(.top, 12)

                Text("Venus foi feita para caminhar com você.\nUm passo de cada vez, no seu ritmo.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .opacity(appear ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).delay(0.28), value: appear)

                Spacer(minLength: 16)

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
