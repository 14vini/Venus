//
//  UserProfileRepositoryImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

class UserProfileRepositoryImpl: UserProfileRepositoryProtocol {
    private let modelContext: ModelContext
    
    @MainActor
    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }
    
    @MainActor
    func save(profile: UserProfile) async throws {
        // Delete existing profile first
        try await delete()
        
        // Insert new profile
        let model = UserProfileModel(profile: profile)
        modelContext.insert(model)
        try modelContext.save()
    }
    
    @MainActor
    func load() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfileModel>()
        let models = try modelContext.fetch(descriptor)
        return models.first?.toDomain()
    }
    
    @MainActor
    func delete() async throws {
        let descriptor = FetchDescriptor<UserProfileModel>()
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
}
