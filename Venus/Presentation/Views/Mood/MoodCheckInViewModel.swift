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
    case energyLevel
    case mood
    case tags
    case affectedArea
    case availableTime
    case controlLevel
    case sleepQuality
    case bodySignals
    case note

    var id: String { rawValue }

    var title: String {
        switch self {
        case .energyLevel: return "Energia"
        case .mood: return "Sentimento"
        case .tags: return "Gatilhos"
        case .affectedArea: return "Área Afetada"
        case .availableTime: return "Tempo Disponível"
        case .controlLevel: return "Controle"
        case .sleepQuality: return "Qualidade do Sono"
        case .bodySignals: return "Sinais no Corpo"
        case .note: return "Nota Curta"
        }
    }

    var inlineTitle: String {
        title.lowercased()
    }
}

@MainActor
class MoodCheckInViewModel: ObservableObject {
    @Published var selectedZenithEnergy: EnergyLevel?
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
        missingRequiredFields.isEmpty
    }

    var missingRequiredFields: [MoodRequiredField] {
        var missing: [MoodRequiredField] = []
        if selectedZenithEnergy == nil { missing.append(.energyLevel) }
        if selectedMood == nil { missing.append(.mood) }
        if selectedTags.isEmpty { missing.append(.tags) }
        if selectedAffectedArea == nil { missing.append(.affectedArea) }
        if selectedAvailableTime == nil { missing.append(.availableTime) }
        if selectedControlLevel == nil { missing.append(.controlLevel) }
        if selectedSleepQuality == nil { missing.append(.sleepQuality) }
        if selectedBodySignals.isEmpty { missing.append(.bodySignals) }
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { missing.append(.note) }
        return missing
    }

    var shouldShowValidationHint: Bool {
        !missingRequiredFields.isEmpty && validationHintVisible
    }

    var validationHintTitle: String {
        "Faltam informações"
    }

    var validationHintBody: String {
        "Preencha todos os campos obrigatórios para salvar."
    }

    var requiredFieldsSummary: String {
        if isReadyToSave {
            return "Tudo pronto para salvar."
        }
        return "Complete todas as etapas."
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
        selectedZenithEnergy = nil
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

        if let prefilledMood {
            selectedZenithEnergy = mapZenithEnergy(from: prefilledMood)
            selectedEnergyLevel = mapMoodEnergy(from: selectedZenithEnergy)
        }
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

    func selectZenithEnergy(_ energy: EnergyLevel) {
        selectedZenithEnergy = energy
        selectedEnergyLevel = mapMoodEnergy(from: energy)
        selectedMood = mapMoodType(from: energy)
        validationHintVisible = false
    }

    func selectEnergyLevel(_ level: MoodEnergyLevel) {
        selectedEnergyLevel = selectedEnergyLevel == level ? nil : level
        guard let selectedEnergyLevel else {
            selectedZenithEnergy = nil
            selectedMood = nil
            return
        }
        let mappedEnergy = mapZenithEnergy(from: selectedEnergyLevel)
        selectedZenithEnergy = mappedEnergy
        selectedMood = mapMoodType(from: mappedEnergy)
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

    private func mapMoodType(from energy: EnergyLevel) -> MoodType {
        switch energy {
        case .critical:
            return .tired
        case .regular:
            return .calm
        case .full:
            return .energetic
        }
    }

    private func mapMoodEnergy(from energy: EnergyLevel?) -> MoodEnergyLevel? {
        switch energy {
        case .critical:
            return .low
        case .regular:
            return .medium
        case .full:
            return .high
        case .none:
            return nil
        }
    }

    private func mapZenithEnergy(from mood: MoodType) -> EnergyLevel {
        switch mood {
        case .tired, .sad, .stressed:
            return .critical
        case .calm, .happy:
            return .regular
        case .energetic:
            return .full
        }
    }

    private func mapZenithEnergy(from energyLevel: MoodEnergyLevel) -> EnergyLevel {
        switch energyLevel {
        case .low:
            return .critical
        case .medium:
            return .regular
        case .high:
            return .full
        }
    }
}
