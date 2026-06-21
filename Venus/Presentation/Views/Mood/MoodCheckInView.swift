//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

private enum MoodCheckInStage {
    case general
    case details
}

struct MoodCheckInView: View {
    @ObservedObject var viewModel: MoodCheckInViewModel
    var ritualProgressLabel: String = "Ritual"
    var onCompleted: ((MoodType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var stage: MoodCheckInStage = .general
    @State private var slideDirection: Int = 1
    @State private var inlineHint: CheckInHint?
    @State private var showOptionalSection = false

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.moodMintStrong,
                secondaryAccent: VenusTheme.moodSage,
                tertiaryAccent: VenusTheme.accentGreen,
                isAnimated: false
            )

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    quotaBanner
                        .venusScrollMotion(.gentle)
                    stepSwitcher
                        .venusScrollMotion(.gentle)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        }
        .overlay(alignment: .top) {
            if let inlineHint {
                VenusFloatingHintBubble(
                    title: inlineHint.title,
                    bodyText: inlineHint.body,
                    systemImage: "exclamationmark.circle.fill",
                    tint: VenusTheme.validationError,
                    maxWidth: 340
                )
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            footerActions
                .padding(.trailing, 20)
                .padding(.bottom, 24)
        }
        .navigationTitle("Check-in")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleLeadingAction()
                } label: {
                    if stage != .general {
                        Image(systemName: "arrow.left")
                    } else {
                        Image(systemName: "xmark")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if stage != .general {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success, let mood = viewModel.selectedMood {
                onCompleted?(mood)
                dismiss()
            }
        }
    }

    private var quotaBanner: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(VenusTheme.moodMintStrong.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: "drop.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(VenusTheme.moodMintStrong)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(stage == .general ? "Como está sua energia?" : "Mais contexto, se quiser")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stage == .general
                         ? "Escolha rápido e siga."
                         : "Detalhes finais.")
                         .font(.system(.footnote, design: .rounded))
                         .foregroundColor(VenusTheme.textSecondary)
                         .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(checkInQuotaTitle)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                if let progress = checkInQuotaProgress {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(VenusTheme.cardBorder.opacity(0.32))

                            Capsule()
                                .fill(VenusTheme.primaryGradient)
                                .frame(width: max(20, geometry.size.width * progress))
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepSwitcher: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepProgress

            ZStack {
                currentStepCard
                    .id(stageID)
                    .transition(stageTransition)
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.86), value: stageID)
        }
    }

    private var generalStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Como você está se sentindo?")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Selecione sua energia e o sentimento predominante de hoje.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Bateria mental de hoje")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                EnergySelectionGrid(
                    selectedEnergy: viewModel.selectedZenithEnergy,
                    onSelect: handleEnergySelection
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Sentimento predominante")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                MoodSelectionGrid(
                    selectedMood: viewModel.selectedMood,
                    onSelect: handleMoodSelection
                )

                MoodShortcutStrip(
                    title: "Atalhos para indecisão",
                    options: MoodShortcutOption.indecisive,
                    onSelect: handleMoodSelection
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stageTitle("O que mais puxou isso?", subtitle: "Adicione contexto para calibrar as sugestões da Venus.")

            if let selectedMood = viewModel.selectedMood {
                selectedMoodBanner(selectedMood)
            }

            fieldSection("Gatilhos") {
                FlowChips(options: viewModel.quickTags, selectedOptions: viewModel.selectedTags, onToggle: viewModel.toggleTag)
            }

            fieldSection("Área mais afetada") {
                FlowSingleChoice(options: viewModel.affectedAreas.map(\.rawValue), selectedOption: viewModel.selectedAffectedArea?.rawValue) { rawValue in
                    if let area = viewModel.affectedAreas.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectAffectedArea(area)
                    }
                }
            }

            fieldSection("Tempo disponível agora") {
                FlowSingleChoice(options: viewModel.availableTimes.map(\.rawValue), selectedOption: viewModel.selectedAvailableTime?.rawValue) { rawValue in
                    if let item = viewModel.availableTimes.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectAvailableTime(item)
                    }
                }
            }

            fieldSection("Isso está sob seu controle?") {
                FlowSingleChoice(options: viewModel.controlLevels.map(\.rawValue), selectedOption: viewModel.selectedControlLevel?.rawValue) { rawValue in
                    if let item = viewModel.controlLevels.first(where: { $0.rawValue == rawValue }) {
                        viewModel.selectControlLevel(item)
                    }
                }
            }

            DisclosureGroup(
                isExpanded: $showOptionalSection,
                content: {
                    VStack(alignment: .leading, spacing: 18) {
                        Divider()
                            .padding(.vertical, 8)

                        fieldSection("Clareza mental") {
                            SimpleSliderCard(
                                value: $viewModel.selectedMentalClarity,
                                lowLabel: "Confuso",
                                highLabel: "Claro",
                                tint: VenusTheme.accentGreen
                            )
                        }

                        fieldSection("Qualidade do sono") {
                            FlowSingleChoice(options: viewModel.sleepQualities.map(\.rawValue), selectedOption: viewModel.selectedSleepQuality?.rawValue) { rawValue in
                                if let item = viewModel.sleepQualities.first(where: { $0.rawValue == rawValue }) {
                                    viewModel.selectSleepQuality(item)
                                }
                            }
                        }

                        fieldSection("Sinais no corpo") {
                            FlowChips(options: viewModel.bodySignalOptions, selectedOptions: viewModel.selectedBodySignals, onToggle: viewModel.toggleBodySignal)
                        }

                        fieldSection("Nota curta") {
                            TextField("Ex: reunião puxada", text: $viewModel.note, axis: .vertical)
                                .lineLimit(2...4)
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
                },
                label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(VenusTheme.moodMintStrong)
                        Text("Adicionar mais detalhes (opcional)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(VenusTheme.text)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            )
            .tint(VenusTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var checkInQuotaTitle: String {
        let values = parsedQuotaValues
        guard let current = values.current else { return ritualProgressLabel }

        if let total = values.total {
            return "\(current) de \(total) check-ins hoje"
        }

        return "\(current) check-ins hoje"
    }

    private var checkInQuotaProgress: CGFloat? {
        let values = parsedQuotaValues
        guard let current = values.current, let total = values.total, total > 0 else { return nil }
        return min(CGFloat(current) / CGFloat(total), 1)
    }

    private var parsedQuotaValues: (current: Int?, total: Int?) {
        guard let slashIndex = ritualProgressLabel.firstIndex(of: "/") else {
            return (extractTrailingNumber(in: ritualProgressLabel), nil)
        }

        let beforeSlash = String(ritualProgressLabel[..<slashIndex])
        let afterSlash = String(ritualProgressLabel[ritualProgressLabel.index(after: slashIndex)...])

        let current = extractTrailingNumber(in: beforeSlash)
        let total = Int(afterSlash.filter(\.isNumber))
        return (current, total)
    }

    private var stageIndex: Int {
        switch stage {
        case .general: return 0
        case .details: return 1
        }
    }

    private var stageID: Int { stageIndex }

    private var currentStepCard: some View {
        Group {
            switch stage {
            case .general:
                generalStep
            case .details:
                detailsStep
            }
        }
    }

    private var stepProgress: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Capsule(style: .continuous)
                    .fill(progressColor(for: index))
                    .frame(height: 4)
            }
        }
    }

    private func progressColor(for index: Int) -> Color {
        if index < stageIndex { return VenusTheme.moodMintStrong.opacity(0.34) }
        if index == stageIndex { return VenusTheme.moodMintStrong }
        return colorScheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.12)
    }

    private var footerActions: some View {
        HStack(spacing: 12) {
            if stage != .general {
                Button {
                    moveBack()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(VenusTheme.text)
                        .frame(width: 48, height: 48)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                        )
                }
                .buttonStyle(.plain)
            }

            if stage == .details {
                MoodCheckInSaveButton(
                    isSaving: viewModel.isSaving,
                    isReady: viewModel.isReadyToSave,
                    action: saveIfPossible
                )
            } else {
                Button {
                    moveForward()
                } label: {
                    HStack(spacing: 8) {
                        Text("Continuar")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(Color(UIColor.systemBackground))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(Color.primary)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var stageTransition: AnyTransition {
        let insertion: AnyTransition = slideDirection >= 0
            ? .move(edge: .trailing).combined(with: .opacity)
            : .move(edge: .leading).combined(with: .opacity)
        let removal: AnyTransition = slideDirection >= 0
            ? .move(edge: .leading).combined(with: .opacity)
            : .move(edge: .trailing).combined(with: .opacity)
        return .asymmetric(insertion: insertion, removal: removal)
    }

    private func selectedMoodBanner(_ mood: MoodType) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(mood.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.selectedZenithEnergy?.displayName ?? mood.rawValue)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text("Adicione contexto só se ajudar.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            VenusGlassPill(
                title: mood.rawValue,
                systemImage: "checkmark.circle.fill",
                tint: VenusTheme.moodMintStrong
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    colorScheme == .dark
                    ? LinearGradient(
                        colors: [Color(hex: "1A2B1C"), Color(hex: "1E3020")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(
                        colors: [Color.white, VenusTheme.moodMist, Color(hex: "EDF5EA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    colorScheme == .dark ? Color(hex: "2E4A32").opacity(0.85) : Color(hex: "C8D8C2").opacity(0.95),
                    lineWidth: 1
                )
        )
    }

    private func handleEnergySelection(_ energy: EnergyLevel) {
        viewModel.selectZenithEnergy(energy)
    }

    private func handleMoodSelection(_ mood: MoodType) {
        viewModel.selectMood(mood)
    }

    private func handleLeadingAction() {
        if stage != .general {
            moveBack()
            return
        }
        dismiss()
    }

    private func moveForward() {
        switch stage {
        case .general:
            guard viewModel.selectedZenithEnergy != nil else {
                presentHint(title: "Escolha sua energia", body: "Marque se sua bateria esta critica, regular ou cheia.")
                return
            }
            guard viewModel.selectedMood != nil else {
                presentHint(title: "Escolha um sentimento", body: "Pode ser o mais proximo ou um dos atalhos de indecisao.")
                return
            }
            goToStage(.details, direction: 1)
        case .details:
            saveIfPossible()
        }
    }

    private func moveBack() {
        switch stage {
        case .general:
            dismiss()
        case .details:
            goToStage(.general, direction: -1)
        }
    }

    private func goToStage(_ newStage: MoodCheckInStage, direction: Int) {
        slideDirection = direction
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            stage = newStage
        }
    }

    private func saveIfPossible() {
        guard viewModel.isReadyToSave else {
            presentHint(title: "Falta um passo", body: "Confere energia e sentimento antes de salvar.")
            return
        }
        viewModel.saveCheckIn()
    }

    private func presentHint(title: String, body: String) {
        withAnimation {
            inlineHint = CheckInHint(title: title, body: body)
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            withAnimation {
                inlineHint = nil
            }
        }
    }

    private func stageTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(VenusTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fieldSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.textSecondary)
            content()
        }
    }

    private func extractTrailingNumber(in text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }
}

private struct CheckInHint {
    let title: String
    let body: String
}

private struct FlowChips: View {
    let options: [String]
    let selectedOptions: Set<String>
    let onToggle: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { option in
                ChoiceChip(
                    title: option,
                    isSelected: selectedOptions.contains(option),
                    action: { onToggle(option) }
                )
            }
        }
    }
}

private struct FlowSingleChoice: View {
    let options: [String]
    let selectedOption: String?
    let onSelect: (String) -> Void

    private let columns = [GridItem(.adaptive(minimum: 118), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(options, id: \.self) { option in
                ChoiceChip(
                    title: option,
                    isSelected: selectedOption == option,
                    action: { onSelect(option) }
                )
            }
        }
    }
}

private struct ChoiceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundColor(isSelected ? VenusTheme.moodMintStrong : VenusTheme.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? VenusTheme.moodMintStrong.opacity(0.12) : VenusTheme.cardSurfaceStrong)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(isSelected ? VenusTheme.moodMintStrong.opacity(0.35) : VenusTheme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct SimpleSliderCard: View {
    @Binding var value: Double
    let lowLabel: String
    let highLabel: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(Int(value))/10")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(tint)
                Spacer()
            }

            Slider(value: $value, in: 1...10, step: 1)
                .tint(tint)

            HStack {
                Text(lowLabel)
                Spacer()
                Text(highLabel)
            }
            .font(.system(.caption, design: .rounded))
            .foregroundColor(VenusTheme.textSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(VenusTheme.cardSurfaceStrong)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(VenusTheme.cardBorder, lineWidth: 1)
        )
    }
}
