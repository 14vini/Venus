//
//  RootStruggleStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

struct RootStruggleOption: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

struct RootStruggleStep: View {
    @Binding var userProfile: UserProfile
    @State private var selectedStruggles: Set<String> = []
    
    private let struggles: [RootStruggleOption] = [
        RootStruggleOption(
            id: "self_criticism",
            title: "Autocobrança excessiva",
            detail: "Sensação constante de que nunca é o suficiente ou medo de errar",
            systemImage: "sparkle.magnifyingglass"
        ),
        RootStruggleOption(
            id: "future_anxiety",
            title: "Ansiedade com o futuro",
            detail: "Preocupação com rumos da vida, decisões e incertezas",
            systemImage: "chart.line.uptrend.xyaxis"
        ),
        RootStruggleOption(
            id: "routine_overload",
            title: "Sobrecarga de rotina",
            detail: "Muitas demandas e pouquíssimo tempo para cuidar de si",
            systemImage: "clock.badge.exclamationmark"
        ),
        RootStruggleOption(
            id: "relationships",
            title: "Relações e limites",
            detail: "Dificuldade em dizer não, absorver problemas alheios ou conflitos",
            systemImage: "person.2.fill"
        ),
        RootStruggleOption(
            id: "isolation",
            title: "Sensação de solidão",
            detail: "Sentir que ninguém compreende de verdade o que você carrega",
            systemImage: "person.crop.circle.badge.questionmark"
        ),
        RootStruggleOption(
            id: "mood_swings",
            title: "Instabilidade de energia",
            detail: "Picos de motivação seguidos de quedas bruscas de ânimo",
            systemImage: "waveform.path.ecg"
        )
    ]
    
    private var selectedAccessory: String? {
        let count = selectedStruggles.count
        guard count > 0 else { return nil }
        return "\(count) selecionado\(count == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "investigação",
                title: "O que tem mais pesado no seu peito?",
                subtitle: "Identificar a raiz do cansaço é o primeiro passo para o alívio.",
                systemImage: "heart.text.square.fill",
                tint: VenusTheme.accentPurple,
                accessory: selectedAccessory
            )
            
            VStack(spacing: 12) {
                ForEach(struggles) { struggle in
                    OnboardingSelectionRow(
                        title: struggle.title,
                        detail: struggle.detail,
                        systemImage: struggle.systemImage,
                        isSelected: selectedStruggles.contains(struggle.title),
                        tint: VenusTheme.accentPurple
                    ) {
                        if selectedStruggles.contains(struggle.title) {
                            selectedStruggles.remove(struggle.title)
                        } else {
                            selectedStruggles.insert(struggle.title)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .onChange(of: selectedStruggles) { _, newValue in
            userProfile.improvementAreas = Array(newValue)
        }
        .onAppear {
            if !userProfile.improvementAreas.isEmpty {
                selectedStruggles = Set(userProfile.improvementAreas)
            }
        }
    }
}

#Preview {
    RootStruggleStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
