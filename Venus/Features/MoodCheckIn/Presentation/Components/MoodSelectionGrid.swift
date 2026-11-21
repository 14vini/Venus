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

// MARK: - Energia

struct EnergySelectionGrid: View {
    let selectedEnergy: MoodEnergyLevel?
    var tint: Color = VenusJourneyPalette.lilac
    let onSelect: (MoodEnergyLevel) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(MoodEnergyLevel.allCases, id: \.self) { energy in
                VenusJourneySelectionRow(
                    title: energy.displayName,
                    detail: energy.supportCopy,
                    systemImage: energy.sfSymbolName,
                    isSelected: selectedEnergy == energy,
                    tint: tintForEnergy(energy),
                    action: { onSelect(energy) }
                )
            }
        }
    }

    private func tintForEnergy(_ energy: MoodEnergyLevel) -> Color {
        switch energy {
        case .low:
            return VenusJourneyPalette.rose
        case .medium:
            return VenusJourneyPalette.sky
        case .high:
            return VenusJourneyPalette.lilac
        }
    }
}

// MARK: - Humor

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
                        UISelectionFeedbackGenerator().selectionChanged()
                        onSelect(option.mood)
                    } label: {
                        HStack(spacing: 8) {
                            Text(option.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(VenusJourneyPressableStyle())
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
        Button(action: {
            UISelectionFeedbackGenerator().selectionChanged()
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 28))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(mood.rawValue)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                if isSelected {
                    Label("Selecionado", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(VenusJourneyPalette.lilac)
                } else {
                    Text("Toque para continuar")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .leading)
            .padding(14)
            .background(
                isSelected
                    ? LinearGradient(
                        colors: [VenusJourneyPalette.lilac.opacity(0.22), VenusJourneyPalette.rose.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .glassEffect(isSelected ? .clear : .regular.interactive(), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(VenusJourneyPressableStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Humor \(mood.rawValue)")
        .accessibilityValue(isSelected ? "Selecionado" : "Não selecionado")
        .accessibilityHint("Toque para selecionar este estado emocional")
    }
}
