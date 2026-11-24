//
//  VenusDailyRitualsView.swift
//  Venus
//
//  F28 / A9 — meta honesta de 3 rituais por dia (check-in, bloco concluído, conversa).
//  Topo limpo: só o arco com pontos, os ícones e a micro-celebração. Sem número grande
//  ou rótulo duplicado — a contagem continua no accessibility label.
//

import SwiftUI
import UIKit

/// Cabeçalho de jornada da Home: três rituais representados pelo arco com pontos
/// e pelos ícones, com um burst sutil quando a meta é concluída.
struct VenusDailyRitualsView: View {
    let checkInDone: Bool
    let planBlockDone: Bool
    let chatDone: Bool

    @Environment(\.colorScheme) private var colorScheme
    @State private var showCelebration = false

    private let total = 3

    private var completed: Int {
        [checkInDone, planBlockDone, chatDone].filter { $0 }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                VenusHomeProgressArc(completed: completed, total: total)

                if showCelebration {
                    VenusRitualBurst()
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: 280)
            .frame(height: 32)

            HStack(spacing: 24) {
                ritualStep(systemImage: "sparkles", label: "Check-in", done: checkInDone)
                ritualStep(systemImage: "square.grid.2x2", label: "Meu Dia", done: planBlockDone)
                ritualStep(systemImage: "bubble.left.and.bubble.right", label: "Conversa", done: chatDone)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Jornada de hoje: \(completed) de \(total) rituais")
        .accessibilityHint(surprisePhrase)
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: completed)
        .onChange(of: completed) { oldValue, newValue in
            guard oldValue < total, newValue >= total else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showCelebration = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showCelebration = false
                }
            }
        }
    }

    /// Só o ícone: o nome do ritual continua disponível para VoiceOver e o arco mostra o progresso.
    private func ritualStep(systemImage: String, label: String, done: Bool) -> some View {
        ZStack {
            Circle()
                .fill(
                    done
                        ? VenusHomeJourneyPalette.lilac.opacity(colorScheme == .dark ? 0.42 : 0.28)
                        : Color.white.opacity(colorScheme == .dark ? 0.08 : 0.46)
                )
                .frame(width: 36, height: 36)
                .glassEffect(.regular, in: Circle())

            Image(systemName: done ? "checkmark" : systemImage)
                .font(.system(size: 13, weight: done ? .bold : .semibold))
                .foregroundStyle(
                    done
                        ? VenusHomeJourneyPalette.lilac
                        : VenusTheme.textSecondary.opacity(colorScheme == .dark ? 0.7 : 0.6)
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: done)
        }
        .contentTransition(.opacity)
        .accessibilityLabel("\(label): \(done ? "concluído" : "pendente")")
    }

    /// Rotação determinística: mesma frase para todos os usuários no mesmo dia, sem IA e sem sortear.
    private var surprisePhrase: String {
        let phrases = [
            "Toda pausa também é progresso.",
            "O primeiro passo já acende o caminho.",
            "Pequenos rituais sustentam grandes mudanças.",
            "Hoje, o cuidado começa por você.",
            "Cada escolha sua tem um lugar nessa jornada.",
            "Um passo de cada vez já é o bastante.",
            "Volte ao que te faz bem, sem pressa."
        ]
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return phrases[max(0, day - 1) % phrases.count]
    }
}

// MARK: - Micro-celebração (burst curto e discreto)

private struct VenusRitualBurst: View {
    @State private var exploded = false

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                let angle = Double(index) * 30.0
                let distance: CGFloat = index.isMultiple(of: 2) ? 34 : 24
                let size: CGFloat = index.isMultiple(of: 3) ? 4 : 3
                let colors: [Color] = [
                    VenusHomeJourneyPalette.lilac,
                    VenusHomeJourneyPalette.rose,
                    VenusHomeJourneyPalette.sky
                ]

                Circle()
                    .fill(colors[index % colors.count])
                    .frame(width: size, height: size)
                    .offset(
                        x: exploded ? CGFloat(cos(angle * .pi / 180)) * distance : 0,
                        y: exploded ? CGFloat(sin(angle * .pi / 180)) * distance : 0
                    )
                    .opacity(exploded ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 0.9).delay(Double(index) * 0.012),
                        value: exploded
                    )
            }
        }
        .onAppear { exploded = true }
    }
}

#Preview {
    VStack(spacing: 40) {
        VenusDailyRitualsView(checkInDone: true, planBlockDone: false, chatDone: false)
        VenusDailyRitualsView(checkInDone: true, planBlockDone: true, chatDone: true)
    }
    .padding()
}
