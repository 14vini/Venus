//
//  VenusHobbiesFlowLayout.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusHobbiesFlowLayout: View {
    let items: [String]
    let selectedItems: [String: Bool]
    let onSelectionChange: (String) -> Void
    
    var body: some View {
        VenusWrappedLayout(spacing: 8, lineSpacing: 12) {
            ForEach(orderedItems, id: \.self) { item in
                VenusInterestChipSimple(
                    title: item,
                    isSelected: selectedItems[item] ?? false,
                    onTap: { onSelectionChange(item) }
                )
            }
        }
    }
    
    private var orderedItems: [String] {
        [
            "Leitura", "Exercícios", "Culinária",
            "Jardinagem", "Música", "Desenho", "Fotografia",
            "Caminhada", "Ioga", "Meditação",
            "Escrita", "Dança", "Natação", "Ciclismo",
            "Pintura", "Artesanato", "Jogos", "Cinema"
        ]
    }
}

#Preview {
    VenusHobbiesFlowLayout(
        items: ["Leitura", "Música", "Desenho", "Ioga"],
        selectedItems: ["Leitura": true, "Música": true, "Desenho": false, "Ioga": false],
        onSelectionChange: { _ in }
    )
    .padding()
    .background(VenusTheme.backgroundGradient)
}