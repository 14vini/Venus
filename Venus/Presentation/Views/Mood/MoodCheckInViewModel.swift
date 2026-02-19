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
    @Published var isSaving: Bool = false
    @Published var savedSuccess: Bool = false
    
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
    
    func saveCheckIn() {
        guard let mood = selectedMood else { return }
        
        isSaving = true
        
        Task {
            do {
                _ = try await saveMoodUseCase.execute(type: mood, note: note.isEmpty ? nil : note)
                isSaving = false
                savedSuccess = true
            } catch {
                print("Error saving mood: \(error)")
                isSaving = false
            }
        }
    }
}
