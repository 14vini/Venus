//
//  UserProfile.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

@Observable
class UserProfile: Sendable {
    // Informações básicas
    var name: String = ""
    var interests: [String] = []

    // Preferências (calibração da Venus)
    var primaryGoal: String = ""
    var coachingTone: String = ""
    var dailyTimeBudgetMinutes: Int = 0
    
    // Rotina
    var workSchedule: WorkSchedule? = nil
    var studySchedule: StudySchedule = StudySchedule()
    
    // Hobbies
    var currentHobbies: [String] = []
    var desiredHobbies: [String] = []
    
    // Bem-estar & Contexto Inicial
    var improvementAreas: [String] = []
    var emotionalAreas: [String] = []
    var contextNote: String = ""
    
    // Validação
    var isOnboardingComplete: Bool = false

    func reset() {
        name = ""
        interests = []
        primaryGoal = ""
        coachingTone = ""
        dailyTimeBudgetMinutes = 0
        workSchedule = nil
        studySchedule = StudySchedule()
        currentHobbies = []
        desiredHobbies = []
        improvementAreas = []
        emotionalAreas = []
        contextNote = ""
        isOnboardingComplete = false
    }
}

struct WorkSchedule: Sendable, Codable, Equatable {
    var hasWork: Bool = false
    var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
}

struct StudySchedule: Sendable, Codable, Equatable {
    var studies: Bool = false
    var startTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    var endTime: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
}
