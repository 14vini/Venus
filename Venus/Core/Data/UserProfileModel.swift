//
//  UserProfileModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

@Model
class UserProfileModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var interests: [String]
    var primaryGoal: String = ""
    var coachingTone: String = ""
    var dailyTimeBudgetMinutes: Int = 0
    var currentHobbies: [String]
    var desiredHobbies: [String]
    var improvementAreas: [String]
    var emotionalAreas: [String]
    var isOnboardingComplete: Bool
    
    // Work Schedule (optional)
    var hasWork: Bool
    var workStartTime: Date?
    var workEndTime: Date?
    
    // Study Schedule
    var studies: Bool
    var studyStartTime: Date?
    var studyEndTime: Date?
    
    init(profile: UserProfile) {
        self.id = UUID()
        self.name = profile.name
        self.interests = profile.interests
        self.primaryGoal = profile.primaryGoal
        self.coachingTone = profile.coachingTone
        self.dailyTimeBudgetMinutes = profile.dailyTimeBudgetMinutes
        self.currentHobbies = profile.currentHobbies
        self.desiredHobbies = profile.desiredHobbies
        self.improvementAreas = profile.improvementAreas
        self.emotionalAreas = profile.emotionalAreas
        self.isOnboardingComplete = profile.isOnboardingComplete
        
        self.hasWork = profile.workSchedule?.hasWork ?? false
        self.workStartTime = profile.workSchedule?.startTime
        self.workEndTime = profile.workSchedule?.endTime
        
        self.studies = profile.studySchedule.studies
        self.studyStartTime = profile.studySchedule.startTime
        self.studyEndTime = profile.studySchedule.endTime
    }
    
    func toDomain() -> UserProfile {
        let profile = UserProfile()
        profile.name = name
        profile.interests = interests
        profile.primaryGoal = primaryGoal
        profile.coachingTone = coachingTone
        profile.dailyTimeBudgetMinutes = dailyTimeBudgetMinutes
        profile.currentHobbies = currentHobbies
        profile.desiredHobbies = desiredHobbies
        profile.improvementAreas = improvementAreas
        profile.emotionalAreas = emotionalAreas
        profile.isOnboardingComplete = isOnboardingComplete
        
        if hasWork, let start = workStartTime, let end = workEndTime {
            profile.workSchedule = WorkSchedule(hasWork: true, startTime: start, endTime: end)
        }
        
        profile.studySchedule = StudySchedule(
            studies: studies,
            startTime: studyStartTime ?? Date(),
            endTime: studyEndTime ?? Date()
        )
        
        return profile
    }
}
