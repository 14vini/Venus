//
//  VenusDesiredHobbiesFlowLayout.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusDesiredHobbiesFlowLayout: View {
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
            "Meditação", "Ioga Avançada", "Fotografia Profissional",
            "Escrita Criativa", "Música", "Culinária Gourmet", "Desenho",
            "Natação", "Pilates", "Línguas",
            "Artes Marciais", "Poesia", "Instrumento Musical", "Cerâmica",
            "Surf", "Dança de Salsa", "Stand-up",
            "Produção Musical", "Parkour", "Costura", "Terapia Holística",
            "Cinematografia"
        ]
    }
}

#Preview {
    VenusDesiredHobbiesFlowLayout(
        items: ["Meditação", "Música", "Desenho", "Surf"],
        selectedItems: ["Meditação": true, "Música": true, "Desenho": false, "Surf": false],
        onSelectionChange: { _ in }
    )
    .padding()
    .background(VenusTheme.backgroundGradient)
}
