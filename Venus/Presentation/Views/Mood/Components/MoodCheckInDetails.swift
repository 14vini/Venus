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
    let missingAffectedArea: Bool
    let energyLevels: [MoodEnergyLevel]
    @Binding var selectedEnergyLevel: MoodEnergyLevel?
    let onSelectEnergyLevel: (MoodEnergyLevel) -> Void
    let missingEnergyLevel: Bool
    let availableTimes: [MoodAvailableTime]
    @Binding var selectedAvailableTime: MoodAvailableTime?
    let onSelectAvailableTime: (MoodAvailableTime) -> Void
    let missingAvailableTime: Bool
    let controlLevels: [MoodControlLevel]
    @Binding var selectedControlLevel: MoodControlLevel?
    let onSelectControlLevel: (MoodControlLevel) -> Void
    let missingControlLevel: Bool
    @Binding var selectedMentalClarity: Double
    let sleepQualities: [MoodSleepQuality]
    @Binding var selectedSleepQuality: MoodSleepQuality?
    let onSelectSleepQuality: (MoodSleepQuality) -> Void
    let bodySignalOptions: [String]
    let selectedBodySignals: Set<String>
    let onToggleBodySignal: (String) -> Void
    @Binding var note: String
    @State private var isOptionalExpanded = false

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
            MoodGroupHeader(
                title: "Essencial",
                subtitle: "Complete esses campos para salvar seu check-in.",
                tint: VenusTheme.moodMintStrong
            )

            MoodDetailSection(
                title: "O que mais está pesando agora",
                subtitle: "Escolha o que mais influencia seu dia neste momento.",
                systemImage: "sparkles"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    MoodFieldBlock(title: "Gatilhos") {
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

                    MoodFieldBlock(
                        title: "Área mais afetada",
                        isRequired: true,
                        isMissing: missingAffectedArea
                    ) {
                        LazyVGrid(columns: areasColumns, spacing: 10) {
                            ForEach(affectedAreas, id: \.rawValue) { area in
                                MoodAreaButton(
                                    area: area,
                                    isSelected: selectedAffectedArea == area,
                                    action: { onSelectAffectedArea(area) }
                                )
                            }
                        }
                    }
                }
            }

            MoodDetailSection(
                title: "Como você está para agir",
                subtitle: "Esse contexto deixa a sugestão mais realista para o agora.",
                systemImage: "figure.walk.motion"
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    MoodFieldBlock(
                        title: "Energia",
                        isRequired: true,
                        isMissing: missingEnergyLevel
                    ) {
                        LazyVGrid(columns: energyColumns, spacing: 10) {
                            ForEach(energyLevels, id: \.rawValue) { level in
                                MoodEnergyButton(
                                    level: level,
                                    isSelected: selectedEnergyLevel == level,
                                    action: { onSelectEnergyLevel(level) }
                                )
                            }
                        }
                    }

                    MoodFieldBlock(
                        title: "Tempo disponível agora",
                        isRequired: true,
                        isMissing: missingAvailableTime
                    ) {
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

                    MoodFieldBlock(
                        title: "Está sob seu controle?",
                        isRequired: true,
                        isMissing: missingControlLevel
                    ) {
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
                }
            }

            DisclosureGroup(isExpanded: $isOptionalExpanded) {
                VStack(alignment: .leading, spacing: 18) {
                    MoodDetailSection(
                        title: "Intensidade do momento",
                        subtitle: "Isso ajuda a dosar melhor o que o app te propõe depois.",
                        systemImage: "dial.medium.fill"
                    ) {
                        MoodSliderRow(
                            title: "Intensidade",
                            value: $selectedIntensity,
                            lowLabel: "Leve",
                            highLabel: "Forte",
                            tint: VenusTheme.moodMintStrong
                        )
                    }

                    MoodDetailSection(
                        title: "Corpo e clareza",
                        subtitle: "Esses sinais ajudam a entender se hoje pede foco, leveza ou recuperação.",
                        systemImage: "brain.head.profile"
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            MoodSliderRow(
                                title: "Clareza mental",
                                value: $selectedMentalClarity,
                                lowLabel: "Confuso",
                                highLabel: "Claro",
                                tint: VenusTheme.accentGreen
                            )

                            MoodFieldBlock(title: "Qualidade do sono") {
                                LazyVGrid(columns: sleepColumns, spacing: 10) {
                                    ForEach(sleepQualities, id: \.rawValue) { quality in
                                        MoodSleepButton(
                                            quality: quality,
                                            isSelected: selectedSleepQuality == quality,
                                            action: { onSelectSleepQuality(quality) }
                                        )
                                    }
                                }
                            }

                            MoodFieldBlock(title: "Sinais no corpo") {
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
                        }
                    }

                    MoodDetailSection(
                        title: "Se quiser, escreva um pouco mais",
                        subtitle: "Opcional. Uma frase curta já ajuda bastante.",
                        systemImage: "text.bubble"
                    ) {
                        TextField("Ex: reunião difícil no trabalho", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(VenusTheme.cardSurfaceStrong)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(VenusTheme.cardBorder, lineWidth: 1)
                            )
                    }
                }
                .padding(.top, 6)
            } label: {
                MoodGroupHeader(
                    title: "Opcional",
                    subtitle: isOptionalExpanded
                    ? "Detalhes extras para deixar a leitura ainda mais precisa."
                    : "Abra se quiser adicionar contexto extra.",
                    tint: VenusTheme.accentBlue,
                    isExpanded: isOptionalExpanded
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MoodGroupHeader: View {
    let title: String
    let subtitle: String
    let tint: Color
    var isExpanded: Bool? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.text)

                    Text(title == "Essencial" ? "Salvar depende disso" : "Complementa a leitura")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(tint.opacity(0.12))
                        )
                }

                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if let isExpanded {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(tint)
            }
        }
    }
}

private struct MoodDetailSection<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let content: Content

    init(
        title: String,
        subtitle: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(VenusTheme.moodMintStrong.opacity(0.14))
                        .frame(width: 40, height: 40)

                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(VenusTheme.moodMintStrong)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 28)
    }
}

private struct MoodFieldBlock<Content: View>: View {
    let title: String
    var isRequired: Bool = false
    var isMissing: Bool = false
    let content: Content

    init(
        title: String,
        isRequired: Bool = false,
        isMissing: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.isMissing = isMissing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(isMissing ? VenusTheme.validationError : VenusTheme.text)

                if isRequired {
                    Text(isMissing ? "Falta preencher" : "Obrigatório")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(isMissing ? VenusTheme.validationError : VenusTheme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(isMissing ? VenusTheme.validationErrorSoft : VenusTheme.cardSurfaceStrong)
                        )
                }
            }

            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isMissing ? VenusTheme.validationErrorSoft.opacity(0.68) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isMissing ? VenusTheme.validationErrorBorder : Color.clear, lineWidth: 1)
        )
    }
}

private struct MoodSliderRow: View {
    let title: String
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Spacer()

                Text("\(Int(value))/10")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(tint)
            }

            Slider(value: $value, in: 1...10, step: 1)
                .tint(tint)

            HStack {
                Text(lowLabel)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text(highLabel)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
    }
}

private struct MoodEnergyButton: View {
    let level: MoodEnergyLevel
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch level {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.100.bolt"
        }
    }

    private var tint: Color {
        switch level {
        case .low: return VenusTheme.accentBlue
        case .medium: return VenusTheme.primary
        case .high: return VenusTheme.accentGreen
        }
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
                Text(level.rawValue)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.12) : VenusTheme.cardSurfaceStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.4) : VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MoodSleepButton: View {
    let quality: MoodSleepQuality
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch quality {
        case .poor: return "moon.zzz"
        case .fair: return "moon.haze.fill"
        case .good: return "moon.stars.fill"
        case .excellent: return "sparkles"
        }
    }

    private var tint: Color {
        switch quality {
        case .poor: return VenusTheme.accentBlue
        case .fair: return VenusTheme.primary
        case .good: return VenusTheme.moodMintStrong
        case .excellent: return VenusTheme.accentGreen
        }
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
                Text(quality.rawValue)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.12) : VenusTheme.cardSurfaceStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.4) : VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct MoodAreaButton: View {
    let area: MoodAffectedArea
    let isSelected: Bool
    let action: () -> Void

    private var icon: String {
        switch area {
        case .work: return "briefcase.fill"
        case .relationship: return "heart.fill"
        case .health: return "cross.fill"
        case .discipline: return "checkmark.seal.fill"
        case .finances: return "dollarsign.circle.fill"
        case .studies: return "book.fill"
        case .social: return "person.2.fill"
        case .family: return "house.fill"
        case .personal: return "person.fill"
        }
    }

    private var tint: Color {
        switch area {
        case .work: return VenusTheme.moodMintStrong
        case .relationship: return VenusTheme.primary
        case .health: return VenusTheme.accentGreen
        case .discipline: return VenusTheme.accentBlue
        case .finances: return VenusTheme.accentGreen
        case .studies: return VenusTheme.accentBlue
        case .social: return VenusTheme.moodMintStrong
        case .family: return VenusTheme.primary
        case .personal: return VenusTheme.accentBlue
        }
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? tint.opacity(0.18) : VenusTheme.cardSurfaceStrong)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
                }
                Text(area.rawValue)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(isSelected ? tint : VenusTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.08) : VenusTheme.cardSurfaceStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? tint.opacity(0.4) : VenusTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
                .foregroundColor(isSelected ? VenusTheme.moodMintStrong : VenusTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? VenusTheme.moodMintStrong.opacity(0.12) : VenusTheme.cardSurfaceStrong)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? VenusTheme.moodMintStrong.opacity(0.3) : VenusTheme.cardBorder, lineWidth: 1)
                )
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
