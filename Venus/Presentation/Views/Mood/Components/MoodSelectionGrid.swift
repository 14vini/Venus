//
//  MoodSelectionGrid.swift
//  Venus
//

import SwiftUI

struct MoodShortcutOption: Identifiable, Hashable {
    let id: String
    let title: String
    let emoji: String
    let mood: MoodType

    init(id: String, title: String, emoji: String, mood: MoodType) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.mood = mood
    }

    var tint: Color {
        Color(hex: mood.colorHex)
    }

    static let indecisive: [MoodShortcutOption] = [
        MoodShortcutOption(id: "neutral", title: "Neutro", emoji: "🙂", mood: .calm),
        MoodShortcutOption(id: "anxious", title: "Ansioso", emoji: "😬", mood: .stressed),
        MoodShortcutOption(id: "overwhelmed", title: "Sobrecarregado", emoji: "🫠", mood: .stressed),
        MoodShortcutOption(id: "demotivated", title: "Sem pique", emoji: "🥱", mood: .tired),
        MoodShortcutOption(id: "sensitive", title: "Sensível", emoji: "🥺", mood: .sad),
        MoodShortcutOption(id: "excited", title: "Animado", emoji: "🤩", mood: .happy)
    ]
}

struct EnergySelectionGrid: View {
    let selectedEnergy: EnergyLevel?
    var tint: Color = VenusTheme.primary
    let onSelect: (EnergyLevel) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(EnergyLevel.allCases, id: \.self) { energy in
                OnboardingSelectionRow(
                    title: energy.displayName,
                    detail: energy.supportCopy,
                    systemImage: energy.sfSymbolName,
                    isSelected: selectedEnergy == energy,
                    tint: tint,
                    action: { onSelect(energy) }
                )
            }
        }
    }
}

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

struct MoodShortcutStrip: View {
    let title: String
    let options: [MoodShortcutOption]
    let onSelect: (MoodType) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(options) { option in
                    Button {
                        onSelect(option.mood)
                    } label: {
                        HStack(spacing: 8) {
//                            Text(option.emoji)
//                                .font(.system(size: 18))

                            Text(option.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(option.tint.opacity(0.10))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(option.tint.opacity(0.24), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
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
