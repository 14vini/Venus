//
//  VenusCelebrationView.swift
//  Venus
//
//  Camada de celebração reutilizável (F41) — confete, estrelas, brilho e
//  mola elástica no estilo Duolingo. Não importa assets: toda a arte vem
//  das formas/paleta já usadas pela Venus e do MascotParticleFactory.
//
//  Uso (o chamador apenas incrementa o trigger):
//
//      @State private var comemoracao = 0
//
//      ZStack {
//          VenusMoodOrb(state: .celebrating)
//          VenusCelebrationView(trigger: comemoracao, style: .milestone)
//      }
//
//      Button("Concluir") {
//          comemoracao += 1
//      }
//
//  A view não bloqueia toques e se desfaz sozinha em ~1,1s.
//

import SwiftUI

// MARK: - Estilo de comemoração

enum VenusCelebrationStyle: Sendable {
    case milestone       // marco de streak / conquista
    case correctAnswer   // resposta correta
    case starRain        // descoberta / recompensa
    case doubleHeart     // carinho
}

// MARK: - Celebração

struct VenusCelebrationView: View {
    /// Incrementar dispara uma nova comemoração. Começar em zero não dispara.
    let trigger: Int

    var style: VenusCelebrationStyle = .milestone
    var size: CGFloat = 220

    @State private var lastTrigger = 0
    @State private var burstID: UUID?
    @State private var particles: [MascotParticleItem] = []
    @State private var glow: Double = 0
    @State private var cleanupTask: Task<Void, Never>?

    private var tint: Color {
        switch style {
        case .milestone: return VenusTheme.accentPurple
        case .correctAnswer: return VenusTheme.primary
        case .starRain: return VenusTheme.journeySky
        case .doubleHeart: return VenusTheme.accentPink
        }
    }

    var body: some View {
        ZStack {
            if burstID != nil {
                MascotParticleEmitterView(particles: particles)
                    .id(burstID)

                // Brilho central com mola elástica — nunca um contorno duro.
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                tint.opacity(0.30),
                                VenusTheme.accentPink.opacity(0.12),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.42
                        )
                    )
                    .frame(width: size * 0.84, height: size * 0.84)
                    .scaleEffect(0.72 + CGFloat(glow) * 0.28)
                    .opacity(glow)

                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: size * (0.055 - 0.008 * Double(index)), weight: .bold))
                        .foregroundColor([VenusTheme.journeyLilac, VenusTheme.journeyRose, VenusTheme.journeySky][index])
                        .shadow(color: tint.opacity(0.6), radius: 6)
                        .offset(
                            x: size * (index == 0 ? -0.32 : (index == 1 ? 0.34 : 0.06)),
                            y: size * (index == 0 ? -0.22 : (index == 1 ? -0.14 : -0.38))
                        )
                        .scaleEffect(0.5 + CGFloat(glow) * 0.7)
                        .opacity(glow * 0.9)
                }
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            lastTrigger = trigger
        }
        .onChange(of: trigger) { _, newValue in
            guard newValue != lastTrigger else { return }
            lastTrigger = newValue
            fire()
        }
        .onDisappear {
            cleanupTask?.cancel()
            cleanupTask = nil
        }
    }

    @MainActor
    private func fire() {
        cleanupTask?.cancel()
        particles.removeAll()
        burstID = UUID()

        switch style {
        case .milestone:
            particles = MascotParticleFactory.makeMilestoneConfetti(count: 18)
            particles.append(contentsOf: MascotParticleFactory.makeStarRain(count: 6))
        case .correctAnswer:
            particles = MascotParticleFactory.makeCorrectAnswerSpark(count: 12, tint: tint)
        case .starRain:
            particles = MascotParticleFactory.makeStarRain(count: 14, tint: tint)
        case .doubleHeart:
            particles = MascotParticleFactory.makeDoubleHeart(count: 2, tint: tint)
        }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            glow = 1
        }

        cleanupTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.1)) {
                glow = 0
            }
            particles.removeAll()
            burstID = nil
        }
    }
}
