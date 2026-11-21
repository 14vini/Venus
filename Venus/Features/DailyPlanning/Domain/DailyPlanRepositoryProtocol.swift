//
//  DailyPlanRepositoryProtocol.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation

@MainActor
public protocol DailyPlanRepositoryProtocol: Sendable {
    func getPlan(for date: Date) async throws -> DailyPlan?
    func save(plan: DailyPlan) async throws
    func updateBlockStatus(planId: UUID, blockId: UUID, status: BlockStatus) async throws
    func deletePlan(id: UUID) async throws
}
