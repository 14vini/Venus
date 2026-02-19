//
//  SaveMoodUseCase.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol SaveMoodUseCaseProtocol {
    func execute(type: MoodType, note: String?) async throws -> Mood
}

class SaveMoodUseCase: SaveMoodUseCaseProtocol {
    private let repository: MoodRepositoryProtocol
    
    init(repository: MoodRepositoryProtocol) {
        self.repository = repository
    }
    
    func execute(type: MoodType, note: String?) async throws -> Mood {
        let mood = Mood(type: type, note: note)
        try await repository.save(mood: mood)
        return mood
    }
}
