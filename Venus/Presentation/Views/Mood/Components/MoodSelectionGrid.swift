//
//  MoodSelectionGrid.swift
//  Venus
//

import SwiftUI

struct MoodSelectionGrid: View {
    let selectedMood: MoodType?
    let onSelect: (MoodType) -> Void

    private let moodColumns = [
        GridItem(.adaptive(minimum: 104), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: moodColumns, spacing: 8) {
            ForEach(MoodType.allCases, id: \.self) { mood in
                MoodOptionCard(
                    mood: mood,
                    isSelected: selectedMood == mood,
                    onTap: { onSelect(mood) }
                )
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: selectedMood)
    }
}

struct MoodOptionCard: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 36))

                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: "FF3D00"))
                } else {
                    Text("Selecionar")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Color(hex: mood.colorHex).opacity(0.18) : VenusTheme.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Humor \(mood.rawValue)")
        .accessibilityValue(isSelected ? "Selecionado" : "Não selecionado")
        .accessibilityHint("Toque para selecionar este estado emocional")
    }
}
