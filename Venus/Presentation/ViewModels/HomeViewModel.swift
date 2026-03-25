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
    @Published var hasCheckedInToday: Bool = false
    @Published var showMoodCheckIn: Bool = false
    @Published var showUpgradePrompt: Bool = false
    @Published var nextBestAction: NextBestAction?
    @Published var alternativeActions: [NextBestAction] = []
    @Published var weeklyTrend: WeeklyEmotionalTrend?
    @Published var patternAlert: PatternAlert?
    @Published var weeklyInsights: WeeklyStrategicInsights?
    @Published var actionWhy: ActionWhyInsight?
    @Published var proMoodForecast: ProMoodForecast?
    @Published var confidenceInsight: ConfidenceImprovementInsight?
    @Published var triggerRecoveryInsight: TriggerRecoveryInsight?
    @Published var exploreActionSuggestions: [ExploreActionSuggestion] = []
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
    @Published var checkInAllowance: CheckInAllowance = .freeDefault
    @Published var insightsErrorMessage: String?
    @Published var isCriticalRiskNow: Bool = false

    var freePlanDailyLimit: Int { CheckInAllowance.defaultFreeDailyLimit }

    private let patternEngineUseCase: PatternEngineUseCaseProtocol
    private let checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let richEngine = RichRecommendationEngine()

    private var insightsTask: Task<Void, Never>?
    private var insightsRequestID = UUID()

    init(
        patternEngineUseCase: PatternEngineUseCaseProtocol,
        checkInAllowanceUseCase: CheckInAllowanceUseCaseProtocol,
        moodRepository: MoodRepositoryProtocol
    ) {
        self.patternEngineUseCase = patternEngineUseCase
        self.checkInAllowanceUseCase = checkInAllowanceUseCase
        self.moodRepository = moodRepository

        Task {
            await checkIfCheckedIn()
        }
    }

    deinit {
        insightsTask?.cancel()
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
            await refreshPatternInsights(allowNextBestAction: hasCheckedInToday)
        }
    }

    func refreshAfterPlanToggle() {
        Task {
            await refreshMoodStatus()
        }
    }

    func selectAlternativeAction(_ action: NextBestAction) {
        guard nextBestAction?.actionKey != action.actionKey else { return }

        let previousPrimary = nextBestAction
        nextBestAction = action

        var reordered = alternativeActions.filter { $0.actionKey != action.actionKey }
        if let previousPrimary, previousPrimary.actionKey != action.actionKey {
            reordered.insert(previousPrimary, at: 0)
        }
        alternativeActions = Array(reordered.prefix(4))
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
                nextBestAction = nil
                alternativeActions = []
                actionWhy = nil
                proMoodForecast = nil
                confidenceInsight = nil
                triggerRecoveryInsight = nil
                exploreActionSuggestions = []
                weeklyTrend = nil
                patternAlert = nil
                weeklyInsights = nil
                isCriticalRiskNow = false
            }

            let streakStartDate = Calendar.current.date(byAdding: .day, value: -365, to: Date()) ?? Date()
            let moods = try await moodRepository.getMoods(from: streakStartDate, to: Date())
            checkInStreakDays = calculateCheckInStreak(from: moods)
            await refreshPatternInsights(allowNextBestAction: hasCheckedInToday)
        } catch {
            insightsTask?.cancel()
            insightsTask = nil
            isLoadingInsights = false
            insightsErrorMessage = "Não foi possível atualizar seu status agora."
            print("Error checking mood: \(error)")
        }
    }

    private func refreshPatternInsights(allowNextBestAction: Bool) async {
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
                    let action = allowNextBestAction ? snapshot?.nextBestAction : nil
                    self.nextBestAction = action
                    self.alternativeActions = action != nil ? (snapshot?.alternativeActions ?? []) : []
                    self.actionWhy = action != nil ? snapshot?.actionWhy : nil
                    self.proMoodForecast = snapshot?.proMoodForecast
                    self.confidenceInsight = snapshot?.confidenceInsight
                    self.triggerRecoveryInsight = snapshot?.triggerRecoveryInsight
                    self.exploreActionSuggestions = snapshot?.exploreActionSuggestions ?? []
                    self.isCriticalRiskNow = self.evaluateCriticalRisk(
                        patternAlert: snapshot?.patternAlert,
                        weeklyTrend: snapshot?.weeklyTrend,
                        proForecast: snapshot?.proMoodForecast
                    )
                    self.isLoadingInsights = false
                    self.insightsErrorMessage = nil

                    if self.nextBestAction == nil {
                        self.useRichFallback()
                    }
                }
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, self.insightsRequestID == requestID else { return }
                self.nextBestAction = nil
                self.alternativeActions = []
                self.weeklyInsights = nil
                self.actionWhy = nil
                self.proMoodForecast = nil
                self.confidenceInsight = nil
                self.triggerRecoveryInsight = nil
                self.exploreActionSuggestions = []
                self.isCriticalRiskNow = false
                self.isLoadingInsights = false
                self.insightsErrorMessage = "Não consegui analisar seus padrões agora."
                self.useRichFallback()
                print("Error generating pattern insights: \(error)")
            }
        }
    }

    private func useRichFallback() {
        guard let moodCluster = todayMoodType?.cluster else { return }

        let moderators = Moderators(
            tempoMinutos: todayMoodAvailableTime?.maxMinutes,
            energia: todayMoodEnergyLevel.map { level in
                switch level {
                case .low: return "baixa"
                case .medium: return "media"
                case .high: return "alta"
                }
            },
            controle: todayMoodControlLevel.map { level in
                switch level {
                case .low: return "baixo"
                case .medium: return "medio"
                case .high: return "alto"
                }
            },
            clareza: todayMoodMentalClarity.map { clarity in
                if clarity <= 3 { return "baixa" }
                if clarity <= 7 { return "media" }
                return "alta"
            },
            area: todayMoodAffectedArea.map { area in
                switch area {
                case .work: return "trabalho"
                case .relationship: return "relacao"
                case .health: return "saude"
                case .discipline: return "disciplina"
                case .finances: return "finanças"
                case .studies: return "estudo"
                case .social: return "social"
                case .family: return "familia"
                case .personal: return "pessoal"
                }
            },
            riscoAlto: false,
            horario: Date()
        )

        let context = UserContext(
            mood: moodCluster,
            intensity: todayMoodIntensity ?? 5,
            moderators: moderators,
            valuePriority: nil,
            area: moderators.area,
            blockedTask: nil,
            easyTask: nil,
            helpsHistory: [:],
            lastActionCategory: nil
        )

        let variants = richEngine.rankedSuggestions(for: context, limit: 5)
        guard let primaryVariant = variants.first else { return }
        let copyWhy = RichRecommendationEngine.defaultPlaybook[moodCluster]?.copyWhy.randomElement()

        let fallbackAction = buildFallbackAction(
            from: primaryVariant,
            moodCluster: moodCluster,
            reason: copyWhy
        )
        let alternatives = variants
            .dropFirst()
            .map { buildFallbackAction(from: $0, moodCluster: moodCluster, reason: copyWhy) }

        withAnimation {
            self.nextBestAction = fallbackAction
            self.alternativeActions = Array(alternatives.prefix(4))
            self.actionWhy = copyWhy.map {
                ActionWhyInsight(
                    summary: $0,
                    evidence: [],
                    confidence: 0.55
                )
            }
        }
    }

    private func buildFallbackAction(
        from variant: ActionVariant,
        moodCluster: MoodCluster,
        reason: String?
    ) -> NextBestAction {
        NextBestAction(
            actionKey: variant.id.uuidString,
            kind: fallbackKind(for: variant),
            title: variant.title,
            detail: variant.detail,
            strategicReason: reason ?? fallbackReason(for: moodCluster),
            estimatedMinutes: variant.duration
        )
    }

    private func fallbackKind(for variant: ActionVariant) -> NextBestActionKind {
        let title = BehaviorMoodScorer.normalize(variant.title)
        let category = BehaviorMoodScorer.normalize(variant.category)

        switch category {
        case "respiracao":
            return .breathReset
        case "movimento":
            if title.contains("along") { return .softStretch }
            if title.contains("caminh") || title.contains("passeio") { return .walkingRegulation }
            return .quickExercise
        case "organizacao":
            if title.contains("brain dump") || title.contains("anotar o que drena") { return .mentalUnload }
            if title.contains("dividir") { return .taskBreakdown }
            if title.contains("remova") || title.contains("prior") { return .scopeReduction }
            if title.contains("proteger") || title.contains("janela") { return .protectPeakWindow }
            if title.contains("primeiro") || title.contains("tijolo") { return .firstStepActivation }
            return .paperPlanning
        case "conexao":
            return title.contains("coisa boa") || title.contains("encontro") ? .shareGoodMoment : .supportMessage
        case "auto_cuidado":
            if title.contains("agua") || title.contains("hidr") || title.contains("checagem") { return .hydrationReset }
            if title.contains("musica") { return .pleasureBoost }
            if title.contains("sono") || title.contains("noite") { return .sleepReset }
            return .mechanicalCare
        case "act_valor":
            return .valueReconnect
        case "behavioral_activation":
            if title.contains("sprint") { return .timerSprint }
            if title.contains("finalizar") || title.contains("fechar") { return .finishSmallWin }
            return .resolveAvoidedTask
        case "manutencao":
            return .environmentReset
        case "sono":
            return title.contains("microdescanso") || title.contains("soneca") ? .microRest : .sleepReset
        case "relacionamento":
            return title.contains("rascunho") ? .safeDraft : .difficultMessage
        case "gratidao":
            return .gratitudeMoment
        case "motivacao":
            return .celebrationBreak
        default:
            return .deepDisconnect
        }
    }

    private func fallbackReason(for cluster: MoodCluster) -> String {
        switch cluster {
        case .ansioso, .estressado:
            return "Essa ação tende a funcionar porque reduz pressão e devolve mais controle para o agora."
        case .sobrecarregado:
            return "Essa ação ajuda a cortar excesso e te devolver sensação de direção."
        case .irritado:
            return "Essa ação serve para baixar impulso antes de qualquer decisão maior."
        case .triste, .desmotivado:
            return "Essa ação busca te devolver movimento sem exigir demais de uma vez."
        case .apatico:
            return "Essa ação quebra a inércia de um jeito leve e mais fácil de cumprir."
        case .cansadoFisico, .cansadoMental:
            return "Essa ação poupa energia e ajuda seu corpo e sua cabeça a recuperarem ritmo."
        case .calmo, .feliz, .energizado, .focado:
            return "Essa ação aproveita o seu melhor estado para transformar isso em progresso real."
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
}
