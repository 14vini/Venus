//
//  BehaviorInsights.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

struct NextBestAction: Identifiable, Equatable, Sendable {
    let id: UUID
    let kind: NextBestActionKind
    let title: String
    let detail: String
    let strategicReason: String
    let estimatedMinutes: Int

    init(
        id: UUID = UUID(),
        kind: NextBestActionKind,
        title: String,
        detail: String,
        strategicReason: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.detail = detail
        self.strategicReason = strategicReason
        self.estimatedMinutes = estimatedMinutes
    }
}

extension NextBestAction {
    var isHighImpactVariant: Bool {
        estimatedMinutes >= 20
    }

    func asHighImpactVariant() -> NextBestAction {
        guard !isHighImpactVariant else { return self }

        switch kind {
        case .resolveAvoidedTask:
            return NextBestAction(
                kind: kind,
                title: "Bloco de Execução Crítica",
                detail: "Reserve 30 minutos para fechar uma tarefa importante com foco total (25 min execução + 5 min fechamento).",
                strategicReason: "Em risco alto, concluir uma entrega relevante reduz ansiedade antecipatória e recupera senso de controle.",
                estimatedMinutes: 30
            )
        case .sleepReset:
            return NextBestAction(
                kind: kind,
                title: "Protocolo Completo de Sono",
                detail: "Faça um fechamento de 35 minutos: reduzir luz, preparar amanhã e desacelerar gradualmente.",
                strategicReason: "Quando o risco sobe, proteger o sono aumenta estabilidade emocional dos próximos dias.",
                estimatedMinutes: 35
            )
        case .environmentReset:
            return NextBestAction(
                kind: kind,
                title: "Reset Estratégico de Ambiente",
                detail: "Execute 25 minutos de organização por zonas para remover fricção visual e cognitiva.",
                strategicReason: "Ambiente organizado reduz carga mental e ajuda a interromper ciclos de estresse elevado.",
                estimatedMinutes: 25
            )
        case .quickExercise:
            return NextBestAction(
                kind: kind,
                title: "Sessão Física de Recuperação",
                detail: "Realize 30 minutos de movimento continuo (caminhada forte ou treino leve).",
                strategicReason: "Em fase crítica, movimento sustentado regula ativação fisiológica e melhora foco.",
                estimatedMinutes: 30
            )
        case .difficultMessage:
            return NextBestAction(
                kind: kind,
                title: "Conversa Difícil Estruturada",
                detail: "Reserve 25 minutos para preparar e conduzir a mensagem com objetividade e limite claro.",
                strategicReason: "Resolver tensões relacionais reduz ruminação e evita escalada emocional.",
                estimatedMinutes: 25
            )
        case .deepDisconnect:
            return NextBestAction(
                kind: kind,
                title: "Protocolo de Descompressão Profunda",
                detail: "Faça 30 minutos sem tela com rotina de regulação (respiração, silêncio e reorganização mental).",
                strategicReason: "No risco alto, uma pausa profunda diminui hiperestímulo e previne piora no curto prazo.",
                estimatedMinutes: 30
            )
        case .weeklyPlanning:
            return NextBestAction(
                kind: kind,
                title: "Planejamento Tático de Contenção",
                detail: "Use 35 minutos para reduzir escopo, priorizar 3 frentes e proteger energia da semana.",
                strategicReason: "Quando há risco elevado, simplificar decisões reduz sobrecarga e melhora aderência.",
                estimatedMinutes: 35
            )
        }
    }
}

enum NextBestActionKind: String, Codable, Hashable, Sendable {
    case resolveAvoidedTask
    case sleepReset
    case environmentReset
    case quickExercise
    case difficultMessage
    case deepDisconnect
    case weeklyPlanning

    var iconName: String {
        switch self {
        case .resolveAvoidedTask:
            return "checklist"
        case .sleepReset:
            return "bed.double.fill"
        case .environmentReset:
            return "sparkles"
        case .quickExercise:
            return "figure.run"
        case .difficultMessage:
            return "message.fill"
        case .deepDisconnect:
            return "moon.stars.fill"
        case .weeklyPlanning:
            return "calendar.badge.clock"
        }
    }
}

struct WeeklyEmotionalTrend: Equatable, Sendable {
    let direction: WeeklyTrendDirection
    let summary: String
    let currentWeekScore: Double
    let previousWeekScore: Double?
}

enum WeeklyTrendDirection: Equatable, Sendable {
    case improving
    case stable
    case declining

    var title: String {
        switch self {
        case .improving:
            return "Tendência de alta"
        case .stable:
            return "Tendência estável"
        case .declining:
            return "Tendência de queda"
        }
    }

    var iconName: String {
        switch self {
        case .improving:
            return "arrow.up.right"
        case .stable:
            return "arrow.left.and.right"
        case .declining:
            return "arrow.down.right"
        }
    }
}

struct PatternAlert: Equatable, Sendable {
    let title: String
    let detail: String
}

struct WeeklyStrategicInsights: Equatable, Sendable {
    let dominantTrigger: String?
    let bestDay: String?
    let criticalWindow: String?
    let sleepCounterfactual: String?
    let worstRecurringPattern: String
    let behavioralFocus: String
    let leverageScore: Double
    let streakQualityScore: Double
    let recoveryProtocol: RecoveryProtocol?
    let confidence: Double
}

struct RecoveryProtocol: Equatable, Sendable {
    let title: String
    let steps: [String]
}

struct ActionWhyEvidence: Equatable, Sendable {
    let title: String
    let detail: String
}

struct ActionWhyInsight: Equatable, Sendable {
    let summary: String
    let evidence: [ActionWhyEvidence]
    let confidence: Double
}

struct MoodForecastPoint: Identifiable, Equatable, Sendable {
    let dayOffset: Int
    let projectedScore: Double
    let projectedScoreWithAction: Double
    let confidence: Double

    var id: Int { dayOffset }
    var actionDelta: Double { projectedScoreWithAction - projectedScore }
}

struct ProMoodForecast: Equatable, Sendable {
    let generatedAt: Date
    let baselineScore: Double
    let confidence: Double
    let rationale: String
    let riskAlert: String?
    let points: [MoodForecastPoint]
}

struct ConfidenceImprovementInsight: Equatable, Sendable {
    let currentConfidence: Double
    let projectedConfidence7Days: Double
    let projectedConfidence14Days: Double
    let confidenceGain7Days: Double
    let confidenceGain14Days: Double
    let keyLevers: [String]
    let personalizedSummary: String
}

struct TriggerRecoveryPoint: Identifiable, Equatable, Sendable {
    let dayOffset: Int
    let scoreWithoutAction: Double
    let scoreWithAction: Double

    var id: Int { dayOffset }
    var delta: Double { scoreWithAction - scoreWithoutAction }
}

struct TriggerAreaProjection: Identifiable, Equatable, Sendable {
    let id: UUID
    let area: String
    let day3Delta: Double
    let day7Delta: Double
    let confidence: Double

    init(
        id: UUID = UUID(),
        area: String,
        day3Delta: Double,
        day7Delta: Double,
        confidence: Double
    ) {
        self.id = id
        self.area = area
        self.day3Delta = day3Delta
        self.day7Delta = day7Delta
        self.confidence = confidence
    }
}

struct TriggerRecoveryInsight: Equatable, Sendable {
    let highlightedTrigger: String
    let highlightedSummary: String
    let highlightedProjection: [TriggerRecoveryPoint]
    let additionalAreaProjections: [TriggerAreaProjection]
    let lockedAdditionalAreasCount: Int
}

struct ExploreActionSuggestion: Identifiable, Equatable, Sendable {
    let id: UUID
    let activityTitle: String
    let activityDescription: String
    let activityCategory: String
    let durationMinutes: Int
    let iconName: String
    let matchScore: Double
    let recommendationReason: String

    init(
        id: UUID = UUID(),
        activityTitle: String,
        activityDescription: String,
        activityCategory: String,
        durationMinutes: Int,
        iconName: String,
        matchScore: Double,
        recommendationReason: String
    ) {
        self.id = id
        self.activityTitle = activityTitle
        self.activityDescription = activityDescription
        self.activityCategory = activityCategory
        self.durationMinutes = durationMinutes
        self.iconName = iconName
        self.matchScore = matchScore
        self.recommendationReason = recommendationReason
    }
}

struct PatternInsightsSnapshot: Equatable, Sendable {
    let nextBestAction: NextBestAction
    let weeklyTrend: WeeklyEmotionalTrend
    let patternAlert: PatternAlert?
    let weeklyInsights: WeeklyStrategicInsights?
    let actionWhy: ActionWhyInsight?
    let proMoodForecast: ProMoodForecast?
    let confidenceInsight: ConfidenceImprovementInsight?
    let triggerRecoveryInsight: TriggerRecoveryInsight?
    let exploreActionSuggestions: [ExploreActionSuggestion]

    init(
        nextBestAction: NextBestAction,
        weeklyTrend: WeeklyEmotionalTrend,
        patternAlert: PatternAlert?,
        weeklyInsights: WeeklyStrategicInsights? = nil,
        actionWhy: ActionWhyInsight? = nil,
        proMoodForecast: ProMoodForecast? = nil,
        confidenceInsight: ConfidenceImprovementInsight? = nil,
        triggerRecoveryInsight: TriggerRecoveryInsight? = nil,
        exploreActionSuggestions: [ExploreActionSuggestion] = []
    ) {
        self.nextBestAction = nextBestAction
        self.weeklyTrend = weeklyTrend
        self.patternAlert = patternAlert
        self.weeklyInsights = weeklyInsights
        self.actionWhy = actionWhy
        self.proMoodForecast = proMoodForecast
        self.confidenceInsight = confidenceInsight
        self.triggerRecoveryInsight = triggerRecoveryInsight
        self.exploreActionSuggestions = exploreActionSuggestions
    }
}
