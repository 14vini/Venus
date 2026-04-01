//
//  PersonalizationStep.swift
//  Venus
//
//  Created by Kaua on 27/03/26.
//

import SwiftUI

private struct PersonalizationGoalOption: Identifiable {
    let title: String
    let detail: String
    let systemImage: String

    var id: String { title }
}

struct PersonalizationStep: View {
    @Binding var userProfile: UserProfile

    private let goals: [PersonalizationGoalOption] = [
        PersonalizationGoalOption(
            title: "Foco e produtividade",
            detail: "Priorizar clareza, hábitos e execução.",
            systemImage: "target"
        ),
        PersonalizationGoalOption(
            title: "Ansiedade e calma",
            detail: "Reduzir ruído mental e regular o corpo.",
            systemImage: "wind"
        ),
        PersonalizationGoalOption(
            title: "Sono e energia",
            detail: "Rotina leve pra dormir melhor e ter mais gás.",
            systemImage: "bed.double.fill"
        ),
        PersonalizationGoalOption(
            title: "Autoconfiança",
            detail: "Fortalecer autoestima com passos pequenos.",
            systemImage: "heart.fill"
        ),
        PersonalizationGoalOption(
            title: "Equilíbrio de vida",
            detail: "Menos overload, mais constância.",
            systemImage: "scale.3d"
        ),
        PersonalizationGoalOption(
            title: "Relacionamentos",
            detail: "Comunicação e limites com mais paz.",
            systemImage: "person.2.fill"
        )
    ]

    private let tones: [String] = [
        "Gentil",
        "Direto",
        "Prático",
        "Motivacional"
    ]

    private let timeBudgets: [Int] = [3, 5, 10, 20]

    private var selectedAccessory: String? {
        var parts: [String] = []
        if !userProfile.primaryGoal.isEmpty { parts.append("foco") }
        if !userProfile.coachingTone.isEmpty { parts.append("tom") }
        if userProfile.dailyTimeBudgetMinutes > 0 { parts.append("tempo") }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "calibração",
                title: "Como eu te ajudo melhor?",
                subtitle: "Isso define o tom e o tipo de sugestão que você vai ver.",
                systemImage: "wand.and.stars",
                tint: VenusTheme.accentBlue,
                accessory: selectedAccessory
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("Seu foco agora")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(VenusTheme.text)

                VStack(spacing: 10) {
                    ForEach(goals) { option in
                        OnboardingSelectionRow(
                            title: option.title,
                            detail: option.detail,
                            systemImage: option.systemImage,
                            isSelected: userProfile.primaryGoal == option.title,
                            tint: VenusTheme.accentBlue
                        ) {
                            userProfile.primaryGoal = option.title
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Tom da Venus")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(VenusTheme.text)

                VenusWrappedLayout(spacing: 10, lineSpacing: 12) {
                    ForEach(tones, id: \.self) { tone in
                        VenusInterestChipSimple(
                            title: tone,
                            isSelected: userProfile.coachingTone == tone,
                            tint: VenusTheme.accentBlue
                        ) {
                            userProfile.coachingTone = tone
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Tempo por dia")
                    .font(.system(.headline, design: .rounded).weight(.black))
                    .foregroundStyle(VenusTheme.text)

                VenusWrappedLayout(spacing: 10, lineSpacing: 12) {
                    ForEach(timeBudgets, id: \.self) { minutes in
                        VenusInterestChipSimple(
                            title: "\(minutes) min",
                            isSelected: userProfile.dailyTimeBudgetMinutes == minutes,
                            tint: VenusTheme.accentBlue
                        ) {
                            userProfile.dailyTimeBudgetMinutes = minutes
                        }
                    }
                }

                Text("Você pode mudar isso depois nas configurações.")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(VenusTheme.textSecondary)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }
}

#Preview {
    PersonalizationStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
