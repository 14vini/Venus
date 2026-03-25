//
//  MoodCheckInViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

enum MoodRequiredField: String, CaseIterable, Identifiable {
    case affectedArea
    case energyLevel
    case availableTime
    case controlLevel

    var id: String { rawValue }

    var title: String {
        switch self {
        case .affectedArea:
            return "Área mais afetada"
        case .energyLevel:
            return "Energia"
        case .availableTime:
            return "Tempo disponível agora"
        case .controlLevel:
            return "Está sob seu controle?"
        }
    }

    var inlineTitle: String {
        switch self {
        case .affectedArea:
            return "área afetada"
        case .energyLevel:
            return "energia"
        case .availableTime:
            return "tempo disponível"
        case .controlLevel:
            return "nível de controle"
        }
    }
}

@MainActor
class MoodCheckInViewModel: ObservableObject {
    @Published var selectedMood: MoodType?
    @Published var note: String = ""
    @Published var selectedIntensity: Double = 5
    @Published var selectedTags: Set<String> = []
    @Published var selectedAffectedArea: MoodAffectedArea?
    @Published var selectedEnergyLevel: MoodEnergyLevel?
    @Published var selectedAvailableTime: MoodAvailableTime?
    @Published var selectedControlLevel: MoodControlLevel?
    @Published var selectedMentalClarity: Double = 5
    @Published var selectedSleepQuality: MoodSleepQuality?
    @Published var selectedBodySignals: Set<String> = []
    @Published var isSaving: Bool = false
    @Published var savedSuccess: Bool = false
    @Published var validationHintVisible: Bool = false
    
    let quickTags = ["Trabalho", "Sono", "Relacionamentos", "Saúde", "Estudos", "Finanças"]
    let bodySignalOptions = ["Tensão muscular", "Respiração curta", "Dor de cabeça", "Cansaço físico", "Agitação", "Sem sintomas"]
    let affectedAreas = MoodAffectedArea.allCases
    let energyLevels = MoodEnergyLevel.allCases
    let availableTimes = MoodAvailableTime.allCases
    let controlLevels = MoodControlLevel.allCases
    let sleepQualities = MoodSleepQuality.allCases

    var isReadyToSave: Bool {
        selectedMood != nil && missingRequiredFields.isEmpty
    }

    var missingRequiredFields: [MoodRequiredField] {
        var missing: [MoodRequiredField] = []

        if selectedAffectedArea == nil {
            missing.append(.affectedArea)
        }
        if selectedEnergyLevel == nil {
            missing.append(.energyLevel)
        }
        if selectedAvailableTime == nil {
            missing.append(.availableTime)
        }
        if selectedControlLevel == nil {
            missing.append(.controlLevel)
        }

        return missing
    }

    var shouldShowValidationHint: Bool {
        selectedMood != nil && (!missingRequiredFields.isEmpty || validationHintVisible)
    }

    var validationHintTitle: String {
        missingRequiredFields.count == 1
        ? "Falta 1 campo obrigatório"
        : "Faltam \(missingRequiredFields.count) campos obrigatórios"
    }

    var validationHintBody: String {
        let fields = missingRequiredFields.map(\.inlineTitle)
        guard !fields.isEmpty else { return "Tudo pronto para salvar seu check-in." }
        return "Complete \(fields.joined(separator: ", ")) para liberar o salvar."
    }

    var requiredFieldsSummary: String {
        if missingRequiredFields.isEmpty {
            return "Tudo pronto para salvar."
        }

        return "Campos em vermelho: \(missingRequiredFields.map(\.inlineTitle).joined(separator: ", "))."
    }

    func triggerValidationHint() {
        withAnimation {
            validationHintVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { validationHintVisible = false }
        }
    }

    func isMissing(_ field: MoodRequiredField) -> Bool {
        missingRequiredFields.contains(field)
    }
    
    private let saveMoodUseCase: SaveMoodUseCaseProtocol
    
    // In a pure DI setup, we would inject the protocol.
    // For simplicity here, we might init with it or use a Factory.
    init(saveMoodUseCase: SaveMoodUseCaseProtocol) {
        self.saveMoodUseCase = saveMoodUseCase
    }
    
    func selectMood(_ mood: MoodType) {
        withAnimation {
            selectedMood = mood
        }
    }

    func startNewCheckIn(prefilledMood: MoodType? = nil) {
        savedSuccess = false
        isSaving = false
        validationHintVisible = false
        selectedMood = prefilledMood
        note = ""
        selectedIntensity = 5
        selectedTags = []
        selectedAffectedArea = nil
        selectedEnergyLevel = nil
        selectedAvailableTime = nil
        selectedControlLevel = nil
        selectedMentalClarity = 5
        selectedSleepQuality = nil
        selectedBodySignals = []
    }
    
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }

    func selectAffectedArea(_ area: MoodAffectedArea) {
        selectedAffectedArea = selectedAffectedArea == area ? nil : area
    }

    func selectEnergyLevel(_ level: MoodEnergyLevel) {
        selectedEnergyLevel = selectedEnergyLevel == level ? nil : level
    }

    func selectAvailableTime(_ availableTime: MoodAvailableTime) {
        selectedAvailableTime = selectedAvailableTime == availableTime ? nil : availableTime
    }

    func selectControlLevel(_ level: MoodControlLevel) {
        selectedControlLevel = selectedControlLevel == level ? nil : level
    }

    func selectSleepQuality(_ quality: MoodSleepQuality) {
        selectedSleepQuality = selectedSleepQuality == quality ? nil : quality
    }

    func toggleBodySignal(_ signal: String) {
        if selectedBodySignals.contains(signal) {
            selectedBodySignals.remove(signal)
        } else {
            if signal == "Sem sintomas" {
                selectedBodySignals = ["Sem sintomas"]
                return
            }
            selectedBodySignals.remove("Sem sintomas")
            selectedBodySignals.insert(signal)
        }
    }
    
    func saveCheckIn() {
        guard let mood = selectedMood else { return }

        savedSuccess = false
        isSaving = true

        Task {
            do {
                _ = try await saveMoodUseCase.execute(
                    type: mood,
                    intensity: Int(selectedIntensity),
                    triggers: selectedTags.sorted(),
                    affectedArea: selectedAffectedArea,
                    energyLevel: selectedEnergyLevel,
                    availableTime: selectedAvailableTime,
                    controlLevel: selectedControlLevel,
                    mentalClarity: Int(selectedMentalClarity),
                    sleepQuality: selectedSleepQuality,
                    bodySignals: normalizedBodySignals(),
                    note: sanitizedNote()
                )
                isSaving = false
                savedSuccess = true
            } catch {
                print("Error saving mood: \(error)")
                isSaving = false
            }
        }
    }

    func resetAfterSave() {
        startNewCheckIn()
    }
    
    private func sanitizedNote() -> String? {
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedNote.isEmpty ? nil : trimmedNote
    }

    private func normalizedBodySignals() -> [String] {
        let containsNoSymptoms = selectedBodySignals.contains("Sem sintomas")
        if containsNoSymptoms {
            return ["Sem sintomas"]
        }
        return selectedBodySignals.sorted()
    }
}
