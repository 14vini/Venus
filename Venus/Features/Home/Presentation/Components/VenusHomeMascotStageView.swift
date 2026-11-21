//
//  VenusHomeMascotStageView.swift
//  Venus
//
//  F10 — slot central: a Venus no lugar da silhueta, com brilho suave ao redor.
//  F12 — volta da Venus desenhada em código (VenusMoodOrb); 3D descartado.
//

import SwiftUI

/// Palco da Venus na metade superior da tela. O loading da F5 troca apenas o estado
/// do avatar para `.thinking`, sem texto de processo e sem pontos.
struct VenusHomeMascotStageView: View {
    let isLoading: Bool
    let size: CGFloat
    var mood: MoodType? = nil

    @Environment(\.colorScheme) private var colorScheme
    @State private var floating = false

    var body: some View {
        ZStack {
            // Aura suave — luz difusa em lilás/rosa, não sombra.
            RadialGradient(
                colors: [
                    Color(hex: "E7D8F5").opacity(colorScheme == .dark ? 0.20 : 0.52),
                    Color(hex: "F3C9DC").opacity(colorScheme == .dark ? 0.09 : 0.22),
                    Color.clear
                ],
                center: .center,
                startRadius: size * 0.10,
                endRadius: size * 0.74
            )
            .frame(width: size * 1.9, height: size * 1.9)
            .blur(radius: 16)

            VenusMoodOrb(
                mood: mood,
                state: isLoading ? .thinking : .idle,
                size: size,
                showShadow: false,
                isInteractive: false
            )
            .frame(width: size, height: size)
            .offset(y: floating ? -5 : 5)
            .animation(.easeInOut(duration: 3.6).repeatForever(autoreverses: true), value: floating)
        }
        .frame(width: size * 1.9, height: size * 1.15)
        .onAppear { floating = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Venus")
    }
}

#Preview {
    VenusHomeMascotStageView(isLoading: false, size: 200)
        .padding()
}
