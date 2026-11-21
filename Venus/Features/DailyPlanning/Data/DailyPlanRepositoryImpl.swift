//
//  DailyPlanRepositoryImpl.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation
import SwiftData

@MainActor
final class DailyPlanRepositoryImpl: DailyPlanRepositoryProtocol {
    private let modelContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContext = modelContainer.mainContext
    }
    
    func getPlan(for date: Date) async throws -> DailyPlan? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }
        
        let descriptor = FetchDescriptor<DailyPlanModel>(
            predicate: #Predicate<DailyPlanModel> {
                $0.date >= startOfDay && $0.date < endOfDay
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.first?.toDomain()
    }
    
    func save(plan: DailyPlan) async throws {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: plan.date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? plan.date
        let targetId = plan.id
        
        // Check for existing plan with same id or on the same day
        let descriptor = FetchDescriptor<DailyPlanModel>(
            predicate: #Predicate<DailyPlanModel> {
                $0.id == targetId || ($0.date >= startOfDay && $0.date < endOfDay)
            }
        )
        
        let existingModels = try modelContext.fetch(descriptor)
        
        if let existing = existingModels.first {
            existing.stateRawValue = plan.state.rawValue
            existing.summary = plan.summary
            existing.updatedAt = Date()
            
            // Delete old blocks and replace with new ones
            for oldBlock in existing.blocks {
                modelContext.delete(oldBlock)
            }
            existing.blocks = plan.blocks.map { PlannedBlockModel(block: $0, plan: existing) }
        } else {
            let newModel = DailyPlanModel(plan: plan)
            modelContext.insert(newModel)
        }
        
        try modelContext.save()
    }
    
    func updateBlockStatus(planId: UUID, blockId: UUID, status: BlockStatus) async throws {
        let descriptor = FetchDescriptor<DailyPlanModel>(
            predicate: #Predicate<DailyPlanModel> {
                $0.id == planId
            }
        )
        
        guard let planModel = try modelContext.fetch(descriptor).first else { return }
        
        if let block = planModel.blocks.first(where: { $0.id == blockId }) {
            block.statusRawValue = status.rawValue
            planModel.updatedAt = Date()
            
            // If all blocks are completed, mark plan as completed
            let allCompleted = planModel.blocks.allSatisfy { $0.statusRawValue == BlockStatus.completed.rawValue || $0.statusRawValue == BlockStatus.skipped.rawValue }
            if allCompleted && !planModel.blocks.isEmpty {
                planModel.stateRawValue = DailyPlanState.completed.rawValue
            } else if planModel.stateRawValue == DailyPlanState.completed.rawValue {
                planModel.stateRawValue = DailyPlanState.active.rawValue
            }
            
            try modelContext.save()
        }
    }
    
    func deletePlan(id: UUID) async throws {
        let descriptor = FetchDescriptor<DailyPlanModel>(
            predicate: #Predicate<DailyPlanModel> {
                $0.id == id
            }
        )
        
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
}
