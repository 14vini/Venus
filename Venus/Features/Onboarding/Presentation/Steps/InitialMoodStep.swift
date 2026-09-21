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
            id: "anxious",
            title: "Mente acelerada",
            detail: "Pensamentos sem parar e dificuldade para desacelerar",
            systemImage: "wind",
            primaryGoal: "Ansiedade e calma",
            primaryEmotion: "Estresse",
            moodType: .stressed
        ),
        InitialMoodOption(
            id: "exhausted",
            title: "Esgotamento & cansaço",
            detail: "Sensação de sobrecarga e bateria emocional baixa",
            systemImage: "battery.25",
            primaryGoal: "Sono e energia",
            primaryEmotion: "Overwhelm",
            moodType: .tired
        ),
        InitialMoodOption(
            id: "vent",
            title: "Precisando desabafar",
            detail: "Sentimentos guardados que preciso colocar pra fora sem julgamentos",
            systemImage: "bubble.left.and.bubble.right.fill",
            primaryGoal: "Equilíbrio de vida",
            primaryEmotion: "Solidão",
            moodType: .sad
        ),
        InitialMoodOption(
            id: "focus",
            title: "Buscando foco & clareza",
            detail: "Quero organizar a mente, ter direção e manter a constância",
            systemImage: "target",
            primaryGoal: "Foco e produtividade",
            primaryEmotion: "Falta de Propósito",
            moodType: .energetic
        ),
        InitialMoodOption(
            id: "sensitive",
            title: "Sensível ou pra baixo",
            detail: "Um momento mais delicado, precisando de conforto e apoio",
            systemImage: "heart.fill",
            primaryGoal: "Autoconfiança",
            primaryEmotion: "Tristeza",
            moodType: .calm
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
                eyebrow: "ponto de partida",
                title: "Como você realmente está hoje?",
                subtitle: "Sem filtros. Este é o seu espaço seguro e 100% confidencial.",
                systemImage: "sparkles",
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
                        if !userProfile.emotionalAreas.contains(option.primaryEmotion) {
                            userProfile.emotionalAreas = [option.primaryEmotion]
                        }
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
