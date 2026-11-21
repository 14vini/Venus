//
//  PlanningResponse.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation

public enum PlanningIntent: String, Codable, Sendable {
    case createPlan
    case updatePlan
    case completeBlock
    case generalChat
}

public struct AIProposedBlock: Codable, Sendable, Equatable {
    public var id: String?
    public var title: String
    public var category: String // "study", "work", "habit", "health", "personal", "rest"
    public var startTime: String // "14:00" or ISO8601
    public var endTime: String   // "15:30" or ISO8601
    public var priority: String? // "high", "medium", "low"
    public var note: String?
    
    public init(
        id: String? = nil,
        title: String,
        category: String,
        startTime: String,
        endTime: String,
        priority: String? = "medium",
        note: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.priority = priority
        self.note = note
    }
}

public struct AIPlanningResponse: Codable, Sendable, Equatable {
    public var message: String
    public var intent: PlanningIntent
    public var proposedBlocks: [AIProposedBlock]
    public var reasoningSummary: String?
    public var questions: [String]?
    public var requiresConfirmation: Bool
    
    public init(
        message: String,
        intent: PlanningIntent,
        proposedBlocks: [AIProposedBlock] = [],
        reasoningSummary: String? = nil,
        questions: [String]? = nil,
        requiresConfirmation: Bool = true
    ) {
        self.message = message
        self.intent = intent
        self.proposedBlocks = proposedBlocks
        self.reasoningSummary = reasoningSummary
        self.questions = questions
        self.requiresConfirmation = requiresConfirmation
    }
}
