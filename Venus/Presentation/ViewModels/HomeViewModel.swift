//
//  HomeViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftUI
import Combine

struct DayOverDayTrendSummary: Equatable {
    let label: String
    let detail: String
    let direction: DayOverDayTrendDirection
}

enum DayOverDayTrendDirection: Equatable {
    case up
    case flat
    case down

    var iconName: String {
        switch self {
        case .up:
            return "arrow.up.right"
        case .flat:
            return "arrow.left.and.right"
        case .down:
            return "arrow.down.right"
        }
    }

    var colorHex: String {
        switch self {
        case .up:
            return "1FA97C"
        case .flat:
            return "6B7280"
        case .down:
            return "FF5F15"
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var userProfile: UserProfile?

    func configure(userProfile: UserProfile) {
        self.userProfile = userProfile
    }

    // MARK: - Home UI state

    @Published var showVenusChat: Bool = false
    @Published var showChatHistory: Bool = false
    @Published var showVenusProPlans: Bool = false
    @Published var showMirror: Bool = false

    @Published var showCheckInHint: Bool = false
    @Published var checkInPrefilledMood: MoodType?

    // MARK: - Home preferences (UserDefaults)

    @Published var preferHighImpactAction: Bool = false {
        didSet { userDefaults.set(preferHighImpactAction, forKey: StorageKey.preferHighImpactAction) }
    }

    @Published var hasSeenCheckInFloatingHint: Bool = false {
        didSet { userDefaults.set(hasSeenCheckInFloatingHint, forKey: StorageKey.hasSeenCheckInFloatingHint) }
    }

    @Published var hasSeenFirstLaunchGuide: Bool = false {
        didSet { userDefaults.set(hasSeenFirstLaunchGuide, forKey: StorageKey.hasSeenFirstLaunchGuide) }
    }

    @Published var streakOverride: Int = 0 {
        didSet { userDefaults.set(streakOverride, forKey: StorageKey.streakOverride) }
    }

    @Published var streakOverrideEnabled: Bool = false {
        didSet { userDefaults.set(streakOverrideEnabled, forKey: StorageKey.streakOverrideEnabled) }
    }

    @Published private(set) var isPremiumTestEnabled: Bool = false

    @Published var hasCheckedInToday: Bool = false {
        didSet {
            guard hasCheckedInToday != oldValue else { return }
            presentCheckInHint()
        }
    }
    @Published var showMoodCheckIn: Bool = false
    @Published var showUpgradePrompt: Bool = false
    @Published var weeklyTrend: WeeklyEmotionalTrend?
    @Published var patternAlert: PatternAlert?
    @Published var weeklyInsights: WeeklyStrategicInsights?
    @Published var proMoodForecast: ProMoodForecast?
    @Published var isLoadingInsights: Bool = false
    @Published var todayMoodType: MoodType?
    @Published var todayMoodIntensity: Int?
    @Published var todayMoodTags: [String] = []
    @Published var todayMoodEnergyLevel: MoodEnergyLevel?
    @Published var todayMoodAvailableTime: MoodAvailableTime?
    @Published var todayMoodControlLevel: MoodControlLevel?
    @Published var todayMoodAffectedArea: MoodAffectedArea?
    @Published var todayMoodMentalClarity: Int?
    @Published var todayMoodSleepQuality: MoodSleepQuality?
    @Published var todayMoodBodySignals: [String] = []
    @Published var dayOverDayTrend: DayOverDayTrendSummary?
    @Published var checkInStreakDays: Int = 0
    @Published var checkInsUsedToday: Int = 0
    @Published var checkInAllowance: CheckInAllowance = .freeDefault {
        didSet {
            guard checkInAllowance.usedToday != oldValue.usedToday else { return }
            presentCheckInHint()
        }
    }
    @Published var insightsErrorMessage: String?
    @Published var isCriticalRiskNow: Bool = false {
        didSet {
            if isCriticalRiskNow {
                preferHighImpactAction = true
            }
        }
    }

    var freePlanDailyLimit: Int { CheckInAllowance.defaultFreeDailyLimit }

    private let patternEngineUseCase: PatternEngineUseCaseProtocol
    private let checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let richEngine = RichRecommendationEngine()
    private let userDefaults: UserDefaults

    private var defaultsCancellable: AnyCancellable?
    private var checkInHintSequence: Int = 0

    private enum StorageKey {
        static let preferHighImpactAction = "home.preferHighImpactAction"
        static let hasSeenCheckInFloatingHint = "home.hasSeenCheckInFloatingHint"
        static let hasSeenFirstLaunchGuide = "home.hasSeenFirstLaunchGuide"
        static let streakOverride = "debug.streakOverride"
        static let streakOverrideEnabled = "debug.streakOverrideEnabled"
        static let planKey = LocalSubscriptionStatusProvider.planKey
    }

    private var insightsTask: Task<Void, Never>?
    private var insightsRequestID = UUID()

    init(
        patternEngineUseCase: PatternEngineUseCaseProtocol,
        checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol,
        moodRepository: MoodRepositoryProtocol,
        userDefaults: UserDefaults = .standard
    ) {
        self.patternEngineUseCase = patternEngineUseCase
        self.checkInAllowanceUseCase = checkInAllowanceUseCase
        self.moodRepository = moodRepository
        self.userDefaults = userDefaults

        loadStoredPreferences()
        observeSubscriptionChanges()

        Task {
            await checkIfCheckedIn()
        }
    }

    deinit {
        insightsTask?.cancel()
        defaultsCancellable?.cancel()
    }

    // MARK: - Lifecycle

    func onAppear() {
        loadStoredPreferences()
        presentCheckInHint()
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

    func refreshAfterPlanToggle() {
        Task {
            await refreshMoodStatus()
        }
    }

    func handleInlineMoodSelection(_ mood: MoodType) {
        guard checkInAllowance.canCheckIn else {
            showUpgradePrompt = true
            return
        }

        checkInPrefilledMood = mood
        showMoodCheckIn = true
        if !hasSeenFirstLaunchGuide {
            hasSeenFirstLaunchGuide = true
        }
    }

    func handleCheckInAction() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            showCheckInHint = false
        }

        if !hasSeenFirstLaunchGuide {
            hasSeenFirstLaunchGuide = true
        }

        guard checkInAllowance.canCheckIn else {
            showUpgradePrompt = true
            return
        }

        checkInPrefilledMood = nil
        showMoodCheckIn = true
    }

    private func checkIfCheckedIn() async {
        await refreshMoodStatus()
    }

    private func refreshMoodStatus() async {
        insightsErrorMessage = nil

        do {
            let usedToday = try await moodRepository.getMoodCount(on: Date())
            checkInsUsedToday = usedToday
            checkInAllowance = await checkInAllowanceUseCase.execute(usedToday: usedToday)
            hasCheckedInToday = usedToday > 0

            if let todayMood = try await moodRepository.getTodayMood() {
                todayMoodType = todayMood.type
                todayMoodIntensity = todayMood.intensity
                todayMoodTags = todayMood.triggers
                todayMoodEnergyLevel = todayMood.energyLevel
                todayMoodAvailableTime = todayMood.availableTime
                todayMoodControlLevel = todayMood.controlLevel
                todayMoodAffectedArea = todayMood.affectedArea
                todayMoodMentalClarity = todayMood.mentalClarity
                todayMoodSleepQuality = todayMood.sleepQuality
                todayMoodBodySignals = todayMood.bodySignals
                dayOverDayTrend = try await buildDayOverDayTrend(for: todayMood)
            } else {
                hasCheckedInToday = false
                todayMoodType = nil
                todayMoodIntensity = nil
                todayMoodTags = []
                todayMoodEnergyLevel = nil
                todayMoodAvailableTime = nil
                todayMoodControlLevel = nil
                todayMoodAffectedArea = nil
                todayMoodMentalClarity = nil
                todayMoodSleepQuality = nil
                todayMoodBodySignals = []
                dayOverDayTrend = nil
                weeklyTrend = nil
                patternAlert = nil
                weeklyInsights = nil
                isCriticalRiskNow = false
            }

            let streakStartDate = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
            let moods = try await moodRepository.getMoods(from: streakStartDate, to: Date())
            checkInStreakDays = calculateCheckInStreak(from: moods)
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
                let snapshot = try await self.patternEngineUseCase.execute(referenceDate: Date())
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }

                withAnimation {
                    self.weeklyTrend = snapshot?.weeklyTrend
                    self.patternAlert = snapshot?.patternAlert
                    self.weeklyInsights = snapshot?.weeklyInsights
                    self.proMoodForecast = snapshot?.proMoodForecast
                    self.isCriticalRiskNow = self.evaluateCriticalRisk(
                        patternAlert: snapshot?.patternAlert,
                        weeklyTrend: snapshot?.weeklyTrend,
                        proForecast: snapshot?.proMoodForecast
                    )
                    self.isLoadingInsights = false
                    self.insightsErrorMessage = nil
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
                self.weeklyInsights = nil
                self.proMoodForecast = nil
                self.isCriticalRiskNow = false
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

    private func buildDayOverDayTrend(for todayMood: Mood) async throws -> DayOverDayTrendSummary? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        guard
            let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday),
            let endOfYesterday = calendar.date(byAdding: .second, value: -1, to: startOfToday)
        else {
            return nil
        }

        let yesterdayMoods = try await moodRepository.getMoods(from: startOfYesterday, to: endOfYesterday)
        guard let yesterdayMood = yesterdayMoods.last else { return nil }

        let delta = wellbeingScore(for: todayMood) - wellbeingScore(for: yesterdayMood)
        return summary(for: delta)
    }

    private func wellbeingScore(for mood: Mood) -> Int {
        var score: Int

        switch mood.type {
        case .happy:
            score = 74
        case .energetic:
            score = 72
        case .calm:
            score = 68
        case .tired:
            score = 46
        case .stressed:
            score = 34
        case .sad:
            score = 28
        }

        if let intensity = mood.intensity {
            let normalizedIntensity = min(max(intensity, 1), 10)
            let centered = normalizedIntensity - 5

            switch mood.type {
            case .happy, .energetic, .calm:
                score += centered * 3
            case .tired, .stressed, .sad:
                score -= centered * 3
            }
        }

        if let energyLevel = mood.energyLevel {
            switch energyLevel {
            case .low:
                score -= 5
            case .medium:
                break
            case .high:
                score += 5
            }
        }

        return min(max(score, 0), 100)
    }

    private func summary(for delta: Int) -> DayOverDayTrendSummary {
        if abs(delta) <= 4 {
            return DayOverDayTrendSummary(
                label: "Estável vs ontem",
                detail: "Seu estado ficou quase no mesmo nível.",
                direction: .flat
            )
        }

        if delta > 0 {
            return DayOverDayTrendSummary(
                label: "+\(delta) vs ontem",
                detail: "Houve melhora no estado geral.",
                direction: .up
            )
        }

        return DayOverDayTrendSummary(
            label: "\(delta) vs ontem",
            detail: "Seu estado caiu em relação a ontem.",
            direction: .down
        )
    }

    private func evaluateCriticalRisk(
        patternAlert: PatternAlert?,
        weeklyTrend: WeeklyEmotionalTrend?,
        proForecast: ProMoodForecast?
    ) -> Bool {
        var riskScore = 0

        if let moodType = todayMoodType, moodType == .stressed || moodType == .sad {
            let intensity = todayMoodIntensity ?? 6
            if intensity >= 8 {
                riskScore += 3
            } else if intensity >= 6 {
                riskScore += 2
            }
        }

        if todayMoodEnergyLevel == .low {
            riskScore += 1
        }

        if todayMoodControlLevel == .low {
            riskScore += 1
        }

        if dayOverDayTrend?.direction == .down {
            riskScore += 1
        }

        if weeklyTrend?.direction == .declining {
            riskScore += 1
        }

        if let patternAlert {
            let raw = "\(patternAlert.title) \(patternAlert.detail)".lowercased()
            let alertKeywords = ["risco", "queda", "crit", "sobrecarga", "piora", "alerta"]
            if alertKeywords.contains(where: { raw.contains($0) }) {
                riskScore += 2
            } else {
                riskScore += 1
            }
        }

        if let proForecast {
            if proForecast.riskAlert != nil {
                riskScore += 2
            }

            let severePoints = proForecast.points.filter {
                $0.projectedScore <= -0.95 || $0.projectedScoreWithAction <= -0.75
            }
            if !severePoints.isEmpty {
                riskScore += 2
            } else {
                let moderatePoints = proForecast.points.filter {
                    $0.projectedScore <= -0.60 || $0.projectedScoreWithAction <= -0.45
                }
                if moderatePoints.count >= 2 {
                    riskScore += 1
                }
            }
        }

        return riskScore >= 4
    }

    // MARK: - Derived presentation values

    var dayMoment: DayMoment { .current }

    var displayedStreakDays: Int {
        streakOverrideEnabled ? streakOverride : checkInStreakDays
    }

    var heroSelectedMood: MoodType? {
        todayMoodType ?? dayMoment.defaultMascotMood
    }

    var ritualProgressLabel: String {
        let nextIndex = checkInAllowance.usedToday + 1
        if checkInAllowance.isUnlimited {
            return "Ritual \(nextIndex)/∞"
        }

        let limit = checkInAllowance.dailyLimit ?? freePlanDailyLimit
        return "Ritual \(min(nextIndex, limit))/\(limit)"
    }

    var checkInStatusLabel: String {
        hasCheckedInToday ? "feito hoje" : "pendente hoje"
    }



    var checkInFloatingButtonTitle: String {
        if !hasCheckedInToday {
            return "Fazer check-in"
        }
        if checkInAllowance.canCheckIn {
            return "Novo check-in"
        }
        return "Mais check-ins"
    }

    var checkInFloatingButtonSubtitle: String {
        if !hasCheckedInToday {
            return "abre o check-in completo"
        }
        if checkInAllowance.canCheckIn {
            return "abra uma nova atualização"
        }
        return "veja como liberar atualizações"
    }

    var checkInFloatingButtonIcon: String {
        if !hasCheckedInToday {
            return "heart.text.square.fill"
        }
        if checkInAllowance.canCheckIn {
            return "plus.circle.fill"
        }
        return "crown.fill"
    }

    var checkInHintTitle: String {
        if !hasCheckedInToday {
            return "Comece o check-in aqui"
        }
        if checkInAllowance.canCheckIn {
            return "Quer registrar um novo check-in?"
        }
        return "Seu check-in de hoje já está salvo"
    }

    var checkInHintBody: String {
        if !hasSeenFirstLaunchGuide {
            return "Vamos registrar como você está? Toque no seu humor atual ou no botão abaixo para começarmos."
        }
        if !hasSeenCheckInFloatingHint {
            return "Este botão flutuante abre o check-in completo sempre que você precisar se atualizar."
        }
        if !hasCheckedInToday {
            return "Leva só alguns segundos para cuidar de você."
        }
        if checkInAllowance.canCheckIn {
            return "Só abra novamente se sentir que o seu momento mudou."
        }
        return "No plano gratuito, focamos em um check-in caprichado por dia."
    }

    enum RoutineStatus {
        case working
        case studying
        case leisure
    }

    var currentRoutineStatus: RoutineStatus {
        guard let profile = userProfile else { return .leisure }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let totalMinutesNow = currentHour * 60 + currentMinute
        
        // Check Work
        if let work = profile.workSchedule, work.hasWork {
            let startHour = calendar.component(.hour, from: work.startTime)
            let startMinute = calendar.component(.minute, from: work.startTime)
            let endHour = calendar.component(.hour, from: work.endTime)
            let endMinute = calendar.component(.minute, from: work.endTime)
            
            let startTotal = startHour * 60 + startMinute
            let endTotal = endHour * 60 + endMinute
            
            if startTotal <= endTotal {
                if totalMinutesNow >= startTotal && totalMinutesNow <= endTotal {
                    return .working
                }
            } else {
                // Crosses midnight
                if totalMinutesNow >= startTotal || totalMinutesNow <= endTotal {
                    return .working
                }
            }
        }
        
        // Check Study
        if profile.studySchedule.studies {
            let startHour = calendar.component(.hour, from: profile.studySchedule.startTime)
            let startMinute = calendar.component(.minute, from: profile.studySchedule.startTime)
            let endHour = calendar.component(.hour, from: profile.studySchedule.endTime)
            let endMinute = calendar.component(.minute, from: profile.studySchedule.endTime)
            
            let startTotal = startHour * 60 + startMinute
            let endTotal = endHour * 60 + endMinute
            
            if startTotal <= endTotal {
                if totalMinutesNow >= startTotal && totalMinutesNow <= endTotal {
                    return .studying
                }
            } else {
                // Crosses midnight
                if totalMinutesNow >= startTotal || totalMinutesNow <= endTotal {
                    return .studying
                }
            }
        }
        
        return .leisure
    }

    var routineStatusLabel: String {
        switch currentRoutineStatus {
        case .working:
            return "Expediente de Trabalho"
        case .studying:
            return "Estudo Ativo"
        case .leisure:
            return "Tempo de Lazer"
        }
    }
    
    var routineStatusIcon: String {
        switch currentRoutineStatus {
        case .working:
            return "briefcase.fill"
        case .studying:
            return "book.closed.fill"
        case .leisure:
            return "sparkles"
        }
    }
    
    var routineStatusColorHex: String {
        switch currentRoutineStatus {
        case .working:
            return "3B82F6"
        case .studying:
            return "8B5CF6"
        case .leisure:
            return "10B981"
        }
    }

    var homeHeadline: String {
        if !hasCheckedInToday {
            switch currentRoutineStatus {
            case .working:
                return "Expediente ativo! 💼 Lembre-se de fazer micro-pausas para manter a clareza mental."
            case .studying:
                return "Momento de dedicação! 📚 Como está o seu foco e clareza nos estudos agora?"
            case .leisure:
                if let profile = userProfile, let firstHobby = profile.currentHobbies.first ?? profile.desiredHobbies.first {
                    return "Tempo de lazer! 🌟 Já pensou em praticar um de seus hobbies hoje, como \(firstHobby.lowercased())?"
                }
                return dayMoment.greeting
            }
        }

        let streak = displayedStreakDays
        switch streak {
        case 3: return "⚡️ 3 dias seguidos! Você está criando um hábito real."
        case 7: return "🔥 Uma semana inteira! Isso é consistência de verdade."
        case 14: return "⭐️ Duas semanas! Seu ritmo está mais forte do que nunca."
        case 30: return "🏆 30 dias! Você transformou isso em parte da sua vida."
        default: break
        }

        switch todayMoodType {
        case .stressed: return "Ainda pesado por aí? Me conta como evoluiu."
        case .tired: return "Descansou um pouco? Atualiza quando quiser."
        case .sad: return "Como você está agora? Pode me contar."
        case .happy: return "Boa energia! Ainda assim por aí?"
        case .calm: return "Ainda tranquilo? Ou o dia mudou?"
        case .energetic: return "Ainda com energia? Me conta como tá indo."
        case nil: return dayMoment.greeting
        }
    }

    // MARK: - Private helpers

    private func loadStoredPreferences() {
        isPremiumTestEnabled = userDefaults.bool(forKey: StorageKey.planKey)
        preferHighImpactAction = userDefaults.bool(forKey: StorageKey.preferHighImpactAction)
        hasSeenCheckInFloatingHint = userDefaults.bool(forKey: StorageKey.hasSeenCheckInFloatingHint)
        hasSeenFirstLaunchGuide = userDefaults.bool(forKey: StorageKey.hasSeenFirstLaunchGuide)
        streakOverride = userDefaults.integer(forKey: StorageKey.streakOverride)
        streakOverrideEnabled = userDefaults.bool(forKey: StorageKey.streakOverrideEnabled)
    }

    private func observeSubscriptionChanges() {
        defaultsCancellable = NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: userDefaults)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    let latest = self.userDefaults.bool(forKey: StorageKey.planKey)
                    guard latest != self.isPremiumTestEnabled else { return }
                    self.isPremiumTestEnabled = latest
                    self.refreshAfterPlanToggle()
                }
            }
    }

    private func presentCheckInHint() {
        let shouldShowHint = !hasSeenFirstLaunchGuide || !hasSeenCheckInFloatingHint
        guard shouldShowHint else {
            showCheckInHint = false
            return
        }

        checkInHintSequence += 1
        let sequence = checkInHintSequence

        withAnimation(.spring(response: 0.36, dampingFraction: 0.88)) {
            showCheckInHint = true
        }

        hasSeenCheckInFloatingHint = true

        guard hasSeenFirstLaunchGuide else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard sequence == checkInHintSequence else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.92)) {
                showCheckInHint = false
            }
        }
    }
}
