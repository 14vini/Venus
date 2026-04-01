//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

private enum MoodCheckInStage {
    case feeling
    case details
}

struct MoodCheckInView: View {
    @ObservedObject var viewModel: MoodCheckInViewModel
    var ritualProgressLabel: String = "Ritual"
    var onCompleted: ((MoodType) -> Void)?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var stage: MoodCheckInStage = .feeling

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
            if stage == .details && viewModel.shouldShowValidationHint {
                VenusFloatingHintBubble(
                    title: viewModel.validationHintTitle,
                    bodyText: viewModel.validationHintBody,
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
            if showsFloatingSaveButton {
                MoodCheckInSaveButton(
                    isSaving: viewModel.isSaving,
                    isReady: viewModel.isReadyToSave,
                    action: {
                        if viewModel.isReadyToSave {
                            viewModel.saveCheckIn()
                        } else {
                            viewModel.triggerValidationHint()
                        }
                    }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(stage == .feeling ? "Check-in" : "Mais contexto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    handleLeadingAction()
                } label: {
                    if stage == .details {
                        Image(systemName: "arrow.left")
                    } else {
                        Image(systemName: "xmark")
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if stage == .details {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedMood) { _, selectedMood in
            guard selectedMood != nil, stage == .feeling else { return }
            stage = .details
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success, let mood = viewModel.selectedMood {
                onCompleted?(mood)
                dismiss()
            }
        }
        .onAppear {
            if viewModel.selectedMood != nil {
                stage = .details
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
                    Text(stage == .feeling ? "Vamos registrar como você está" : "Agora eu só preciso de alguns detalhes")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(stage == .feeling
                         ? "Primeiro escolha o sentimento que mais combina com o seu momento."
                         : "Essas respostas deixam a próxima leitura bem mais útil e mais humana.")
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
        .solidCardStyle(cornerRadius: 28)
    }

    @ViewBuilder
    private var stepSwitcher: some View {
        if stage == .feeling {
            moodStep
        } else {
            detailsStep
        }
    }

    private var moodStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Como você está se sentindo agora?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Escolha a opção que mais parece com o seu momento. Assim que você tocar, eu sigo com a próxima etapa.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MoodSelectionGrid(
                selectedMood: viewModel.selectedMood,
                onSelect: handleMoodSelection
            )
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let selectedMood = viewModel.selectedMood {
                selectedMoodBanner(selectedMood)
            }

            MoodCheckInDetailsCard(
                selectedIntensity: $viewModel.selectedIntensity,
                quickTags: viewModel.quickTags,
                selectedTags: viewModel.selectedTags,
                onToggleTag: viewModel.toggleTag,
                affectedAreas: viewModel.affectedAreas,
                selectedAffectedArea: $viewModel.selectedAffectedArea,
                onSelectAffectedArea: viewModel.selectAffectedArea,
                missingAffectedArea: viewModel.isMissing(.affectedArea),
                energyLevels: viewModel.energyLevels,
                selectedEnergyLevel: $viewModel.selectedEnergyLevel,
                onSelectEnergyLevel: viewModel.selectEnergyLevel,
                missingEnergyLevel: viewModel.isMissing(.energyLevel),
                availableTimes: viewModel.availableTimes,
                selectedAvailableTime: $viewModel.selectedAvailableTime,
                onSelectAvailableTime: viewModel.selectAvailableTime,
                missingAvailableTime: viewModel.isMissing(.availableTime),
                controlLevels: viewModel.controlLevels,
                selectedControlLevel: $viewModel.selectedControlLevel,
                onSelectControlLevel: viewModel.selectControlLevel,
                missingControlLevel: viewModel.isMissing(.controlLevel),
                selectedMentalClarity: $viewModel.selectedMentalClarity,
                sleepQualities: viewModel.sleepQualities,
                selectedSleepQuality: $viewModel.selectedSleepQuality,
                onSelectSleepQuality: viewModel.selectSleepQuality,
                bodySignalOptions: viewModel.bodySignalOptions,
                selectedBodySignals: viewModel.selectedBodySignals,
                onToggleBodySignal: viewModel.toggleBodySignal,
                note: $viewModel.note
            )

            requiredFieldsHint
        }
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

    private var showsFloatingSaveButton: Bool {
        stage == .details
    }

    private var requiredFieldsHint: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: viewModel.isReadyToSave ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(viewModel.isReadyToSave ? VenusTheme.moodMintStrong : VenusTheme.validationError)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isReadyToSave ? "Tudo certo para salvar" : "Campos obrigatórios")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text(viewModel.isReadyToSave ? viewModel.requiredFieldsSummary : "Complete os blocos marcados em vermelho para liberar o botão de salvar.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(viewModel.isReadyToSave ? VenusTheme.cardSurface : VenusTheme.validationErrorSoft)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(viewModel.isReadyToSave ? VenusTheme.cardBorder : VenusTheme.validationErrorBorder, lineWidth: 1)
        )
    }

    private func selectedMoodBanner(_ mood: MoodType) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Text(mood.emoji)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 4) {
                Text("Você marcou \(mood.rawValue.lowercased())")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)

                Text("Agora me conta o que mais está influenciando isso hoje.")
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

    private func handleMoodSelection(_ mood: MoodType) {
        viewModel.selectMood(mood)
    }

    private func handleLeadingAction() {
        if stage == .details {
            stage = .feeling
            return
        }
        dismiss()
    }

    private func extractTrailingNumber(in text: String) -> Int? {
        let digits = text.filter(\.isNumber)
        return Int(digits)
    }
}
