//
//  WelcomeStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct WelcomeStep: View {
    @Binding var userProfile: UserProfile
    var onSubmit: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    @State private var inputName: String = ""
    @State private var showGreeting = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Mascot
            VenusMascot3DCute(mood: .happy, size: 240)
                .padding(.top, 8)
                .opacity(showGreeting ? 1 : 0)
                .scaleEffect(showGreeting ? 1 : 0.82)
                .animation(.spring(response: 0.6, dampingFraction: 0.72), value: showGreeting)

            // Greeting
            VStack(spacing: 6) {
                Text("Oi! Eu sou a Venus 👋")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .multilineTextAlignment(.center)

                Text("Não é terapia, mas é terapêutico.")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showGreeting ? 1 : 0)
            .offset(y: showGreeting ? 0 : 12)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: showGreeting)
            .padding(.top, 4)
            .padding(.bottom, 32)

            // Name card
            VenusCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Qual é o seu nome?")
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(VenusTheme.text)

                    TextField("Digite seu nome", text: $inputName)
                        .padding(16)
                        .background(nameFieldBackground)
                        .foregroundColor(VenusTheme.text)
                        .tint(VenusTheme.primary)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .submitLabel(.next)
                        .focused($isInputFocused)
                        .onChange(of: inputName) { _, newValue in
                            userProfile.name = newValue
                        }
                        .onSubmit {
                            commitName()
                            onSubmit?()
                        }
                        .accessibilityLabel("Nome")
                        .accessibilityHint("Digite seu nome para personalizar sua experiência")

                    Text("Seu nome nos ajuda a personalizar sua experiência")
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
            .opacity(showGreeting ? 1 : 0)
            .offset(y: showGreeting ? 0 : 16)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.28), value: showGreeting)
        }
        .padding(.bottom, 20)
        .onAppear {
            inputName = userProfile.name
            showGreeting = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
        .onDisappear {
            commitName()
        }
    }

    private var nameFieldBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.70 : 0.96)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22),
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .blendMode(.overlay)
            )
    }

    private func commitName() {
        let normalized = inputName.trimmingCharacters(in: .whitespacesAndNewlines)
        if inputName != normalized { inputName = normalized }
        userProfile.name = normalized
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        WelcomeStep(userProfile: .constant(UserProfile()))
    }
}
