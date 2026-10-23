//
//  Mood.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

struct Mood: Identifiable, Equatable, Sendable {
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

enum MoodAffectedArea: String, CaseIterable, Codable, Sendable {
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

enum MoodEnergyLevel: String, CaseIterable, Codable, Sendable {
    case low = "Baixa"
    case medium = "Média"
    case high = "Alta"

    var displayName: String {
        switch self {
        case .low: return "Crítica / Baixa"
        case .medium: return "Regular / Estável"
        case .high: return "Alta / Disposta"
        }
    }

    var supportCopy: String {
        switch self {
        case .low: return "Pouca bateria mental, preciso de leveza"
        case .medium: return "Consigo focar no que é essencial"
        case .high: return "Pronto para desafios e ação"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.75"
        case .high: return "battery.100"
        }
    }
}

enum MoodAvailableTime: String, CaseIterable, Codable, Sendable {
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

enum MoodControlLevel: String, CaseIterable, Codable, Sendable {
    case low = "Baixo"
    case medium = "Médio"
    case high = "Alto"
}

enum MoodSleepQuality: String, CaseIterable, Codable, Sendable {
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

enum MoodType: String, CaseIterable, Codable, Sendable {
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
        case .calm: return "#0077B6"
        case .happy: return "#00B4D8"
        case .energetic: return "#0096C7"
        case .stressed: return "#023E8A"
        case .sad: return "#03045E"
        case .tired: return "#48CAE4"
        }
    }

    /// Orb gradient colors: [light highlight, mid, deep]
    var orbColors: (light: String, mid: String, deep: String) {
        switch self {
        case .happy:    return ("90E0EF", "00B4D8", "0077B6")
        case .calm:     return ("ADE8F4", "48CAE4", "0096C7")
        case .energetic:return ("CAF0F8", "00B4D8", "023E8A")
        case .stressed: return ("48CAE4", "0077B6", "023E8A")
        case .sad:      return ("90E0EF", "023E8A", "03045E")
        case .tired:    return ("ADE8F4", "48CAE4", "023E8A")
        }
    }

    /// Face ink color
    var faceColorHex: String {
        switch self {
        case .happy:    return "03045E"
        case .calm:     return "023E8A"
        case .energetic:return "03045E"
        case .stressed: return "03045E"
        case .sad:      return "03045E"
        case .tired:    return "023E8A"
        }
    }
}
