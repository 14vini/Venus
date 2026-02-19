//
//  Activity.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct Activity: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let category: ActivityCategory
    let durationMinutes: Int
    let iconName: String
    let steps: [String]?
    let audioUrl: String?
    let targetEmotions: [MoodType]?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: ActivityCategory,
        durationMinutes: Int,
        iconName: String,
        steps: [String]? = nil,
        audioUrl: String? = nil,
        targetEmotions: [MoodType]? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.durationMinutes = durationMinutes
        self.iconName = iconName
        self.steps = steps
        self.audioUrl = audioUrl
        self.targetEmotions = targetEmotions
    }
}

enum ActivityCategory: String, CaseIterable {
    case relaxation = "Relaxamento"
    case focus = "Foco"
    case creativity = "Criatividade"
    case physical = "Físico"
    case social = "Social"
}
