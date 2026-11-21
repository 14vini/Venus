//
//  VenusHomeEtherealBackgroundView.swift
//  Venus
//
//  Fundo etéreo e minimalista da Home:
//  Carrega a arte visual de alta resolução (silhueta anatômica/porcelana suave
//  com iluminação de spa de luxo no topo e névoa azul-gelo na base)
//  com suporte a pulso circadiano e fallback procedural.
//

import SwiftUI

struct VenusHomeEtherealBackgroundView: View {
    let activeAuraColor: Color

    @State private var breathingPulse: CGFloat = 1.0
    @State private var mistShift: CGFloat = 0

    init(activeAuraColor: Color = Color(hex: "FDE8D7")) {
        self.activeAuraColor = activeAuraColor
    }

    public var body: some View {
        ZStack {
            // 1. Camada de Imagem de Fundo (Asset de Alta Resolução)
            Image("VenusEtherealBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                // Fallback procedural gracioso caso a imagem não carregue
                .background(proceduralFallback)

            // 2. Halo de Luz Orgânica na Região da Garganta / Vago
            RadialGradient(
                colors: [
                    activeAuraColor.opacity(0.38 * breathingPulse),
                    activeAuraColor.opacity(0.12 * breathingPulse),
                    Color.clear
                ],
                center: UnitPoint(x: 0.52, y: 0.36),
                startRadius: 20,
                endRadius: 220
            )
            .ignoresSafeArea()
            .blur(radius: 20)

            // 3. Névoa Suave na Região Inferior para Legibilidade da Tipografia
            LinearGradient(
                colors: [
                    Color.clear,
                    Color(hex: "5A7B90").opacity(0.15),
                    Color(hex: "4B697D").opacity(0.42),
                    Color(hex: "344F60").opacity(0.68)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // 4. Efeito de Respiração Parassimpática (12 respirações por minuto)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.08 * (breathingPulse - 0.95)),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.5),
                startRadius: 50,
                endRadius: 380
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.2)
                .repeatForever(autoreverses: true)
            ) {
                breathingPulse = 1.10
                mistShift = 10
            }
        }
    }

    /// Gradiente procedural de fallback caso o asset não esteja disponível
    private var proceduralFallback: some View {
        LinearGradient(
            colors: [
                Color(hex: "E8D2C4"), // Tom pele/porcelana suave no topo
                Color(hex: "D9C5B6"),
                Color(hex: "B7CBD7"), // Transição para névoa
                Color(hex: "8BA7B8"), // Azul ardósia suave
                Color(hex: "617F92")  // Base ciano profunda
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    VenusHomeEtherealBackgroundView()
}
