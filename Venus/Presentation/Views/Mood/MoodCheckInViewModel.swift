//
//  MoodCheckInViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

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
    
    let quickTags = ["Trabalho", "Sono", "Relacionamentos", "Saúde", "Estudos", "Finanças"]
    let bodySignalOptions = ["Tensão muscular", "Respiração curta", "Dor de cabeça", "Cansaço físico", "Agitação", "Sem sintomas"]
    let affectedAreas = MoodAffectedArea.allCases
    let energyLevels = MoodEnergyLevel.allCases
    let availableTimes = MoodAvailableTime.allCases
    let controlLevels = MoodControlLevel.allCases
    let sleepQualities = MoodSleepQuality.allCases
    
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
