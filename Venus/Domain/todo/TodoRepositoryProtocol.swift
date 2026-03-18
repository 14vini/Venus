//
//  TodoRepositoryProtocol.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol TodoRepositoryProtocol {
    func getTodos(for date: Date) async throws -> [TodoItem]
    func getTodos(from startDate: Date, to endDate: Date) async throws -> [TodoItem]
    func save(item: TodoItem) async throws
    func delete(id: UUID) async throws
    func toggleCompletion(id: UUID) async throws
}
