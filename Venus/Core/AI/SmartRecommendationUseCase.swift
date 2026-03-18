//
//  SmartRecommendationUseCase.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

protocol SmartRecommendationUseCaseProtocol {
    func execute(mood: MoodType, userProfile: UserProfile, currentTime: Date) async -> Recommendation?
}

class SmartRecommendationUseCase: SmartRecommendationUseCaseProtocol {
    private let activityRepository: ActivityRepositoryProtocol
    private let calendar: Calendar = .current
    
    init(activityRepository: ActivityRepositoryProtocol) {
        self.activityRepository = activityRepository
    }
    
    func execute(mood: MoodType, userProfile: UserProfile, currentTime: Date) async -> Recommendation? {
        let allActivities = await activityRepository.getActivities()
        
        // 1. Matchmaker (Energy Filter)
        let targetCategory = determineCategory(for: mood)
        var candidates = allActivities.filter { $0.category == targetCategory }
        
        // Fallback: If no match, pick relaxation
        if candidates.isEmpty {
            candidates = allActivities.filter { $0.category == .relaxation }
        }
        
        // 2. Agenda Manager (Availability Check)
        let availableMinutes = calculateAvailableTime(userProfile: userProfile, currentTime: currentTime)
        candidates = candidates.filter { $0.durationMinutes <= availableMinutes }
        
        // 3. Context Awareness (Time of Day)
        // Morning (6-11): Prefer Physical/Focus if compatible
        // Night (20-00): Stick to Relaxation/Creativity
        let hour = calendar.component(.hour, from: currentTime)
        
        if hour >= 20 {
            // Late night: prefer very short or relaxation
            candidates = candidates.filter { $0.category == .relaxation || $0.category == .creativity }
        } else if hour < 11 && (targetCategory == .physical || targetCategory == .focus) {
            // Morning boost: Keep these candidates
        }
        
        // Make sure we have something
        guard let finalActivity = candidates.randomElement() else {
             // Ultimate fallback: 4-7-8 Breathing (Short, works anytime)
             return allActivities.first(where: { $0.title.contains("4-7-8") })
                .map { Recommendation(activity: $0, suggestedTime: currentTime, reason: "Reset rápido para o seu momento.") }
        }
        
        let reason = generateReason(mood: mood, activity: finalActivity)
        
        return Recommendation(activity: finalActivity, suggestedTime: currentTime, reason: reason)
    }
    
    // MARK: - Helper Logic
    
    private func determineCategory(for mood: MoodType) -> ActivityCategory {
        switch mood {
        case .stressed, .calm:
            return .relaxation // Anxious/Stressed needs calm
        case .sad:
            return .creativity // Comfort, maybe music or art
        case .tired:
            return .relaxation // Rest
        case .energetic, .happy:
            return .physical // Burn energy
        }
    }
    
    private func calculateAvailableTime(userProfile: UserProfile, currentTime: Date) -> Int {
        // Simple logic: check next block of Work or Study
        var nextBlockStart: Date? = nil
        
        // Check Work
        if let workStart = userProfile.workSchedule?.startTime,
           userProfile.workSchedule?.hasWork == true,
           workStart > currentTime {
             // If work starts today later
            if calendar.isDate(workStart, inSameDayAs: currentTime) {
                nextBlockStart = workStart
            }
        }
        
        // Check Study
        let studyStart = userProfile.studySchedule.startTime
        if userProfile.studySchedule.studies, studyStart > currentTime {
             if calendar.isDate(studyStart, inSameDayAs: currentTime) {
                if let next = nextBlockStart {
                    // Pick the earliest one
                   nextBlockStart = min(next, studyStart)
                } else {
                    nextBlockStart = studyStart
                }
             }
        }
        
        guard let limit = nextBlockStart else {
            return 60 // No immediate block? Assume 1 hour free
        }
        
        let diff = calendar.dateComponents([.minute], from: currentTime, to: limit).minute ?? 0
        return max(5, diff) // At least 5 mins
    }
    
    private func generateReason(mood: MoodType, activity: Activity) -> String {
        switch mood {
        case .stressed:
            return "Para acalmar sua mente e reduzir a ansiedade."
        case .sad:
            return "Um pouco de conforto e criatividade para você."
        case .tired:
            return "Algo leve para descansar sem parar completamente."
        case .energetic:
            return "Aproveite sua energia para se movimentar!"
        case .happy:
            return "Mantenha essa vibração positiva!"
        case .calm:
            return "Continue nesse fluxo de tranquilidade."
        }
    }
}
