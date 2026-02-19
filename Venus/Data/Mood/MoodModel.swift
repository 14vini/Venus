//
//  MoodModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

@Model
class MoodModel {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var note: String?
    var timestamp: Date
    
    init(mood: Mood) {
        self.id = mood.id
        self.typeRawValue = mood.type.rawValue
        self.note = mood.note
        self.timestamp = mood.timestamp
    }
    
    func toDomain() -> Mood? {
        guard let type = MoodType(rawValue: typeRawValue) else { return nil }
        return Mood(id: id, type: type, note: note, timestamp: timestamp)
    }
}
