//
//  PlanningContext.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import Foundation

public struct FixedCommitment: Codable, Sendable, Equatable {
    public var title: String
    public var startTime: Date
    public var endTime: Date
    public var category: BlockCategory
    
    public init(
        title: String,
        startTime: Date,
        endTime: Date,
        category: BlockCategory = .work
    ) {
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.category = category
    }
}

public struct PlanningTimePreferences: Codable, Sendable, Equatable {
    public var preferredFocusDurationMinutes: Int
    public var minimumRestMinutes: Int
    public var wakeUpHour: Int
    public var sleepHour: Int
    
    public init(
        preferredFocusDurationMinutes: Int = 45,
        minimumRestMinutes: Int = 15,
        wakeUpHour: Int = 7,
        sleepHour: Int = 23
    ) {
        self.preferredFocusDurationMinutes = preferredFocusDurationMinutes
        self.minimumRestMinutes = minimumRestMinutes
        self.wakeUpHour = wakeUpHour
        self.sleepHour = sleepHour
    }
}

public struct PlanningContext: Codable, Sendable, Equatable {
    public var fixedCommitments: [FixedCommitment]
    public var preferences: PlanningTimePreferences
    public var minimumRestMinutes: Int
    public var preferredFocusDurationMinutes: Int
    public var userConstraints: [String]
    public var dailyTimeBudgetMinutes: Int
    public var readinessScore: Double?
    public var recentMoodTitle: String?
    
    public init(
        fixedCommitments: [FixedCommitment] = [],
        preferences: PlanningTimePreferences = PlanningTimePreferences(),
        minimumRestMinutes: Int = 15,
        preferredFocusDurationMinutes: Int = 45,
        userConstraints: [String] = [],
        dailyTimeBudgetMinutes: Int = 480,
        readinessScore: Double? = nil,
        recentMoodTitle: String? = nil
    ) {
        self.fixedCommitments = fixedCommitments
        self.preferences = preferences
        self.minimumRestMinutes = minimumRestMinutes
        self.preferredFocusDurationMinutes = preferredFocusDurationMinutes
        self.userConstraints = userConstraints
        self.dailyTimeBudgetMinutes = dailyTimeBudgetMinutes
        self.readinessScore = readinessScore
        self.recentMoodTitle = recentMoodTitle
    }
}
