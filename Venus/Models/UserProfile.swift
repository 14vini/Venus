//
//  UserProfile.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

@Observable
class UserProfile {
    // Informações básicas
    var name: String = ""
    var interests: [String] = []
    
    // Rotina
    var workSchedule: WorkSchedule? = nil
    var studySchedule: StudySchedule = StudySchedule()
    
    // Hobbies
    var currentHobbies: [String] = []
    var desiredHobbies: [String] = []
    
    // Bem-estar
    var improvementAreas: [String] = []
    var emotionalAreas: [String] = []
    
    // Validação
    var isOnboardingComplete: Bool = false

    func reset() {
        name = ""
        interests = []
        workSchedule = nil
        studySchedule = StudySchedule()
        currentHobbies = []
        desiredHobbies = []
        improvementAreas = []
        emotionalAreas = []
        isOnboardingComplete = false
    }
}

struct WorkSchedule {
    var hasWork: Bool = false
    var startTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    var endTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
}

struct StudySchedule {
    var studies: Bool = false
    var startTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    var endTime: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
}
