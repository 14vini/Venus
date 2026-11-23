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
    var showReadinessBreakdown: Bool = false
    var showMyDay: Bool = false
    var checkInPrefilledMood: MoodType? = nil
    var todayPlan: DailyPlan? = nil

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
    var isHomeLoading: Bool = false
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

    /// Cosmético desbloqueado pelo streak real — o mesmo mapa do mascote hero.
    var unlockedCosmetic: VenusCosmeticItem {
        if checkInStreakDays >= 30 { return .saturnRing }
        if checkInStreakDays >= 14 { return .cosmicHeadphones }
        if checkInStreakDays >= 7 { return .astralWings }
        if checkInStreakDays >= 3 { return .starHalo }
        return .none
    }

    /// Progresso honesto do dia, derivado apenas de dados já existentes no ViewModel.
    /// Usa os blocos concluídos do plano diário; sem plano, usa o check-in de hoje.
    var dailyProgress: (completed: Int, total: Int) {
        if let plan = todayPlan, plan.totalBlocksCount > 0 {
            return (min(plan.completedBlocksCount, plan.totalBlocksCount), plan.totalBlocksCount)
        }
        return (hasCheckedInToday ? 1 : 0, 1)
    }

    var dailyProgressLabel: String {
        let progress = dailyProgress
        return "\(progress.completed) de \(progress.total) rituais"
    }

    private let patternEngineUseCase: PatternEngineUseCaseProtocol
    private let checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let chatRepository: ChatRepositoryProtocol
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let venusAI: VenusAIServiceProtocol
    private let healthKitService: HealthKitServiceProtocol
    private let readinessEngine: ReadinessEngineProtocol

    private var insightsTask: Task<Void, Never>?
    private var biometricObserverTask: Task<Void, Never>?
    private var biometricDebounceTask: Task<Void, Never>?
    private var microCopyTask: Task<Void, Never>?
    private var chatImpactTask: Task<Void, Never>?
    private var greetingTask: Task<Void, Never>?
    private var insightsRequestID = UUID()
    private var microCopyRequestID = UUID()
    private var chatImpactRequestID = UUID()
    private var greetingRequestID = UUID()
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
        dailyPlanRepository: DailyPlanRepositoryProtocol? = nil,
        venusAI: VenusAIServiceProtocol? = nil,
        healthKitService: HealthKitServiceProtocol? = nil,
        readinessEngine: ReadinessEngineProtocol? = nil
    ) {
        self.patternEngineUseCase = patternEngineUseCase ?? DependencyContainer.shared.makePatternEngineUseCase()
        self.checkInAllowanceUseCase = checkInAllowanceUseCase ?? DependencyContainer.shared.makeCheckInAllowanceUseCase()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.chatRepository = chatRepository ?? DependencyContainer.shared.makeChatRepository()
        self.dailyPlanRepository = dailyPlanRepository ?? DependencyContainer.shared.makeDailyPlanRepository()
        self.venusAI = venusAI ?? DependencyContainer.shared.makeVenusAIService()
        self.healthKitService = healthKitService ?? DependencyContainer.shared.makeHealthKitService()
        self.readinessEngine = readinessEngine ?? DependencyContainer.shared.makeReadinessEngine()
        self.notificationService = DependencyContainer.shared.makeNotificationService()

        startBiometricObservation()

        // Autorização de HealthKit não bloqueia a leitura local que monta a tela.
        Task { [weak self] in
            guard let self = self else { return }
            _ = try? await self.healthKitService.requestAuthorization()
        }
        Task { [weak self] in
            guard let self = self else { return }
            await self.refreshMoodStatus()
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
        // A4: a saudação é gerada depois de configure(userProfile:) — o nome veio do perfil,
        // não do placeholder "Amigo" — e é exibida no hero da Home.
        fetchAIGreeting()
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

        Task { [weak self] in
            guard let self = self else { return }
            await self.refreshMoodStatus(force: true)
            self.fetchAIGreeting(force: true)
        }
    }

    func retryInsights() {
        refreshPatternInsights()
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

    // MARK: - Private Methods

    private func refreshMoodStatus(force: Bool = false) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if !force, let lastRefresh = lastRefreshAt, calendar.isDate(lastRefresh, inSameDayAs: today) {
            let minutesSince = Date().timeIntervalSince(lastRefresh) / 60.0
            if minutesSince < 2.0 { return }
        }
        lastRefreshAt = Date()

        isHomeLoading = true
        defer { isHomeLoading = false }

        do {
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

            // Leituras locais independentes em paralelo: a tela não espera a IA.
            async let fetchedMoods = moodRepository.getMoods(from: sevenDaysAgo, to: Date())
            // A3: a tendência usa a janela de 7 dias, mas o streak (e os cosméticos
            // de 14/30 dias) precisa do histórico completo. Buscar só 7 dias quebrava
            // a sequência acima de uma semana.
            async let fetchedAllMoods = moodRepository.getAllMoods()
            async let fetchedPlan = try? dailyPlanRepository.getPlan(for: Date())
            async let fetchedSessions = chatRepository.loadSessions()

            let weekMoods = try await fetchedMoods
            let allMoods = (try? await fetchedAllMoods) ?? weekMoods
            let plan = await fetchedPlan
            let sessions = try await fetchedSessions

            // O allowance depende da contagem de check-ins de hoje, que vem dos moods.
            let todayCount = weekMoods.filter { calendar.isDate($0.timestamp, inSameDayAs: today) }.count
            let allowance = await checkInAllowanceUseCase.execute(usedToday: todayCount)

            let todayMood = weekMoods.first { calendar.isDate($0.timestamp, inSameDayAs: today) }
            let todaySessions = sessions.filter { calendar.isDate($0.lastMessageAt, inSameDayAs: today) }
            let hasChatToday = !todaySessions.isEmpty

            // Publica todo o estado local de uma vez, antes de qualquer chamada de IA.
            self.weekMoods = weekMoods
            self.hasCheckedInToday = (todayMood != nil)
            self.todayMoodType = todayMood?.type
            self.checkInStreakDays = calculateStreak(from: allMoods)
            self.todayPlan = plan
            self.checkInAllowance = allowance
            self.checkInsUsedToday = allowance.usedToday

            if let existing = latestChatImpact, existing.isExpired {
                latestChatImpact = nil
            }

            recalculateReadiness(todayMoodItem: todayMood, hasChatToday: hasChatToday)
            updateReadinessHistory()
            scheduleProactiveReminders()

            withAnimation(.easeInOut(duration: 0.25)) {
                isHomeLoading = false
            }

            // IA em background: complementa a tela quando chega, sem bloqueá-la.
            triggerAIMicroCopyUpdate()
            refreshPatternInsights()
            if let latestSession = todaySessions.first {
                scheduleChatImpactAnalysis(session: latestSession)
            }
        } catch {
            insightsTask?.cancel()
            insightsTask = nil
            isLoadingInsights = false
            insightsErrorMessage = "Não foi possível atualizar seu status agora."
            print("Error checking mood: \(error)")
        }
    }

    private func recalculateReadinessWithCurrentData(hasChatToday: Bool = false) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayMoodItem = weekMoods.first { calendar.isDate($0.timestamp, inSameDayAs: today) }
        recalculateReadiness(todayMoodItem: todayMoodItem, hasChatToday: hasChatToday)
    }

    // MARK: - IA em background

    private func scheduleChatImpactAnalysis(session: ChatSession) {
        let sessionID = session.id
        let messages = session.messages
        let messageCount = messages.count

        guard lastAnalyzedChatSessionId != sessionID || lastAnalyzedMessageCount != messageCount else { return }
        lastAnalyzedChatSessionId = sessionID
        lastAnalyzedMessageCount = messageCount

        chatImpactTask?.cancel()
        let requestID = UUID()
        chatImpactRequestID = requestID

        chatImpactTask = Task { [weak self] in
            guard let self = self else { return }
            guard let analysis = await self.venusAI.analyzeChatReadinessImpact(messages: messages) else { return }
            guard !Task.isCancelled, self.chatImpactRequestID == requestID else { return }
            guard !analysis.isExpired else { return }
            guard analysis.scoreDelta != 0.0 || analysis.customStateTitle != nil else { return }

            withAnimation(.easeInOut(duration: 0.3)) {
                self.latestChatImpact = analysis
            }
            self.recalculateReadinessWithCurrentData(hasChatToday: true)
            self.triggerAIMicroCopyUpdate()
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

    private func calculateStreak(from moods: [Mood]) -> Int {
        guard !moods.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today
        
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

    private func refreshPatternInsights() {
        insightsTask?.cancel()
        let requestID = UUID()
        insightsRequestID = requestID
        isLoadingInsights = true
        insightsErrorMessage = nil

        insightsTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                // A4: usa o callback assíncrono. O snapshot local chega rápido; a IA paga
                // atualiza a Home quando termina, em vez de rodar no caminho síncrono.
                let localSnapshot = try await self.patternEngineUseCase.execute(
                    referenceDate: Date(),
                    onAIUpdate: { [weak self] snapshot in
                        Task { @MainActor [weak self] in
                            guard let self, self.insightsRequestID == requestID else { return }
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.patternSnapshot = snapshot
                                self.weeklyTrend = snapshot.weeklyTrend
                                self.isLoadingInsights = false
                            }
                        }
                    }
                )
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.patternSnapshot = localSnapshot
                    if let trend = localSnapshot?.weeklyTrend {
                        self.weeklyTrend = trend
                    }
                    self.isLoadingInsights = false
                }
            } catch {
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
                self.isLoadingInsights = false
                self.insightsErrorMessage = "Não foi possível atualizar suas reflexões agora."
                print("Error refreshing pattern insights: \(error)")
            }
        }
    }

    private func fetchAIGreeting(force: Bool = false) {
        let calendar = Calendar.current
        let now = Date()

        if !force, let lastDate = lastGreetingDate,
           calendar.isDate(lastDate, inSameDayAs: now) &&
           calendar.component(.hour, from: lastDate) == calendar.component(.hour, from: now) {
            return
        }

        let userName = userProfile?.name ?? "Amigo"
        let mood = todayMoodType

        greetingTask?.cancel()
        let requestID = UUID()
        greetingRequestID = requestID

        greetingTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                let greeting = try await self.venusAI.generateGreeting(
                    userName: userName,
                    mood: mood
                )
                guard !Task.isCancelled, self.greetingRequestID == requestID else { return }
                guard !greeting.isEmpty else { return }

                withAnimation(.easeInOut(duration: 0.3)) {
                    self.aiGreeting = greeting
                    self.lastGreetingDate = now
                }
            } catch {
                print("Error generating greeting: \(error)")
            }
        }
    }
}
