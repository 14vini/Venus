//
//  VenusInterestsFlowLayout.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusInterestsFlowLayout: View {
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
    
    // We ignore 'items' passed in and use our defined thematic order
    private var orderedItems: [String] {
        [
            "Tecnologia", "Natureza", "Artes",
            "Esportes", "Culinária", "Música", "Leitura",
            "Viagens", "Fotografia", "Filmes",
            "Meditação", "Educação", "Dança", "Jogos",
            "Moda", "Bem-estar", "Arquitetura",
            "História", "Ciência", "Filosofia", "Desenho",
            "Escrita", "Espiritualidade", "Humor"
        ]
    }
}

struct VenusInterestChipSimple: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                onTap()
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.tail)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(minHeight: 44)
                .background(
                    isSelected ? VenusTheme.darkGreen : Color.white.opacity(0.3)
                )
                .foregroundColor(
                    isSelected ? .white : VenusTheme.text
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? VenusTheme.darkGreen : Color.white.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    VenusInterestsFlowLayout(
        items: ["Tecnologia", "Natureza", "Artes", "Música"],
        selectedItems: ["Tecnologia": true, "Música": true, "Natureza": false, "Artes": false],
        onSelectionChange: { _ in }
    )
    .padding()
    .background(VenusTheme.backgroundGradient)
}
