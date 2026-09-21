//
//  EmotionalAreaStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct EmotionalAreaStep: View {
    @Binding var userProfile: UserProfile
    @State private var selectedAreas: Set<String> = []
    
    private let emotionalAreas = [
        "Estresse", "Tristeza", "Solidão", "Culpa", "Raiva",
        "Insegurança", "Falta de Propósito", "Overwhelm"
    ]

    private var selectedAccessory: String? {
        let count = selectedAreas.count
        guard count > 0 else { return nil }
        return "\(count) selecionado\(count == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "emoções",
                title: "O que mais mexe com você?",
                subtitle: "Escolha algumas áreas emocionais para eu cuidar melhor do seu dia.",
                systemImage: "heart.text.square.fill",
                tint: VenusTheme.accentOrange,
                accessory: selectedAccessory
            )

            VStack(spacing: 12) {
                ForEach(emotionalAreas, id: \.self) { area in
                    OnboardingSelectionRow(
                        title: area,
                        detail: descriptionForArea(area),
                        systemImage: iconForArea(area),
                        isSelected: selectedAreas.contains(area),
                        tint: VenusTheme.accentOrange
                    ) {
                        if selectedAreas.contains(area) {
                            selectedAreas.remove(area)
                        } else {
                            selectedAreas.insert(area)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onChange(of: selectedAreas) { _, newValue in
            userProfile.emotionalAreas = Array(newValue)
        }
        .onAppear {
            selectedAreas = Set(userProfile.emotionalAreas)
        }
    }
    
    private func iconForArea(_ area: String) -> String {
        let icons: [String: String] = [
            "Estresse": "exclamationmark.circle.fill",
            "Tristeza": "cloud.rain.fill",
            "Solidão": "person.slash.fill",
            "Culpa": "xmark.circle.fill",
            "Raiva": "flame.fill",
            "Insegurança": "questionmark.circle.fill",
            "Falta de Propósito": "magnifyingglass",
            "Overwhelm": "tornado"
        ]
        return icons[area] ?? "heart.fill"
    }
    
    private func descriptionForArea(_ area: String) -> String {
        let descriptions: [String: String] = [
            "Estresse": "Pressão e tensão do dia a dia",
            "Tristeza": "Sentimentos melancólicos e baixos",
            "Solidão": "Falta de conexão com outros",
            "Culpa": "Arrependimento e autocrítica",
            "Raiva": "Irritação e frustração",
            "Insegurança": "Dúvida sobre si mesmo",
            "Falta de Propósito": "Sensação de falta de direção",
            "Overwhelm": "Sensação de estar sobrecarregado"
        ]
        return descriptions[area] ?? ""
    }
}

#Preview {
    EmotionalAreaStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
