//
//  TodoModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

@Model
class TodoModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var isCompleted: Bool
    var date: Date
    var time: Date?
    var typeString: String
    var isSystemGenerated: Bool
    var createdAt: Date
    
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
        self.typeString = type.rawValue
        self.isSystemGenerated = isSystemGenerated
        self.createdAt = Date()
    }
    
    var type: TodoType {
        get { TodoType(rawValue: typeString) ?? .task }
        set { typeString = newValue.rawValue }
    }
    
    func toDomain() -> TodoItem {
        return TodoItem(
            id: id,
            title: title,
            isCompleted: isCompleted,
            date: date,
            time: time,
            type: type,
            isSystemGenerated: isSystemGenerated
        )
    }
    
    static func fromDomain(_ item: TodoItem) -> TodoModel {
        return TodoModel(
            id: item.id,
            title: item.title,
            isCompleted: item.isCompleted,
            date: item.date,
            time: item.time,
            type: item.type,
            isSystemGenerated: item.isSystemGenerated
        )
    }
}
