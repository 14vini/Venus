//
//  PlannedBlockModel.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation
import SwiftData

@Model
final class PlannedBlockModel {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRawValue: String
    var startTime: Date
    var endTime: Date
    var priorityRawValue: String
    var statusRawValue: String
    var note: String?
    var order: Int
    var plan: DailyPlanModel?
    
    init(block: PlannedBlock, plan: DailyPlanModel? = nil) {
        self.id = block.id
        self.title = block.title
        self.categoryRawValue = block.category.rawValue
        self.startTime = block.startTime
        self.endTime = block.endTime
        self.priorityRawValue = block.priority.rawValue
        self.statusRawValue = block.status.rawValue
        self.note = block.note
        self.order = block.order
        self.plan = plan
    }
    
    func toDomain() -> PlannedBlock {
        PlannedBlock(
            id: id,
            title: title,
            category: BlockCategory(rawValue: categoryRawValue) ?? .personal,
            startTime: startTime,
            endTime: endTime,
            priority: BlockPriority(rawValue: priorityRawValue) ?? .medium,
            status: BlockStatus(rawValue: statusRawValue) ?? .planned,
            note: note,
            order: order
        )
    }
}
