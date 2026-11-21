//
//  DailyPlanModel.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation
import SwiftData

@Model
final class DailyPlanModel {
    @Attribute(.unique) var id: UUID
    var date: Date
    var stateRawValue: String
    var summary: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PlannedBlockModel.plan)
    var blocks: [PlannedBlockModel] = []
    
    init(plan: DailyPlan) {
        self.id = plan.id
        self.date = plan.date
        self.stateRawValue = plan.state.rawValue
        self.summary = plan.summary
        self.createdAt = plan.createdAt
        self.updatedAt = plan.updatedAt
        self.blocks = plan.blocks.map { PlannedBlockModel(block: $0) }
    }
    
    func toDomain() -> DailyPlan {
        let converted: [PlannedBlock] = blocks.map { $0.toDomain() }
        let sortedBlocks = converted.sorted { (lhs: PlannedBlock, rhs: PlannedBlock) -> Bool in
            if lhs.order != rhs.order {
                return lhs.order < rhs.order
            }
            return lhs.startTime < rhs.startTime
        }
        
        let state = DailyPlanState(rawValue: stateRawValue) ?? .active
        return DailyPlan(
            id: id,
            date: date,
            state: state,
            summary: summary,
            blocks: sortedBlocks,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
