//
//  SaveMoodUseCase.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol SaveMoodUseCaseProtocol {
    func execute(
        type: MoodType,
        intensity: Int?,
        triggers: [String],
        affectedArea: MoodAffectedArea?,
        energyLevel: MoodEnergyLevel?,
        availableTime: MoodAvailableTime?,
        controlLevel: MoodControlLevel?,
        mentalClarity: Int?,
        sleepQuality: MoodSleepQuality?,
        bodySignals: [String],
        note: String?
    ) async throws -> Mood
}

class SaveMoodUseCase: SaveMoodUseCaseProtocol {
    private let repository: MoodRepositoryProtocol
    
    init(repository: MoodRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(
        type: MoodType,
        intensity: Int?,
        triggers: [String],
        affectedArea: MoodAffectedArea?,
        energyLevel: MoodEnergyLevel?,
        availableTime: MoodAvailableTime?,
        controlLevel: MoodControlLevel?,
        mentalClarity: Int?,
        sleepQuality: MoodSleepQuality?,
        bodySignals: [String],
        note: String?
    ) async throws -> Mood {
        let mood = Mood(
            type: type,
            intensity: intensity,
            triggers: triggers,
            affectedArea: affectedArea,
            energyLevel: energyLevel,
            availableTime: availableTime,
            controlLevel: controlLevel,
            mentalClarity: mentalClarity,
            sleepQuality: sleepQuality,
            bodySignals: bodySignals,
            note: note
        )
        try await repository.save(mood: mood)
        return mood
    }
}
