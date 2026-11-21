//
//  VenusPastelMascotView.swift
//  Venus
//
//  Adaptador do Mascote oficial da Venus (VenusMoodOrb) para o fluxo de check-in,
//  mantendo a identidade visual do app com expressões táteis e aura acolhedora.
//

import SwiftUI

enum VenusCheckInMoodLevel: Int, CaseIterable, Identifiable {
    case veryLow = 0
    case low = 1
    case neutral = 2
    case good = 3
    case optimal = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .veryLow: return "Difícil sair da cama"
        case .low: return "Sem energia / Cansado"
        case .neutral: return "Nem bom, nem ruim"
        case .good: return "Disposto e focado"
        case .optimal: return "Otimista e animado"
        }
    }

    var englishReferenceTitle: String {
        switch self {
        case .veryLow: return "Hard to push myself out of bed"
        case .low: return "Low energy, feeling sluggish"
        case .neutral: return "Not bad, not good"
        case .good: return "Focused and steady"
        case .optimal: return "Optimistic and delighted"
        }
    }

    var shortLabel: String {
        switch self {
        case .veryLow: return "Crítico"
        case .low: return "Baixo"
        case .neutral: return "Médio"
        case .good: return "Bom"
        case .optimal: return "Alto"
        }
    }

    var emoji: String {
        switch self {
        case .veryLow: return "🥱"
        case .low: return "😴"
        case .neutral: return "🙂"
        case .good: return "😊"
        case .optimal: return "⚡️"
        }
    }

    var mappedMoodType: MoodType {
        switch self {
        case .veryLow: return .sad
        case .low: return .tired
        case .neutral: return .calm
        case .good: return .happy
        case .optimal: return .energetic
        }
    }

    var mappedEnergyLevel: MoodEnergyLevel {
        switch self {
        case .veryLow, .low: return .low
        case .neutral: return .medium
        case .good, .optimal: return .high
        }
    }

    var mascotExpression: VenusMascotExpression {
        switch self {
        case .veryLow: return .sad
        case .low: return .tired
        case .neutral: return .calm
        case .good: return .happy
        case .optimal: return .excited
        }
    }

    var mascotState: VenusMascotState {
        switch self {
        case .veryLow: return .idle
        case .low: return .idle
        case .neutral: return .idle
        case .good: return .welcoming
        case .optimal: return .celebrating
        }
    }
}

struct VenusPastelMascotView: View {
    let level: VenusCheckInMoodLevel
    var size: CGFloat = 200
    var isAnimated: Bool = true
    var customState: VenusMascotState? = nil
    var customExpression: VenusMascotExpression? = nil
    var gazeOffset: CGSize = .zero

    @Environment(\.colorScheme) private var colorScheme
    @State private var floatingOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Aura luminosa suave em volta do mascote oficial
            RadialGradient(
                colors: [
                    auraGlowColor.opacity(colorScheme == .dark ? 0.35 : 0.55),
                    auraGlowColor.opacity(colorScheme == .dark ? 0.12 : 0.22),
                    Color.clear
                ],
                center: .center,
                startRadius: size * 0.10,
                endRadius: size * 0.75
            )
            .frame(width: size * 1.6, height: size * 1.6)
            .blur(radius: 20)

            // Mascote Oficial da Venus do Projeto (VenusMoodOrb)
            VenusMoodOrb(
                mood: level.mappedMoodType,
                state: customState ?? level.mascotState,
                expression: customExpression ?? level.mascotExpression,
                size: size,
                showFace: true,
                showHands: true,
                showShadow: false,
                isInteractive: false,
                gazeOffset: gazeOffset
            )
            .frame(width: size, height: size)
            .offset(y: floatingOffset)
        }
        .frame(width: size * 1.5, height: size * 1.25)
        .onAppear {
            if isAnimated {
                withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                    floatingOffset = -6
                }
            }
        }
    }

    private var auraGlowColor: Color {
        switch level {
        case .veryLow:
            return Color(hex: "95AEE8")
        case .low:
            return Color(hex: "A3A7E8")
        case .neutral:
            return Color(hex: "8BBBF8")
        case .good:
            return Color(hex: "7AC2F5")
        case .optimal:
            return Color(hex: "FFBED0")
        }
    }
}
