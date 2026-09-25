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
        healthKitService: HealthKitServiceProtocol? = nil
    ) {
        self.patternEngineUseCase = patternEngineUseCase ?? DependencyContainer.shared.makePatternEngineUseCase()
        self.checkInAllowanceUseCase = checkInAllowanceUseCase ?? DependencyContainer.shared.makeCheckInAllowanceUseCase()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.chatRepository = chatRepository ?? DependencyContainer.shared.makeChatRepository()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeVenusAIService()
        self.healthKitService = healthKitService ?? DependencyContainer.shared.makeHealthKitService()
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

    // MARK: - Biometric Observation

    private func startBiometricObservation() {
        biometricObserverTask?.cancel()
        biometricObserverTask = Task { [weak self] in
            guard let self = self else { return }
            for await snapshot in self.healthKitService.observeBiometricUpdates() {
                guard !Task.isCancelled else { break }
                self.handleNewBiometricSnapshot(snapshot)
            }
        }
    }

    private func handleNewBiometricSnapshot(_ snapshot: BiometricSnapshot) {
        // Debounce 2s: evita re-animação em rajada do HKObserverQuery
        biometricDebounceTask?.cancel()
        biometricDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard let self, !Task.isCancelled else { return }
            self.latestBiometrics = snapshot
            self.recalculateReadiness()
        }
    }

    // MARK: - Mood & Readiness Refresh

    func refreshMoodStatus(force: Bool = false) async {
        // Throttle: evita refetch pesado (365d) a cada onAppear/scenePhase
        if !force, let last = lastRefreshAt, Date().timeIntervalSince(last) < 60 {
            return
        }
        lastRefreshAt = Date()
        insightsErrorMessage = nil

        do {
            let usedToday = try await moodRepository.getMoodCount(on: Date())
            checkInsUsedToday = usedToday
            checkInAllowance = await checkInAllowanceUseCase.execute(usedToday: usedToday)
            hasCheckedInToday = usedToday > 0

            let todayMood = try await moodRepository.getTodayMood()
            if let todayMood {
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
            
            // Fetch Biometrics
            let snapshot = await healthKitService.fetchBiometricSnapshot()
            self.latestBiometrics = snapshot

            // Analyze Chat Impact if recent conversation occurred
            let sessions = (try? await chatRepository.loadSessions()) ?? []
            let calendar = Calendar.current
            let recentSession = sessions.first { session in
                session.messages.contains { calendar.isDateInToday($0.timestamp) }
            }

            let hasChatToday = recentSession != nil

            if let session = recentSession, !session.messages.isEmpty {
                let userMsgCount = session.messages.filter { $0.isFromUser }.count
                if lastAnalyzedChatSessionId != session.id || lastAnalyzedMessageCount != userMsgCount {
                    self.lastAnalyzedChatSessionId = session.id
                    self.lastAnalyzedMessageCount = userMsgCount
                    let impact = await venusAI.analyzeChatReadinessImpact(messages: session.messages)
                    self.latestChatImpact = impact
                } else if let existing = self.latestChatImpact, existing.isExpired {
                    // Limpa impacto stale (>24h) — antes persistia para sempre
                    self.latestChatImpact = nil
                }
            } else {
                // Sem conversa hoje: limpa impacto antigo
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
            self.readinessAssessment = ReadinessEnergyAssessment.evaluate(
                todayMood: self.todayMoodType,
                todayMoodItem: todayMoodItem,
                weekMoods: self.weekMoods,
                hasRecentChat: hasChatToday,
                biometrics: self.latestBiometrics,
                chatImpact: self.latestChatImpact
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
        readinessHistory = Array(scores.suffix(7))
    }

    private func scheduleProactiveReminders() {
        let score = readinessAssessment.score
        let title = readinessAssessment.stateTitle
        Task {
            await notificationService.scheduleMorningReadiness(score: score, stateTitle: title)
            await notificationService.scheduleEveningReflection()
            if let window = patternSnapshot?.weeklyInsights?.criticalWindow, !window.isEmpty {
                await notificationService.scheduleCriticalWindowAlert(window: window)
            }
        }
    }

    private func fetchAIGreeting(force: Bool = false) async {
        let name = userProfile?.name ?? "você"
        
        if !force, let lastDate = lastGreetingDate, Date().timeIntervalSince(lastDate) < 1800, aiGreeting != nil {
            return
        }
        
        do {
            let greeting = try await venusAI.generateGreeting(userName: name, mood: todayMoodType)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.aiGreeting = greeting
                self.lastGreetingDate = Date()
            }
        } catch {
            print("Could not generate AI greeting: \(error)")
        }
    }

    private func refreshPatternInsights() async {
        insightsTask?.cancel()
        let requestID = UUID()
        insightsRequestID = requestID
        insightsErrorMessage = nil
        isLoadingInsights = true

        insightsTask = Task { [weak self] in
            guard let self = self else { return }

            do {
                let snapshot = try await self.patternEngineUseCase.execute(referenceDate: Date()) { [weak self] mergedSnapshot in
                    guard let self = self else { return }
                    Task { @MainActor in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.patternSnapshot = mergedSnapshot
                            self.weeklyTrend = mergedSnapshot.weeklyTrend
                        }
                    }
                }
                
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }

                withAnimation {
                    self.patternSnapshot = snapshot
                    self.weeklyTrend = snapshot?.weeklyTrend
                    self.isLoadingInsights = false
                    self.insightsErrorMessage = nil
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
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
