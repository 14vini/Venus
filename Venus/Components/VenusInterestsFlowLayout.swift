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
    
    private let defaultOrder: [String] = [
        "Tecnologia", "Natureza", "Artes",
        "Esportes", "Culinária", "Música", "Leitura",
        "Viagens", "Fotografia", "Filmes",
        "Meditação", "Educação", "Dança", "Jogos",
        "Moda", "Bem-estar", "Arquitetura",
        "História", "Ciência", "Filosofia", "Desenho",
        "Escrita", "Espiritualidade", "Humor"
    ]

    private var orderedItems: [String] {
        let requested = items.isEmpty ? defaultOrder : items

        let requestedSet = Set(requested)
        let orderedFromDefault = defaultOrder.filter { requestedSet.contains($0) }
        let extras = requested.filter { !defaultOrder.contains($0) }

        return orderedFromDefault + extras
    }
}

struct VenusInterestChipSimple: View {
    let title: String
    let isSelected: Bool
    var tint: Color = VenusTheme.primary
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                onTap()
            }
        } label: {
            Group {
                if isSelected {
                    chipContent
                        .background(selectedBackground)
                        .overlay(selectedHighlightOverlay)
                } else {
                    chipContent
                        .background(unselectedBackground)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var chipContent: some View {
        HStack(spacing: 8) {
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white.opacity(0.92))
            }

            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(isSelected ? .white : unselectedText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .contentShape(Capsule(style: .continuous))
    }
    
    private var selectedHighlightOverlay: some View {
        Capsule(style: .continuous)
            .fill(LinearGradient(
                colors: [
                    Color.white.opacity(colorScheme == .dark ? 0.16 : 0.22),
                    Color.clear,
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .blendMode(.overlay)
    }

    private var selectedBackground: some View {
        Capsule(style: .continuous)
            .fill(tint)
            .overlay(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(colorScheme == .dark ? 0.18 : 0))
                    .blendMode(.multiply)
            )
    }

    private var unselectedBackground: some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            .opacity(colorScheme == .dark ? 0.62 : 0.94)
            .overlay(
                Capsule(style: .continuous)
                    .fill(tint.opacity(colorScheme == .dark ? 0.10 : 0.05))
                    .blendMode(.overlay)
            )
            .overlay(
                Capsule(style: .continuous)
                    .fill(LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.12 : 0.22),
                            Color.clear,
                            Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .blendMode(.overlay)
            )
    }

    private var unselectedText: Color {
        colorScheme == .dark ? tint.opacity(0.92) : tint
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
