//
//  HomeViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

class HomeViewModel: ObservableObject {
    @Published var hasCheckedInToday: Bool = false
    @Published var showMoodCheckIn: Bool = false
    @Published var dailyRecommendation: Recommendation?
    @Published var isLoadingRecommendation: Bool = false
    
    private let smartRecommendationUseCase: SmartRecommendationUseCaseProtocol
    private let profileRepository: UserProfileRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    
    init(
        smartRecommendationUseCase: SmartRecommendationUseCaseProtocol,
        profileRepository: UserProfileRepositoryProtocol,
        moodRepository: MoodRepositoryProtocol
    ) {
        self.smartRecommendationUseCase = smartRecommendationUseCase
        self.profileRepository = profileRepository
        self.moodRepository = moodRepository
        
        Task {
            await checkIfCheckedIn()
        }
    }
    
    func checkInButtonTapped() {
        showMoodCheckIn = true
    }
    
    @MainActor
    func handleMoodCheckInCompleted(mood: MoodType) {
        hasCheckedInToday = true
        showMoodCheckIn = false
        generateDailyRecommendation(for: mood)
    }
    
    @MainActor
    private func checkIfCheckedIn() async {
        do {
            if let todayMood = try await moodRepository.getTodayMood() {
                hasCheckedInToday = true
                generateDailyRecommendation(for: todayMood.type)
            }
        } catch {
            print("Error checking mood: \(error)")
        }
    }
    
    @MainActor
    private func generateDailyRecommendation(for mood: MoodType) {
        isLoadingRecommendation = true
        
        Task {
            do {
                if let profile = try await profileRepository.load() {
                    let recommendation = await smartRecommendationUseCase.execute(
                        mood: mood,
                        userProfile: profile,
                        currentTime: Date()
                    )
                    
                    withAnimation {
                        self.dailyRecommendation = recommendation
                        self.isLoadingRecommendation = false
                    }
                }
            } catch {
                print("Error loading profile for recommendation: \(error)")
                self.isLoadingRecommendation = false
            }
        }
    }
}
