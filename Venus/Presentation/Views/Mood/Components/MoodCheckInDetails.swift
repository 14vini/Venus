//
//  MoodCheckInDetails.swift
//  Venus
//

import SwiftUI

struct MoodCheckInDetailsCard: View {
    @Binding var selectedIntensity: Double
    let quickTags: [String]
    let selectedTags: Set<String>
    let onToggleTag: (String) -> Void
    let affectedAreas: [MoodAffectedArea]
    @Binding var selectedAffectedArea: MoodAffectedArea?
    let onSelectAffectedArea: (MoodAffectedArea) -> Void
    let energyLevels: [MoodEnergyLevel]
    @Binding var selectedEnergyLevel: MoodEnergyLevel?
    let onSelectEnergyLevel: (MoodEnergyLevel) -> Void
    let availableTimes: [MoodAvailableTime]
    @Binding var selectedAvailableTime: MoodAvailableTime?
    let onSelectAvailableTime: (MoodAvailableTime) -> Void
    let controlLevels: [MoodControlLevel]
    @Binding var selectedControlLevel: MoodControlLevel?
    let onSelectControlLevel: (MoodControlLevel) -> Void
    @Binding var selectedMentalClarity: Double
    let sleepQualities: [MoodSleepQuality]
    @Binding var selectedSleepQuality: MoodSleepQuality?
    let onSelectSleepQuality: (MoodSleepQuality) -> Void
    let bodySignalOptions: [String]
    let selectedBodySignals: Set<String>
    let onToggleBodySignal: (String) -> Void
    @Binding var note: String

    private let tagsColumns = [
        GridItem(.adaptive(minimum: 128), spacing: 10)
    ]
    private let areasColumns = [
        GridItem(.adaptive(minimum: 118), spacing: 10)
    ]
    private let energyColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    private let timeColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    private let controlColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    private let sleepColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 10)
    ]
    private let bodySignalsColumns = [
        GridItem(.adaptive(minimum: 138), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Intensidade")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                Text("\(Int(selectedIntensity))/10")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
            }

            Slider(value: $selectedIntensity, in: 1...10, step: 1)
                .tint(Color(hex: "FF5F15"))

            HStack {
                Text("Leve")
                    .font(.caption)
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text("Forte")
                    .font(.caption)
                    .foregroundColor(VenusTheme.textSecondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Gatilhos")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: tagsColumns, spacing: 10) {
                    ForEach(quickTags, id: \.self) { tag in
                        MoodSelectableChip(
                            title: tag,
                            isSelected: selectedTags.contains(tag),
                            action: { onToggleTag(tag) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Área afetada")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: areasColumns, spacing: 10) {
                    ForEach(affectedAreas, id: \.rawValue) { area in
                        MoodSelectableChip(
                            title: area.rawValue,
                            isSelected: selectedAffectedArea == area,
                            action: { onSelectAffectedArea(area) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Energia")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: energyColumns, spacing: 10) {
                    ForEach(energyLevels, id: \.rawValue) { level in
                        MoodSelectableChip(
                            title: level.rawValue,
                            isSelected: selectedEnergyLevel == level,
                            action: { onSelectEnergyLevel(level) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Tempo disponível agora")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: timeColumns, spacing: 10) {
                    ForEach(availableTimes, id: \.rawValue) { availableTime in
                        MoodSelectableChip(
                            title: availableTime.rawValue,
                            isSelected: selectedAvailableTime == availableTime,
                            action: { onSelectAvailableTime(availableTime) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Está sob seu controle?")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: controlColumns, spacing: 10) {
                    ForEach(controlLevels, id: \.rawValue) { controlLevel in
                        MoodSelectableChip(
                            title: controlLevel.rawValue,
                            isSelected: selectedControlLevel == controlLevel,
                            action: { onSelectControlLevel(controlLevel) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Clareza mental")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    Spacer()
                    Text("\(Int(selectedMentalClarity))/10")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                }

                Slider(value: $selectedMentalClarity, in: 1...10, step: 1)
                    .tint(Color(hex: "FF5F15"))
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Qualidade do sono")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: sleepColumns, spacing: 10) {
                    ForEach(sleepQualities, id: \.rawValue) { quality in
                        MoodSelectableChip(
                            title: quality.rawValue,
                            isSelected: selectedSleepQuality == quality,
                            action: { onSelectSleepQuality(quality) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Sinais no corpo")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                LazyVGrid(columns: bodySignalsColumns, spacing: 10) {
                    ForEach(bodySignalOptions, id: \.self) { signal in
                        MoodSelectableChip(
                            title: signal,
                            isSelected: selectedBodySignals.contains(signal),
                            action: { onToggleBodySignal(signal) }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Nota livre (opcional)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                TextField("Ex: reunião difícil no trabalho...", text: $note, axis: .vertical)
                    .lineLimit(2...5)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(VenusTheme.cardSurfaceStrong)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(VenusTheme.cardBorder, lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 30)
    }
}

private struct MoodSelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(hex: "FFE6DA") : VenusTheme.cardSurfaceStrong)
                )
                .overlay(
                    Capsule().stroke(VenusTheme.cardBorder, lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
