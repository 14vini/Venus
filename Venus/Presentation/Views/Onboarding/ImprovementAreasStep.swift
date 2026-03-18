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
    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Áreas para Melhorar")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    if selectedCount > 0 {
                        Text("Vamos trabalhar \(selectedCount) área\(selectedCount != 1 ? "s" : ""). Você consegue!")
                            .font(.headline)
                            .foregroundColor(VenusTheme.darkGreen)
                            .fontWeight(.semibold)
                    } else {
                        Text("Selecione áreas que quer trabalhar")
                            .font(.headline)
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)

                VenusImprovementAreasFlowLayout(
                    items: Array(model.selectedAreas.keys),
                    selectedItems: model.selectedAreas,
                    onSelectionChange: { area in
                        model.selectedAreas[area]?.toggle()
                    }
                )
                .padding(.horizontal, 24)
            
        }
        .padding(.top, 24)
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
