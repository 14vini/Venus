//
//  TodoRepositoryImpl.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

class TodoRepositoryImpl: TodoRepositoryProtocol {
    private let modelContainer: ModelContainer
    private let context: ModelContext
    
    @MainActor
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.context = modelContainer.mainContext
    }
    
    func getTodos(for date: Date) async throws -> [TodoItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Predicate to filter by date range
        let predicate = #Predicate<TodoModel> { todo in
            todo.date >= startOfDay && todo.date < endOfDay
        }
        
        let descriptor = FetchDescriptor<TodoModel>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.time, order: .forward), SortDescriptor(\.createdAt, order: .forward)]
        )
        
        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }

    func getTodos(from startDate: Date, to endDate: Date) async throws -> [TodoItem] {
        let descriptor = FetchDescriptor<TodoModel>(
            predicate: #Predicate<TodoModel> { todo in
                todo.date >= startDate && todo.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward), SortDescriptor(\.time, order: .forward)]
        )

        let models = try context.fetch(descriptor)
        return models.map { $0.toDomain() }
    }
    
    func save(item: TodoItem) async throws {
        // Check if exists update, else insert
        let id = item.id
        let predicate = #Predicate<TodoModel> { $0.id == id }
        let descriptor = FetchDescriptor<TodoModel>(predicate: predicate)
        
        if let existing = try context.fetch(descriptor).first {
            existing.title = item.title
            existing.isCompleted = item.isCompleted
            existing.date = item.date
            existing.time = item.time
            existing.type = item.type
            existing.isSystemGenerated = item.isSystemGenerated
        } else {
            let newModel = TodoModel.fromDomain(item)
            context.insert(newModel)
        }
        
        try context.save()
    }
    
    func delete(id: UUID) async throws {
        let predicate = #Predicate<TodoModel> { $0.id == id }
        let descriptor = FetchDescriptor<TodoModel>(predicate: predicate)
        if let model = try context.fetch(descriptor).first {
            context.delete(model)
            try context.save()
        }
    }
    
    func toggleCompletion(id: UUID) async throws {
        let predicate = #Predicate<TodoModel> { $0.id == id }
        let descriptor = FetchDescriptor<TodoModel>(predicate: predicate)
        if let model = try context.fetch(descriptor).first {
            model.isCompleted.toggle()
            try context.save()
        }
    }
}
