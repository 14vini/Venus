//
//  VenusSplashView.swift
//  Venus
//

import SwiftUI

struct VenusSplashView: View {
    let isReadyToReveal: Bool
    let onCompleted: () -> Void

    @State private var pulseScale: CGFloat = 0.95
    @State private var isRevealing = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. Fundo base (desaparece na revelação)
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
                .opacity(isRevealing ? 0 : 1)

            // 2. Aura central (pulsa e depois explode suavemente)
            Circle()
                .fill(VenusTheme.primary.opacity(colorScheme == .dark ? 0.4 : 0.2))
                .frame(width: 250, height: 250)
                .scaleEffect(isRevealing ? 8.0 : pulseScale) // Expande muito na saída
                .blur(radius: isRevealing ? 60 : 30)
                .opacity(isRevealing ? 0 : 1)

            // 3. Conteúdo Central (Logo e Textos)
            VStack(spacing: 24) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(VenusTheme.primary)
                    .scaleEffect(isRevealing ? 1.2 : 1.0) // Dá um leve "pulo" antes de sumir

                VStack(spacing: 8) {
                    Text("VENUS")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .tracking(4)

                    Text("transforme sentimento em direção")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
            }
            // Animação de saída do conteúdo
            .scaleEffect(isRevealing ? 1.1 : 1.0)
            .opacity(isRevealing ? 0 : 1)
            .offset(y: isRevealing ? -20 : 0) // Sobe levemente ao desaparecer
            
            // 4. Texto de status (Rodapé ou Topo)
            VStack {
                Spacer()
                Text("inicializando seu ritual...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary.opacity(0.6))
                    .tracking(1)
                    .padding(.bottom, 40)
                    .opacity(isRevealing ? 0 : 1)
            }
        }
        // Animação de respiração contínua
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
        // Gatilho de revelação
        .onChange(of: isReadyToReveal) { _, ready in
            guard ready, !isRevealing else { return }
            
            // Dispara a animação de transição
            withAnimation(.easeInOut(duration: 0.8)) {
                isRevealing = true
            }
            
            // Aguarda a animação terminar para remover a view da memória
            Task {
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    onCompleted()
                }
            }
        }
    }
}
