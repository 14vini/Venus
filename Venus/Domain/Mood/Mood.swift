//
//  Mood.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct Mood: Identifiable, Equatable {
    let id: UUID
    let type: MoodType
    let note: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), type: MoodType, note: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.note = note
        self.timestamp = timestamp
    }
}

enum MoodType: String, CaseIterable, Codable {
    case calm = "Calmo"
    case happy = "Feliz"
    case energetic = "Energizado"
    case stressed = "Estressado"
    case sad = "Triste"
    case tired = "Cansado"
    
    var emoji: String {
        switch self {
        case .calm: return "😌"
        case .happy: return "😊"
        case .energetic: return "⚡️"
        case .stressed: return "😫"
        case .sad: return "😢"
        case .tired: return "😴"
        }
    }
    
    var colorHex: String {
        switch self {
        case .calm: return "#A78BFA" // Purple
        case .happy: return "#F472B6" // Pink
        case .energetic: return "#FBBF24" // Yellow
        case .stressed: return "#F87171" // Red
        case .sad: return "#60A5FA" // Blue
        case .tired: return "#9CA3AF" // Grey
        }
    }
}
