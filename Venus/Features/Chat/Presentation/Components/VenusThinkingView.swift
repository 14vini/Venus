//
//  VenusThinkingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

/// Indicador de que a Venus está preparando uma resposta: apenas o mascot em
/// pose `.thinking` com uma aura pulsante sutil. Sem texto, sem pontos, sem
/// qualquer linguagem de processo.
struct VenusThinkingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(VenusChatVisualStyle.aura.opacity(colorScheme == .dark ? 0.16 : 0.26))
                    .frame(width: 58, height: 58)
                    .blur(radius: 13)
                    .scaleEffect(isPulsing ? 1.14 : 0.92)
                    .opacity(isPulsing ? 0.85 : 0.40)
                    .accessibilityHidden(true)

                VenusMoodOrb(
                    state: .thinking,
                    size: 42,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
            }
            .frame(width: 58, height: 58)
            .accessibilityLabel("Venus")
            .onAppear {
                guard !isPulsing else { return }
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusThinkingView()
            .padding(20)
    }
}
