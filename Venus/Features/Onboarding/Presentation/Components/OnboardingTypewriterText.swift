//
//  OnboardingTypewriterText.swift
//  Venus
//
//  Texto dinâmico do onboarding com a mesma cadência suave das perguntas:
//  revelação caractere a caractere, cursor discreto e toque para revelar tudo.
//  Nunca exibe texto de processo da IA.
//

import SwiftUI

struct OnboardingTypewriterText: View {
    let text: String
    var font: Font = .system(size: 26, weight: .light, design: .rounded)
    var color: Color = VenusTheme.text
    var cursorColor: Color = OnboardingVisualPalette.lilac
    var lineSpacing: CGFloat = 2
    var alignment: TextAlignment = .leading
    var speedNanos: UInt64 = 12_000_000
    var showCursorWhenEmpty: Bool = false
    var hapticsEnabled: Bool = true
    var onRevealCompleted: (() -> Void)? = nil

    @State private var displayed: String = ""
    @State private var isRevealing: Bool = false
    @State private var cursorVisible: Bool = true
    @State private var generation: UInt = 0

    var body: some View {
        HStack(alignment: .top, spacing: 2) {
            if !displayed.isEmpty {
                Text(displayed)
                    .font(font)
                    .foregroundStyle(color)
                    .lineSpacing(lineSpacing)
                    .multilineTextAlignment(alignment)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isRevealing || showCursorWhenEmpty || displayed.isEmpty {
                Text("|")
                    .font(font.weight(.black))
                    .foregroundStyle(cursorColor)
                    .opacity(cursorVisible ? 1 : 0)
                    .animation(
                        .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
                        value: cursorVisible
                    )
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .contentTransition(.opacity)
        .animation(.spring(response: 0.42, dampingFraction: 0.8), value: text)
        .onTapGesture {
            revealAllImmediately()
        }
        .task(id: text) {
            await reveal(text)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityHidden(text.isEmpty)
    }

    // MARK: - Reveal

    @MainActor
    private func reveal(_ fullText: String) async {
        generation += 1
        let currentGeneration = generation

        guard !fullText.isEmpty else {
            displayed = ""
            isRevealing = false
            return
        }

        displayed = ""
        isRevealing = true
        cursorVisible = true
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }

        for character in fullText {
            guard !Task.isCancelled, generation == currentGeneration, isRevealing else { return }
            displayed.append(character)
            try? await Task.sleep(nanoseconds: speedNanos)
        }

        guard generation == currentGeneration else { return }
        isRevealing = false
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        onRevealCompleted?()
    }

    private func revealAllImmediately() {
        guard isRevealing else { return }
        generation += 1
        displayed = text
        isRevealing = false
        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
        onRevealCompleted?()
    }
}
