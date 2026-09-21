//
//  VenusWelcomeMessage.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusWelcomeMessage: View {
    @State private var animateText = false
    
    var body: some View {
        VStack(spacing: 22) {
            // Interactive Welcoming Mascot
            VenusMoodOrb(
                mood: .happy,
                state: .celebrating,
                size: 92,
                showFace: true,
                isInteractive: true
            )
            .scaleEffect(animateText ? 1.0 : 0.85)
            .opacity(animateText ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.72), value: animateText)
            
            VStack(spacing: 10) {
                Text("Olá! Eu sou a Venus 👋")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
                
                Text("Estou aqui para ouvir você e refletir sobre o seu dia. Toque em mim ou envie uma mensagem para começar!")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 28)
            .opacity(animateText ? 1.0 : 0.0)
            .offset(y: animateText ? 0 : 12)
            .animation(.spring(response: 0.55, dampingFraction: 0.8).delay(0.15), value: animateText)
        }
        .onAppear {
            animateText = true
        }
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        VenusWelcomeMessage()
    }
}
