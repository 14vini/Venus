//
//  PlannedBlock.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation
import SwiftUI

public enum BlockCategory: String, Codable, CaseIterable, Sendable {
    case study
    case work
    case habit
    case health
    case personal
    case rest
    
    public var displayName: String {
        switch self {
        case .study: return "Estudos"
        case .work: return "Trabalho"
        case .habit: return "Hábito"
        case .health: return "Saúde"
        case .personal: return "Pessoal"
        case .rest: return "Descanso"
        }
    }
    
    public var iconName: String {
        switch self {
        case .study: return "book.fill"
        case .work: return "briefcase.fill"
        case .habit: return "sparkles"
        case .health: return "heart.fill"
        case .personal: return "person.fill"
        case .rest: return "cup.and.saucer.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .study: return Color(hex: "818CF8") // Indigo suave
        case .work: return Color(hex: "60A5FA")  // Azul claro
        case .habit: return Color(hex: "F472B6") // Rosa suave
        case .health: return Color(hex: "34D399")// Verde menta
        case .personal: return Color(hex: "FBBF24") // Âmbar acolhedor
        case .rest: return Color(hex: "A78BFA") // Roxo lavanda
        }
    }
}

public enum BlockPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    
    public var displayName: String {
        switch self {
        case .low: return "Baixa"
        case .medium: return "Média"
        case .high: return "Alta"
        }
    }
}

public enum BlockStatus: String, Codable, CaseIterable, Sendable {
    case planned
    case inProgress
    case completed
    case skipped
    
    public var displayName: String {
        switch self {
        case .planned: return "Planejado"
        case .inProgress: return "Em andamento"
        case .completed: return "Concluído"
        case .skipped: return "Pulado"
        }
    }
    
    public var iconName: String {
        switch self {
        case .planned: return "circle"
        case .inProgress: return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.circle.fill"
        }
    }
}

public struct PlannedBlock: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var title: String
    public var category: BlockCategory
    public var startTime: Date
    public var endTime: Date
    public var priority: BlockPriority
    public var status: BlockStatus
    public var note: String?
    public var order: Int
    
    public init(
        id: UUID = UUID(),
        title: String,
        category: BlockCategory,
        startTime: Date,
        endTime: Date,
        priority: BlockPriority = .medium,
        status: BlockStatus = .planned,
        note: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.status = status
        self.note = note
        self.order = order
    }
    
    public var durationMinutes: Int {
        max(0, Int(endTime.timeIntervalSince(startTime) / 60))
    }
    
    public var formattedTimeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
