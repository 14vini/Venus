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
    let intensity: Int?
    let triggers: [String]
    let affectedArea: MoodAffectedArea?
    let energyLevel: MoodEnergyLevel?
    let availableTime: MoodAvailableTime?
    let controlLevel: MoodControlLevel?
    let mentalClarity: Int?
    let sleepQuality: MoodSleepQuality?
    let bodySignals: [String]
    let note: String?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        type: MoodType,
        intensity: Int? = nil,
        triggers: [String] = [],
        affectedArea: MoodAffectedArea? = nil,
        energyLevel: MoodEnergyLevel? = nil,
        availableTime: MoodAvailableTime? = nil,
        controlLevel: MoodControlLevel? = nil,
        mentalClarity: Int? = nil,
        sleepQuality: MoodSleepQuality? = nil,
        bodySignals: [String] = [],
        note: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.intensity = intensity
        self.triggers = triggers
        self.affectedArea = affectedArea
        self.energyLevel = energyLevel
        self.availableTime = availableTime
        self.controlLevel = controlLevel
        self.mentalClarity = mentalClarity
        self.sleepQuality = sleepQuality
        self.bodySignals = bodySignals
        self.note = note
        self.timestamp = timestamp
    }
}

enum MoodAffectedArea: String, CaseIterable, Codable {
    case work = "Trabalho"
    case relationship = "Relacionamento"
    case health = "Saúde"
    case discipline = "Disciplina"
    case finances = "Finanças"
    case studies = "Estudos"
    case social = "Social"
    case family = "Família"
    case personal = "Pessoal"
}

enum MoodEnergyLevel: String, CaseIterable, Codable {
    case low = "Baixa"
    case medium = "Média"
    case high = "Alta"
}

enum MoodAvailableTime: String, CaseIterable, Codable {
    case fiveMinutes = "5 min"
    case tenMinutes = "10 min"
    case twentyPlusMinutes = "20+ min"

    var maxMinutes: Int {
        switch self {
        case .fiveMinutes:
            return 5
        case .tenMinutes:
            return 10
        case .twentyPlusMinutes:
            return 30
        }
    }
}

enum MoodControlLevel: String, CaseIterable, Codable {
    case low = "Baixo"
    case medium = "Médio"
    case high = "Alto"
}

enum MoodSleepQuality: String, CaseIterable, Codable {
    case poor = "Ruim"
    case fair = "Regular"
    case good = "Boa"
    case excellent = "Excelente"

    var score: Int {
        switch self {
        case .poor:
            return 1
        case .fair:
            return 2
        case .good:
            return 3
        case .excellent:
            return 4
        }
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
        case .calm: return "#8FD8FF"
        case .happy: return "#82DEC9"
        case .energetic: return "#5DBBFF"
        case .stressed: return "#69B8D8"
        case .sad: return "#A7D4FF"
        case .tired: return "#BBD4C8"
        }
    }

    /// Orb gradient colors: [light highlight, mid, deep]
    var orbColors: (light: String, mid: String, deep: String) {
        switch self {
        case .happy:    return ("D6FFB9", "9BF66F", "59D85A")  // green
        case .calm:     return ("B9EEFF", "6DCFF5", "3AAED8")  // sky blue
        case .energetic:return ("FFFAB9", "FFE44A", "F5C800")  // yellow
        case .stressed: return ("FFD4B9", "FF9A6C", "E06030")  // orange-red
        case .sad:      return ("C4D4FF", "7FA8F5", "4A72D8")  // blue
        case .tired:    return ("E0D4FF", "B89AF5", "8A60D8")  // purple
        }
    }

    /// Face ink color (dark enough to read on the orb)
    var faceColorHex: String {
        switch self {
        case .happy:    return "27603F"
        case .calm:     return "1A5070"
        case .energetic:return "7A5800"
        case .stressed: return "7A2800"
        case .sad:      return "1A3070"
        case .tired:    return "3A1A70"
        }
    }
}
