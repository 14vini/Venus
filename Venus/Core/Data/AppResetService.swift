//
//  AppResetService.swift
//  Venus
//

import Foundation
import SwiftData

@MainActor
struct AppResetService {
    private let context: ModelContext

    init(modelContainer: ModelContainer = DependencyContainer.shared.modelContainer) {
        self.context = modelContainer.mainContext
    }

    func resetAllLocalData() throws {
        try deleteUserProfile()
        try deleteMoods()
        try deleteTodos()
    }

    private func deleteUserProfile() throws {
        let models = try context.fetch(FetchDescriptor<UserProfileModel>())
        for model in models {
            context.delete(model)
        }
        try context.save()
    }

    private func deleteMoods() throws {
        let models = try context.fetch(FetchDescriptor<MoodModel>())
        for model in models {
            context.delete(model)
        }
        try context.save()
    }

    private func deleteTodos() throws {
        let models = try context.fetch(FetchDescriptor<TodoModel>())
        for model in models {
            context.delete(model)
        }
        try context.save()
    }
}
