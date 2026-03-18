//
//  MoodCheckInView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MoodCheckInView: View {
    @ObservedObject var viewModel: MoodCheckInViewModel
    var ritualProgressLabel: String = "Ritual"
    var onCompleted: ((MoodType) -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 300, height: 300)
                    .blur(radius: 44)
                    .offset(x: -130, y: -240)

                Circle()
                    .fill(Color(hex: "FF5F15").opacity(0.12))
                    .frame(width: 220, height: 220)
                    .blur(radius: 40)
                    .offset(x: 140, y: 210)
            }
            .ignoresSafeArea()

            VStack(spacing: 14) {
                MoodCheckInHeader(
                    ritualProgressLabel: ritualProgressLabel,
                    onClose: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        MoodCheckInHeroCard()

                        MoodSelectionGrid(
                            selectedMood: viewModel.selectedMood,
                            onSelect: viewModel.selectMood
                        )

                        if viewModel.selectedMood != nil {
                            MoodCheckInDetailsCard(
                                selectedIntensity: $viewModel.selectedIntensity,
                                quickTags: viewModel.quickTags,
                                selectedTags: viewModel.selectedTags,
                                onToggleTag: viewModel.toggleTag,
                                affectedAreas: viewModel.affectedAreas,
                                selectedAffectedArea: $viewModel.selectedAffectedArea,
                                onSelectAffectedArea: viewModel.selectAffectedArea,
                                energyLevels: viewModel.energyLevels,
                                selectedEnergyLevel: $viewModel.selectedEnergyLevel,
                                onSelectEnergyLevel: viewModel.selectEnergyLevel,
                                availableTimes: viewModel.availableTimes,
                                selectedAvailableTime: $viewModel.selectedAvailableTime,
                                onSelectAvailableTime: viewModel.selectAvailableTime,
                                controlLevels: viewModel.controlLevels,
                                selectedControlLevel: $viewModel.selectedControlLevel,
                                onSelectControlLevel: viewModel.selectControlLevel,
                                selectedMentalClarity: $viewModel.selectedMentalClarity,
                                sleepQualities: viewModel.sleepQualities,
                                selectedSleepQuality: $viewModel.selectedSleepQuality,
                                onSelectSleepQuality: viewModel.selectSleepQuality,
                                bodySignalOptions: viewModel.bodySignalOptions,
                                selectedBodySignals: viewModel.selectedBodySignals,
                                onToggleBodySignal: viewModel.toggleBodySignal,
                                note: $viewModel.note
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if viewModel.selectedMood != nil {
                FloatingSaveButton(
                    isSaving: viewModel.isSaving,
                    action: viewModel.saveCheckIn
                )
                .padding(.trailing, 20)
                .padding(.bottom, 24)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: viewModel.selectedMood != nil)
            }
        }
        .onChange(of: viewModel.savedSuccess) { _, success in
            if success, let mood = viewModel.selectedMood {
                onCompleted?(mood)
                dismiss()
            }
        }
    }
}

private struct FloatingSaveButton: View {
    let isSaving: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(isSaving ? "Salvando..." : "Salvar check-in")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color(hex: "FF3D00").opacity(0.35), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
