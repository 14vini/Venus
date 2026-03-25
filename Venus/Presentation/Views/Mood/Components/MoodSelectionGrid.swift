//
//  MoodSelectionGrid.swift
//  Venus
//

import SwiftUI

struct MoodSelectionGrid: View {
    let selectedMood: MoodType?
    let onSelect: (MoodType) -> Void

    private let moodColumns = [
        GridItem(.adaptive(minimum: 98), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: moodColumns, spacing: 10) {
            ForEach(MoodType.allCases, id: \.self) { mood in
                MoodOptionCard(
                    mood: mood,
                    isSelected: selectedMood == mood,
                    onTap: { onSelect(mood) }
                )
            }
        }
    }
}

struct MoodOptionCard: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(mood.rawValue)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                if isSelected {
                    Label("Selecionado", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.moodMintStrong)
                } else {
                    Text("Toque para continuar")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                Color(hex: mood.colorHex).opacity(0.24),
                                VenusTheme.cardSurfaceStrong
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [VenusTheme.cardSurface, VenusTheme.cardSurfaceStrong.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color(hex: mood.colorHex).opacity(0.45) : VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Humor \(mood.rawValue)")
        .accessibilityValue(isSelected ? "Selecionado" : "Não selecionado")
        .accessibilityHint("Toque para selecionar este estado emocional")
    }
}
