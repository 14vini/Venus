//
//  VenusThinkingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//
//  Indicador discreto de que a Venus está preparando a resposta: só o mascot
//  com aura suave. Sem texto, sem pontos e sem linguagem de processo.
//

import SwiftUI

struct VenusThinkingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(VenusChatVisualStyle.aura.opacity(colorScheme == .dark ? 0.16 : 0.24))
                    .frame(width: 50, height: 50)
                    .blur(radius: 12)
                    .scaleEffect(isPulsing ? 1.12 : 0.92)
                    .opacity(isPulsing ? 0.7 : 0.35)
                    .accessibilityHidden(true)

                VenusMoodOrb(
                    state: .thinking,
                    size: 36,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
            }
            .frame(width: 50, height: 50)
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
