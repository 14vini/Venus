//
//  ImprovementAreasStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

@Observable
class VenusImprovementAreasStepModel {
    var selectedAreas: [String: Bool] = [
        "Ansiedade": false,
        "Foco e Produtividade": false,
        "Sono": false,
        "Confiança": false,
        "Relacionamentos": false,
        "Criatividade": false,
        "Energia": false,
        "Equilíbrio de Vida": false,
        "Autoestima": false,
        "Paciência": false,
        "Espiritualidade": false,
        "Saúde Física": false,
        "Comunicação": false,
        "Motivação": false,
        "Resiliência": false,
        "Perdão": false,
        "Memória": false,
        "Flexibilidade": false,
        "Inteligência Emocional": false,
        "Gratidão": false,
        "Aceitação": false,
        "Propósito de Vida": false
    ]
}

struct ImprovementAreasStep: View {
    @Binding var userProfile: UserProfile
    @State private var model = VenusImprovementAreasStepModel()
    
    var selectedCount: Int {
        model.selectedAreas.filter { $0.value }.count
    }

    private var selectedAccessory: String? {
        guard selectedCount > 0 else { return nil }
        return "\(selectedCount) selecionado\(selectedCount == 1 ? "" : "s")"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "foco",
                title: "O que você quer melhorar?",
                subtitle: "Eu uso isso para priorizar leituras e sugestões ao longo da semana.",
                systemImage: "target",
                tint: VenusTheme.accentPink,
                accessory: selectedAccessory
            )

            VenusImprovementAreasFlowLayout(
                items: Array(model.selectedAreas.keys),
                selectedItems: model.selectedAreas,
                tint: VenusTheme.accentPink,
                onSelectionChange: { area in
                    model.selectedAreas[area]?.toggle()
                }
            )
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onChange(of: model.selectedAreas) { _, newValue in
            userProfile.improvementAreas = newValue.filter { $0.value }.map { $0.key }
        }
        .onAppear {
            for area in userProfile.improvementAreas {
                model.selectedAreas[area] = true
            }
        }
    }
}

#Preview {
    ImprovementAreasStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
