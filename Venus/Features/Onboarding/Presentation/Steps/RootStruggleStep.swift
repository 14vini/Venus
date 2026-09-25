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
            id: "mental_workload",
            title: "Trabalho & Decisões pesadas",
            detail: "Alta demanda cognitiva, reuniões e muitas decisões consecutivas",
            systemImage: "brain.head.profile"
        ),
        RootStruggleOption(
            id: "poor_sleep",
            title: "Sono & Descanso não restaurador",
            detail: "Acordar cansado(a), sono leve ou dificuldade para desligar à noite",
            systemImage: "moon.zzz.fill"
        ),
        RootStruggleOption(
            id: "self_pressure",
            title: "Autocobrança & Ansiedade mental",
            detail: "Sensação constante de urgência e pensamentos acelerados",
            systemImage: "tornado"
        ),
        RootStruggleOption(
            id: "busy_routine",
            title: "Rotina corrida & Falta de tempo",
            detail: "Muitas interrupções diárias e pouco espaço para respirar",
            systemImage: "clock.badge.exclamationmark"
        ),
        RootStruggleOption(
            id: "emotional_drain",
            title: "Relações & Desgaste emocional",
            detail: "Absorver problemas alheios, conflitos ou dificuldade em colocar limites",
            systemImage: "person.2.fill"
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
                eyebrow: "drenos de carga",
                title: "O que mais drena sua energia ultimamente?",
                subtitle: "Identificar seu maior dreno nos ajuda a blindar o seu ritmo.",
                systemImage: "flame.fill",
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
