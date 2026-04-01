//
//  VenusImprovementAreasFlowLayout.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusImprovementAreasFlowLayout: View {
    let items: [String]
    let selectedItems: [String: Bool]
    var tint: Color = VenusTheme.primary
    let onSelectionChange: (String) -> Void
    
    var body: some View {
        VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
            ForEach(orderedItems, id: \.self) { item in
                VenusInterestChipSimple(
                    title: item,
                    isSelected: selectedItems[item] ?? false,
                    tint: tint,
                    onTap: { onSelectionChange(item) }
                )
            }
        }
    }
    
    private var orderedItems: [String] {
        [
            "Ansiedade", "Foco e Produtividade", "Sono",
            "Confiança", "Relacionamentos", "Criatividade", "Energia",
            "Equilíbrio de Vida", "Autoestima", "Paciência",
            "Espiritualidade", "Saúde Física", "Comunicação", "Motivação",
            "Resiliência", "Perdão", "Memória",
            "Flexibilidade", "Inteligência Emocional", "Gratidão", "Aceitação",
            "Propósito de Vida"
        ]
    }
}

#Preview {
    VenusImprovementAreasFlowLayout(
        items: ["Ansiedade", "Confiança", "Energia", "Gratidão"],
        selectedItems: ["Ansiedade": true, "Confiança": true, "Energia": false, "Gratidão": false],
        onSelectionChange: { _ in }
    )
    .padding()
    .background(VenusTheme.backgroundGradient)
}
