//
//  MoodRepositoryImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

class MoodRepositoryImpl: MoodRepositoryProtocol {
    private let modelContext: ModelContext
    
    @MainActor
    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }
    
    @MainActor
    func save(mood: Mood) async throws {
        let model = MoodModel(mood: mood)
        modelContext.insert(model)
        try modelContext.save()
    }
    
    @MainActor
    func getTodayMood() async throws -> Mood? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<MoodModel>(
            predicate: #Predicate<MoodModel> {
                $0.timestamp >= startOfDay && $0.timestamp < endOfDay
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.first?.toDomain()
    }
    
    @MainActor
    func getAllMoods() async throws -> [Mood] {
        let descriptor = FetchDescriptor<MoodModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        let models = try modelContext.fetch(descriptor)
        return models.compactMap { $0.toDomain() }
    }
}
