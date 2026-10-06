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
    var showEmotionalGalaxy: Bool = false
    var showVenusWrap: Bool = false
    var showReadinessBreakdown: Bool = false
    var checkInPrefilledMood: MoodType? = nil

    var hasCheckedInToday: Bool = false
    var todayMoodType: MoodType?
    var checkInsUsedToday: Int = 0
    var checkInStreakDays: Int = 0
    var weekMoods: [Mood] = []
    var checkInAllowance: CheckInAllowance = .freeDefault

    var weeklyTrend: WeeklyEmotionalTrend?
    var patternSnapshot: PatternInsightsSnapshot?
    var readinessAssessment: ReadinessEnergyAssessment = .sampleDefault
    var readinessHistory: [Double] = []
    var isLoadingInsights: Bool = false
    var insightsErrorMessage: String?
    var aiGreeting: String? = nil
    var lastRefreshAt: Date? = nil

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
    private let chatRepository: ChatRepositoryProtocol
    private let venusAI: VenusAIServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let readinessEngine: ReadinessEngineProtocol

    private var insightsTask: Task<Void, Never>?
    private var biometricObserverTask: Task<Void, Never>?
    private var biometricDebounceTask: Task<Void, Never>?
    private var microCopyTask: Task<Void, Never>?
    private var insightsRequestID = UUID()
    private var microCopyRequestID = UUID()
    private var lastGreetingDate: Date?
    private let notificationService: NotificationServiceProtocol

    private var latestBiometrics: BiometricSnapshot?
    private var latestChatImpact: ChatReadinessImpact?
    private var lastAnalyzedChatSessionId: UUID?
    private var lastAnalyzedMessageCount: Int = 0

    init(
        patternEngineUseCase: PatternEngineUseCaseProtocol? = nil,
        checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil,
        chatRepository: ChatRepositoryProtocol? = nil,
        venusAI: VenusAIServiceProtocol? = nil,
        healthKitService: HealthKitServiceProtocol? = nil,
        readinessEngine: ReadinessEngineProtocol? = nil
    ) {
        self.patternEngineUseCase = patternEngineUseCase ?? DependencyContainer.shared.makePatternEngineUseCase()
        self.checkInAllowanceUseCase = checkInAllowanceUseCase ?? DependencyContainer.shared.makeCheckInAllowanceUseCase()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.chatRepository = chatRepository ?? DependencyContainer.shared.makeChatRepository()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeVenusAIService()
        self.healthKitService = healthKitService ?? DependencyContainer.shared.makeHealthKitService()
        self.readinessEngine = readinessEngine ?? DependencyContainer.shared.makeReadinessEngine()
        self.notificationService = DependencyContainer.shared.makeNotificationService()

        startBiometricObservation()

        Task {
            _ = try? await self.healthKitService.requestAuthorization()
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
        Task {
            await notificationService.scheduleEveningReflection()
        }
    }

    func onChatDismissed() {
        selectedChatSession = nil
        Task {
            await refreshMoodStatus(force: true)
        }
    }

    func onMoodCheckInDismissed() {
        Task {
            await refreshMoodStatus(force: true)
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
            await refreshMoodStatus(force: true)
            await fetchAIGreeting(force: true)
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

    func handleReadinessActionSelected(_ category: ReadinessActionRecommendation.ActionCategory) {
        switch category {
        case .talkToVenus, .focus, .rest:
            showVenusChat = true
        case .movement, .breath:
            if checkInAllowance.canCheckIn {
                showMoodCheckIn = true
            } else {
                showVenusChat = true
            }
        }
    }

    // MARK: - Biometric Observation

    private func startBiometricObservation() {
        biometricObserverTask?.cancel()
        biometricObserverTask = Task { [weak self] in
            guard let self = self else { return }
            let stream = self.healthKitService.observeBiometricUpdates()

            for await snapshot in stream {
                guard !Task.isCancelled else { break }
                self.handleBiometricUpdate(snapshot)
            }
        }
    }

    private func handleBiometricUpdate(_ snapshot: BiometricSnapshot) {
        latestBiometrics = snapshot

        biometricDebounceTask?.cancel()
        biometricDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled, let self = self else { return }

            self.recalculateReadiness()
            self.triggerAIMicroCopyUpdate()
        }
    }

    // MARK: - Private Methods

    private func refreshMoodStatus(force: Bool = false) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if !force, let lastRefresh = lastRefreshAt, calendar.isDate(lastRefresh, inSameDayAs: today) {
            let minutesSince = Date().timeIntervalSince(lastRefresh) / 60.0
            if minutesSince < 2.0 { return }
        }
        lastRefreshAt = Date()

        do {
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
            let weekMoods = try await moodRepository.getMoods(from: sevenDaysAgo, to: Date())
            self.weekMoods = weekMoods
            let todayMood = weekMoods.first { calendar.isDate($0.timestamp, inSameDayAs: today) }

            self.hasCheckedInToday = (todayMood != nil)
            self.todayMoodType = todayMood?.type
            self.checkInStreakDays = calculateStreak(from: weekMoods)

            // Update Check-in allowance
            let todayCount = weekMoods.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
            let allowance = await checkInAllowanceUseCase.execute(usedToday: todayCount)
            self.checkInAllowance = allowance
            self.checkInsUsedToday = allowance.usedToday

            // Analyze Chat Impact (se houver nova conversa recente)
            let sessions = try await chatRepository.loadSessions()
            let todaySessions = sessions.filter { calendar.isDate($0.lastMessageAt, inSameDayAs: today) }
            let hasChatToday = !todaySessions.isEmpty

            if let latestSession = todaySessions.first {
                let msgCount = latestSession.messages.count
                if lastAnalyzedChatSessionId != latestSession.id || lastAnalyzedMessageCount != msgCount {
                    lastAnalyzedChatSessionId = latestSession.id
                    lastAnalyzedMessageCount = msgCount

                    if let analysis = await venusAI.analyzeChatReadinessImpact(messages: latestSession.messages) {
                        if analysis.scoreDelta != 0.0 || analysis.customStateTitle != nil {
                            self.latestChatImpact = analysis
                        }
                    }
                }
            } else {
                if let existing = self.latestChatImpact, existing.isExpired {
                    self.latestChatImpact = nil
                }
            }

            // Recalculate with all components (Biometrics + Check-in + Chat Impact)
            recalculateReadiness(todayMoodItem: todayMood, hasChatToday: hasChatToday)
            updateReadinessHistory()
            scheduleProactiveReminders()
            
            // Asynchronously generate personalized AI micro-copy for the score
            triggerAIMicroCopyUpdate()

            await refreshPatternInsights()
            await fetchAIGreeting()
        } catch {
            insightsTask?.cancel()
            insightsTask = nil
            isLoadingInsights = false
            insightsErrorMessage = "Não foi possível atualizar seu status agora."
            print("Error checking mood: \(error)")
        }
    }

    private func recalculateReadiness(todayMoodItem: Mood? = nil, hasChatToday: Bool = false) {
        withAnimation(.easeInOut(duration: 0.35)) {
            self.readinessAssessment = self.readinessEngine.evaluate(
                todayMood: self.todayMoodType,
                todayMoodItem: todayMoodItem,
                weekMoods: self.weekMoods,
                hasRecentChat: hasChatToday,
                biometrics: self.latestBiometrics,
                chatImpact: self.latestChatImpact,
                aiStateTitle: nil,
                aiStateSubtitle: nil
            )
        }
    }

    private func triggerAIMicroCopyUpdate() {
        microCopyTask?.cancel()
        let requestID = UUID()
        microCopyRequestID = requestID
        let currentScore = readinessAssessment.score
        let currentState = readinessAssessment.stateTitle
        let userGoal = userProfile?.primaryGoal

        microCopyTask = Task { [weak self] in
            guard let self = self else { return }
            let (aiTitle, aiSub) = await self.venusAI.generateReadinessMicroCopy(
                score: currentScore,
                primaryState: currentState,
                userContext: userGoal
            )

            guard !Task.isCancelled, self.microCopyRequestID == requestID else { return }
            // Guard: se o score mudou >0.6 enquanto a IA gerava, descarta copy stale
            guard abs(self.readinessAssessment.score - currentScore) < 0.6 else { return }
            guard !aiTitle.isEmpty, !aiSub.isEmpty else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.readinessAssessment = ReadinessEnergyAssessment(
                    id: self.readinessAssessment.id,
                    score: self.readinessAssessment.score,
                    stateTitle: aiTitle,
                    stateSubtitle: aiSub,
                    focusMetric: self.readinessAssessment.focusMetric,
                    bodyMetric: self.readinessAssessment.bodyMetric,
                    sleepMetric: self.readinessAssessment.sleepMetric,
                    biometricsUsed: self.readinessAssessment.biometricsUsed,
                    chatContextUsed: self.readinessAssessment.chatContextUsed,
                    timestamp: self.readinessAssessment.timestamp,
                    breakdown: self.readinessAssessment.breakdown,
                    dataStale: self.readinessAssessment.dataStale
                )
            }
        }
    }

    private func updateReadinessHistory() {
        // Sparkline 7d a partir de weekMoods (normalizado 0-10 via BehaviorMoodScorer)
        let scores = weekMoods.suffix(14).map { mood -> Double in
            let raw = BehaviorMoodScorer.score(for: mood)
            return max(1.0, min(10.0, 6.2 + raw * 2.4))
        }
        self.readinessHistory = Array(scores)
    }

    private func scheduleProactiveReminders() {
        // Proactive schedule
    }

    private func calculateStreak(from moods: [Mood]) -> Int {
        guard !moods.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
        // Group timestamps by start of day
        let uniqueDays = Set(moods.map { calendar.startOfDay(for: $0.timestamp) })
        
        // If not checked in today, check if yesterday was checked in to keep streak alive
        if !uniqueDays.contains(today) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                  uniqueDays.contains(yesterday) else {
                return 0
            }
            checkDate = yesterday
        }
        
        // Count consecutive days
        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previousDay
        }
        
        return streak
    }

    private func refreshPatternInsights() async {
        insightsTask?.cancel()
        let requestID = UUID()
        insightsRequestID = requestID
        isLoadingInsights = true
        insightsErrorMessage = nil

        let task = Task { [weak self] () -> PatternInsightsSnapshot? in
            guard let self = self else { return nil }
            return try? await self.patternEngineUseCase.execute()
        }
        insightsTask = Task {
            _ = await task.result
        }

        let snapshot = await task.value
        guard !Task.isCancelled, self.insightsRequestID == requestID else { return }

        self.patternSnapshot = snapshot
        if let trend = snapshot?.weeklyTrend {
            self.weeklyTrend = trend
        }
        self.isLoadingInsights = false
    }

    private func fetchAIGreeting(force: Bool = false) async {
        let calendar = Calendar.current
        let now = Date()
        
        if !force, let lastDate = lastGreetingDate,
           calendar.isDate(lastDate, inSameDayAs: now) &&
           calendar.component(.hour, from: lastDate) == calendar.component(.hour, from: now) {
            return
        }
        
        let userName = userProfile?.name ?? "Amigo"
        
        do {
            let greeting = try await venusAI.generateGreeting(
                userName: userName,
                mood: todayMoodType
            )
            
            if !greeting.isEmpty {
                self.aiGreeting = greeting
                self.lastGreetingDate = now
            }
        } catch {
            print("Error generating greeting: \(error)")
        }
    }
}
