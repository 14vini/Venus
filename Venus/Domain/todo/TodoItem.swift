//
//  TodoItem.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct TodoItem: Identifiable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date
    var time: Date?
    var type: TodoType
    var isSystemGenerated: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        date: Date,
        time: Date? = nil,
        type: TodoType = .task,
        isSystemGenerated: Bool = false
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.date = date
        self.time = time
        self.type = type
        self.isSystemGenerated = isSystemGenerated
    }
}

enum TodoType: String, Codable, CaseIterable {
    case task = "Tarefa"
    case work = "Trabalho"
    case study = "Estudo"
    case routine = "Rotina"
    case health = "Saúde"
    
    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .work: return "briefcase"
        case .study: return "book"
        case .routine: return "arrow.triangle.2.circlepath"
        case .health: return "heart"
        }
    }
}
