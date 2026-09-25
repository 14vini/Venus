//
//  InitialMoodStep.swift
//  Venus
//
//  Created by Kaua on 20/09/26.
//

import SwiftUI

struct InitialMoodOption: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
    let primaryGoal: String
    let primaryEmotion: String
    let moodType: MoodType
}

struct InitialMoodStep: View {
    @Binding var userProfile: UserProfile
    
    private let options: [InitialMoodOption] = [
        InitialMoodOption(
            id: "full_energy",
            title: "100% · Bateria Alta",
            detail: "Pronto para foco profundo, alta demanda e execução",
            systemImage: "bolt.fill",
            primaryGoal: "Foco e produtividade",
            primaryEmotion: "Energia",
            moodType: .energetic
        ),
        InitialMoodOption(
            id: "stable_energy",
            title: "75% · Estável & Funcional",
            detail: "Bom ritmo mental, buscando manter a constância e equilíbrio",
            systemImage: "battery.75percent",
            primaryGoal: "Equilíbrio de vida",
            primaryEmotion: "Equilíbrio",
            moodType: .calm
        ),
        InitialMoodOption(
            id: "low_energy",
            title: "40% · Bateria Baixa",
            detail: "Cansaço acumulado e mente acelerada, precisando de suporte",
            systemImage: "battery.25percent",
            primaryGoal: "Ansiedade e calma",
            primaryEmotion: "Estresse",
            moodType: .stressed
        ),
        InitialMoodOption(
            id: "exhausted_energy",
            title: "15% · Esgotamento Total",
            detail: "Sensação de overload, bateria no limite e precisando recarregar",
            systemImage: "battery.0percent",
            primaryGoal: "Sono e energia",
            primaryEmotion: "Overwhelm",
            moodType: .tired
        )
    ]
    
    private var selectedAccessory: String? {
        if !userProfile.primaryGoal.isEmpty {
            return "selecionado"
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "bateria inicial",
                title: "Como está seu nível de energia hoje?",
                subtitle: "Seu ponto de partida para a Venus calibrar sua prontidão.",
                systemImage: "bolt.batteryblock.fill",
                tint: VenusTheme.accentBlue,
                accessory: selectedAccessory
            )
            
            VStack(spacing: 12) {
                ForEach(options) { option in
                    OnboardingSelectionRow(
                        title: option.title,
                        detail: option.detail,
                        systemImage: option.systemImage,
                        isSelected: userProfile.primaryGoal == option.primaryGoal,
                        tint: VenusTheme.accentBlue
                    ) {
                        userProfile.primaryGoal = option.primaryGoal
                        userProfile.emotionalAreas = [option.primaryEmotion]
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

#Preview {
    InitialMoodStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
