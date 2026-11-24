//
//  VenusThinkingView.swift
//  Venus
//
//  Indicador de espera: Venus pequena e aura pulsante em lilás/rosa.
//  Sem texto, sem pontos, sem linguagem de processo — a conversa fica limpa.
//

import SwiftUI

struct VenusThinkingView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(VenusChatVisualStyle.aura.opacity(isDark ? 0.18 : 0.28))
                    .frame(width: 44, height: 44)
                    .blur(radius: 11)
                    .scaleEffect(isPulsing ? 1.14 : 0.9)
                    .opacity(isPulsing ? 0.75 : 0.3)

                Circle()
                    .fill(VenusChatVisualStyle.rose.opacity(isDark ? 0.12 : 0.2))
                    .frame(width: 34, height: 34)
                    .blur(radius: 9)
                    .offset(x: 5, y: 5)
                    .scaleEffect(isPulsing ? 0.92 : 1.08)
                    .opacity(isPulsing ? 0.6 : 0.25)

                VenusMoodOrb(
                    state: .thinking,
                    size: 32,
                    showHands: false,
                    showShadow: false,
                    isInteractive: false
                )
            }
            .frame(width: 44, height: 44)
            .accessibilityLabel("Venus")

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 20)
        .onAppear {
            guard !isPulsing else { return }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    ZStack {
        VenusChatBackground()
        VenusThinkingView()
            .padding(20)
    }
}
