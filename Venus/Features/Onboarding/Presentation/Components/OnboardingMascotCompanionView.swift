//
//  OnboardingMascotCompanionView.swift
//  Venus
//
//  Created by Kaua on 04/10/26.
//

import SwiftUI

struct OnboardingMascotCompanionView: View {
    let currentStep: Int
    @Binding var userProfile: UserProfile
    var isTextFocused: Bool = false

    // MARK: - Computed Mascot State & Mood

    private var effectiveMood: MoodType {
        switch currentStep {
        case 1:
            return .happy
        case 2:
            return .calm
        case 3:
            return .calm
        case 4:
            return .calm
        case 5:
            return .happy
        default:
            return .happy
        }
    }

    private var effectiveState: VenusMascotState {
        switch currentStep {
        case 1:
            return userProfile.name.isEmpty ? .welcoming : .celebrating
        case 2:
            return userProfile.contextNote.isEmpty ? .curious : .empathetic
        // A Venus escuta nos passos 3/4 — sem texto de processo na UI.
        case 3, 4:
            return .listening
        case 5:
            return .celebrating
        default:
            return .welcoming
        }
    }

    private var speechText: String {
        switch currentStep {
        case 1:
            let name = userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if !name.isEmpty {
                return "Que alegria te conhecer, \(name). É um prazer ter você aqui."
            }
            return "Olá, como você prefere que eu te chame?"

        case 2:
            if !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Entender seu ritmo nos dá a base perfeita para calibrar seus dias."
            }
            let name = userProfile.name.isEmpty ? "" : ", \(userProfile.name)"
            return "Como costuma ser seu ritmo e nível de energia\(name)?"

        case 3:
            return "Vamos conhecer um pouco mais da sua mente, uma pergunta de cada vez."

        case 4:
            return "Cada resposta sua ajuda a desenhar o seu ritmo."

        case 5:
            return "Olhe só o quanto você já avançou."

        default:
            return "Estou pronta para começar."
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Venus em código — ANTIGA, sem USDZ.
            VenusMoodOrb(
                mood: effectiveMood,
                state: effectiveState,
                size: 80,
                showFace: true,
                showHands: true,
                showShadow: false,
                isInteractive: true
            )
            .frame(width: 80, height: 80)

            // Balão de fala em vidro líquido real.
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(OnboardingVisualPalette.lilac)
                    Text("Venus")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(VenusTheme.text)
                }

                Text(speechText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(VenusTheme.text)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: speechText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: effectiveState)
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: effectiveMood)
    }
}
