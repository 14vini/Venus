//
//  DailyPlan.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation

public enum DailyPlanState: String, Codable, CaseIterable, Sendable {
    case draft
    case active
    case completed
    case cancelled
    
    public var displayName: String {
        switch self {
        case .draft: return "Rascunho"
        case .active: return "Ativo"
        case .completed: return "Concluído"
        case .cancelled: return "Cancelado"
        }
    }
}

public struct DailyPlan: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var date: Date
    public var state: DailyPlanState
    public var summary: String
    public var blocks: [PlannedBlock]
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        state: DailyPlanState = .active,
        summary: String = "",
        blocks: [PlannedBlock] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.state = state
        self.summary = summary
        self.blocks = blocks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var completedBlocksCount: Int {
        blocks.filter { $0.status == .completed }.count
    }
    
    public var totalBlocksCount: Int {
        blocks.count
    }
    
    public var progressRatio: Double {
        guard totalBlocksCount > 0 else { return 0 }
        return Double(completedBlocksCount) / Double(totalBlocksCount)
    }
    
    public var topPriorities: [PlannedBlock] {
        let activeBlocks = blocks.filter { $0.status != .skipped }
        let high = activeBlocks.filter { $0.priority == .high }
        if high.count >= 3 {
            return Array(high.prefix(3))
        }
        let remaining = activeBlocks.filter { $0.priority != .high }
        return Array((high + remaining).prefix(3))
    }
}
