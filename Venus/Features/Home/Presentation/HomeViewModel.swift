//
//  HomeViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

@Observable
@MainActor
final class HomeViewModel {
    var userProfile: UserProfile?
    var showVenusChat: Bool = false
    var showChatHistory: Bool = false
    var showVenusProPlans: Bool = false
    var selectedChatSession: ChatSession? = nil
    var showMoodCheckIn: Bool = false
    var showUpgradePrompt: Bool = false
    var checkInPrefilledMood: MoodType? = nil

    var hasCheckedInToday: Bool = false
    var todayMoodType: MoodType?
    var checkInsUsedToday: Int = 0
    var checkInStreakDays: Int = 0
    var weekMoods: [Mood] = []
    var checkInAllowance: CheckInAllowance = .freeDefault

    var weeklyTrend: WeeklyEmotionalTrend?
    var patternAlert: PatternAlert?
    var weeklyInsights: WeeklyStrategicInsights?
    var proMoodForecast: ProMoodForecast?
    var isLoadingInsights: Bool = false
    var insightsErrorMessage: String?

    var freePlanDailyLimit: Int { CheckInAllowance.defaultFreeDailyLimit }
    var dayMoment: DayMoment { .current }

    var ritualProgressLabel: String {
        let nextIndex = checkInAllowance.usedToday + 1
        if checkInAllowance.isUnlimited {
            return "Ritual \(nextIndex)/∞"
        }
        let limit = checkInAllowance.dailyLimit ?? freePlanDailyLimit
        return "Ritual \(min(nextIndex, limit))/\(limit)"
    }

    private let patternEngineUseCase: PatternEngineUseCaseProtocol
    private let checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol
    private let moodRepository: MoodRepositoryProtocol

    private var insightsTask: Task<Void, Never>?
    private var insightsRequestID = UUID()

    init(
        patternEngineUseCase: PatternEngineUseCaseProtocol? = nil,
        checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil
    ) {
        self.patternEngineUseCase = patternEngineUseCase ?? DependencyContainer.shared.makePatternEngineUseCase()
        self.checkInAllowanceUseCase = checkInAllowanceUseCase ?? DependencyContainer.shared.makeCheckInAllowanceUseCase()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()

        Task {
            await refreshMoodStatus()
        }
    }

    func configure(userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    func onAppear() {
        Task {
            await refreshMoodStatus()
        }
    }

    func checkInButtonTapped() {
        if checkInAllowance.canCheckIn {
            showMoodCheckIn = true
        } else {
            showUpgradePrompt = true
        }
    }

    func handleMoodCheckInCompleted(mood: MoodType) {
        hasCheckedInToday = true
        todayMoodType = mood
        showMoodCheckIn = false

        Task {
            await refreshMoodStatus()
        }
    }

    func retryInsights() {
        Task {
            await refreshPatternInsights()
        }
    }

    func handleCheckInAction() {
        guard checkInAllowance.canCheckIn else {
            showUpgradePrompt = true
            return
        }
        checkInPrefilledMood = nil
        showMoodCheckIn = true
    }

    func refreshMoodStatus() async {
        insightsErrorMessage = nil

        do {
            let usedToday = try await moodRepository.getMoodCount(on: Date())
            checkInsUsedToday = usedToday
            checkInAllowance = await checkInAllowanceUseCase.execute(usedToday: usedToday)
            hasCheckedInToday = usedToday > 0

            if let todayMood = try await moodRepository.getTodayMood() {
                todayMoodType = todayMood.type
            } else {
                hasCheckedInToday = false
                todayMoodType = nil
            }

            let streakStartDate = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
            let moods = try await moodRepository.getMoods(from: streakStartDate, to: Date())
            checkInStreakDays = calculateCheckInStreak(from: moods)
            
            let weekStartDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            weekMoods = moods.filter { $0.timestamp >= weekStartDate }
            
            await refreshPatternInsights()
        } catch {
            insightsTask?.cancel()
            insightsTask = nil
            isLoadingInsights = false
            insightsErrorMessage = "Não foi possível atualizar seu status agora."
            print("Error checking mood: \(error)")
        }
    }

    private func refreshPatternInsights() async {
        insightsTask?.cancel()
        let requestID = UUID()
        insightsRequestID = requestID
        insightsErrorMessage = nil
        isLoadingInsights = true

        insightsTask = Task { [weak self] in
            guard let self else { return }

            do {
                let snapshot = try await self.patternEngineUseCase.execute(referenceDate: Date()) { [weak self] mergedSnapshot in
                    guard let self = self else { return }
                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.weeklyTrend = mergedSnapshot.weeklyTrend
                            self.patternAlert = mergedSnapshot.patternAlert
                            self.weeklyInsights = mergedSnapshot.weeklyInsights
                            self.proMoodForecast = mergedSnapshot.proMoodForecast
                        }
                    }
                }
                
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }

                withAnimation {
                    self.weeklyTrend = snapshot?.weeklyTrend
                    self.patternAlert = snapshot?.patternAlert
                    self.weeklyInsights = snapshot?.weeklyInsights
                    self.proMoodForecast = snapshot?.proMoodForecast
                    self.isLoadingInsights = false
                    self.insightsErrorMessage = nil
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
                self.weeklyInsights = nil
                self.proMoodForecast = nil
                self.isLoadingInsights = false
                self.insightsErrorMessage = "Não consegui analisar seus padrões agora."
                print("Error generating pattern insights: \(error)")
            }
        }
    }

    private func calculateCheckInStreak(from moods: [Mood]) -> Int {
        guard !moods.isEmpty else { return 0 }

        let calendar = Calendar.current
        let uniqueDays = Set(moods.map { calendar.startOfDay(for: $0.timestamp) })
        var streak = 0

        for offset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { break }
            let day = calendar.startOfDay(for: date)

            if uniqueDays.contains(day) {
                streak += 1
            } else if offset > 0 {
                break
            }
        }

        return streak
    }
}
