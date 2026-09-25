//
//  MoodCheckInViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI

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

@Observable
@MainActor
final class MoodCheckInViewModel {
    var selectedMood: MoodType?
    var selectedEnergyLevel: MoodEnergyLevel?
    var note: String = ""
    var selectedIntensity: Double = 5
    var selectedTags: Set<String> = []
    var selectedAffectedArea: MoodAffectedArea?
    var selectedAvailableTime: MoodAvailableTime?
    var selectedControlLevel: MoodControlLevel?
    var selectedMentalClarity: Double = 5
    var selectedSleepQuality: MoodSleepQuality?
    var selectedBodySignals: Set<String> = []
    var isSaving: Bool = false
    var savedSuccess: Bool = false
    var validationHintVisible: Bool = false
    
    let quickTags = ["Trabalho", "Sono", "Relacionamentos", "Saúde", "Estudos", "Finanças"]
    let bodySignalOptions = ["Tensão muscular", "Respiração curta", "Dor de cabeça", "Cansaço físico", "Agitação", "Sem sintomas"]
    let affectedAreas = MoodAffectedArea.allCases
    let energyLevels = MoodEnergyLevel.allCases
    let availableTimes = MoodAvailableTime.allCases
    let controlLevels = MoodControlLevel.allCases
    let sleepQualities = MoodSleepQuality.allCases

    /// Save rápido (10s): só energia + humor. Fluxo completo continua opcional.
    var isQuickSaveReady: Bool {
        selectedEnergyLevel != nil && selectedMood != nil
    }

    var isReadyToSave: Bool {
        missingRequiredFields.isEmpty
    }

    var isReadyForFullSave: Bool { isReadyToSave }

    var missingRequiredFields: [MoodRequiredField] {
        var missing: [MoodRequiredField] = []
        if selectedEnergyLevel == nil { missing.append(.energyLevel) }
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

    private let saveMoodUseCase: SaveMoodUseCaseProtocol
    
    init(saveMoodUseCase: SaveMoodUseCaseProtocol) {
        self.saveMoodUseCase = saveMoodUseCase
    }

    func triggerValidationHint() {
        withAnimation {
            validationHintVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation { self.validationHintVisible = false }
        }
    }

    func isMissing(_ field: MoodRequiredField) -> Bool {
        missingRequiredFields.contains(field)
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
        selectedAvailableTime = nil
        selectedControlLevel = nil
        selectedMentalClarity = 5
        selectedSleepQuality = nil
        selectedBodySignals = []

        if let prefilledMood {
            selectedEnergyLevel = mapEnergy(from: prefilledMood)
        } else {
            selectedEnergyLevel = nil
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

    func selectEnergyLevel(_ level: MoodEnergyLevel) {
        // NÃO sobrescreve o humor escolhido pelo usuário (bug anterior: low -> tired).
        // Energia e humor são independentes; o score combina os dois.
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
    
    /// Check-in rápido de 10s: salva só humor + energia, resto nil.
    func saveQuickCheckIn() {
        guard let mood = selectedMood else { return }
        savedSuccess = false
        isSaving = true
        let energy = selectedEnergyLevel
        Task {
            do {
                _ = try await saveMoodUseCase.execute(
                    type: mood,
                    intensity: Int(selectedIntensity),
                    triggers: [],
                    affectedArea: nil,
                    energyLevel: energy,
                    availableTime: nil,
                    controlLevel: nil,
                    mentalClarity: Int(selectedMentalClarity),
                    sleepQuality: nil,
                    bodySignals: [],
                    note: sanitizedNote()
                )
                self.isSaving = false
                self.savedSuccess = true
            } catch {
                print("Error saving quick mood: \(error)")
                self.isSaving = false
            }
        }
    }

    func saveCheckIn() {
        // Se só tem o essencial, faz quick save em vez de bloquear
        if isQuickSaveReady && !isReadyToSave {
            saveQuickCheckIn()
            return
        }
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
                self.isSaving = false
                self.savedSuccess = true
            } catch {
                print("Error saving mood: \(error)")
                self.isSaving = false
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

    private func mapEnergy(from mood: MoodType) -> MoodEnergyLevel {
        switch mood {
        case .tired, .sad, .stressed:
            return .low
        case .calm, .happy:
            return .medium
        case .energetic:
            return .high
        }
    }

    private func mapMood(from energy: MoodEnergyLevel) -> MoodType {
        switch energy {
        case .low:
            return .tired
        case .medium:
            return .calm
        case .high:
            return .energetic
        }
    }
}
