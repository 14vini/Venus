//
//  BehaviorInsights.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

struct NextBestAction: Identifiable, Hashable, Equatable, Sendable {
    let id: UUID
    let actionKey: String
    let kind: NextBestActionKind
    let title: String
    let detail: String
    let strategicReason: String
    let estimatedMinutes: Int

    init(
        id: UUID = UUID(),
        actionKey: String? = nil,
        kind: NextBestActionKind,
        title: String,
        detail: String,
        strategicReason: String,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.actionKey = actionKey ?? kind.rawValue
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

        let expandedMinutes = max(20, estimatedMinutes + 12)
        let expandedTitle: String
        let expandedDetail: String
        let expandedReason: String

        switch kind.category {
        case .execution:
            expandedTitle = "Bloco guiado: \(title)"
            expandedDetail = "Expanda isso para \(expandedMinutes) minutos com começo claro, foco protegido e um fechamento simples para sair com sensação de avanço real."
            expandedReason = "Quando você transforma um passo curto em bloco protegido, cresce a chance de sair da trava e terminar com sensação de domínio."
        case .recovery:
            expandedTitle = "Protocolo completo: \(title)"
            expandedDetail = "Use \(expandedMinutes) minutos para reduzir estímulo, recuperar o corpo e deixar seu estado mais estável pelo resto do dia."
            expandedReason = "Quando o cansaço ou a pressão estão altos, uma recuperação mais completa costuma funcionar melhor do que só uma pausa rápida."
        case .planning:
            expandedTitle = "Mapa claro para seguir"
            expandedDetail = "Reserve \(expandedMinutes) minutos para organizar a cabeça, cortar excesso e sair com um plano enxuto e fácil de cumprir."
            expandedReason = "Dar estrutura ao que está difuso diminui o peso mental e deixa a ação seguinte muito mais provável."
        case .communication:
            expandedTitle = "Versão preparada da conversa"
            expandedDetail = "Use \(expandedMinutes) minutos para escrever, revisar e deixar a mensagem mais calma, objetiva e segura antes de agir."
            expandedReason = "Quando existe carga emocional em volta da conversa, preparar com calma costuma evitar impulso e reduzir arrependimento."
        case .movement:
            expandedTitle = "Sessão completa: \(title)"
            expandedDetail = "Transforme isso em \(expandedMinutes) minutos de movimento contínuo para descarregar tensão e devolver presença ao corpo."
            expandedReason = "Sustentar o movimento por mais tempo tende a regular melhor a ativação física e limpar a mente."
        }

        return NextBestAction(
            id: id,
            actionKey: "\(actionKey)::deep",
            kind: kind,
            title: expandedTitle,
            detail: expandedDetail,
            strategicReason: expandedReason,
            estimatedMinutes: expandedMinutes
        )
    }
}

enum NextBestActionKind: String, Codable, Hashable, Sendable {
    case resolveAvoidedTask
    case firstStepActivation
    case mentalUnload
    case solveOneProblem
    case scopeReduction
    case taskBreakdown
    case delegateOneThing
    case paperPlanning
    case protectPeakWindow
    case finishSmallWin
    case timerSprint
    case frictionCleanup
    case sleepReset
    case breathReset
    case sensoryPause
    case sceneShift
    case coolDownReset
    case environmentReset
    case mechanicalCare
    case hydrationReset
    case microRest
    case analogReset
    case bodyScan
    case quickExercise
    case walkingRegulation
    case softStretch
    case physicalDischarge
    case difficultMessage
    case safeDraft
    case supportMessage
    case shareGoodMoment
    case deepDisconnect
    case weeklyPlanning
    case valueReconnect
    case pleasureBoost
    case gratitudeMoment
    case celebrationBreak

    var iconName: String {
        switch self {
        case .resolveAvoidedTask:
            return "checklist"
        case .firstStepActivation:
            return "play.circle.fill"
        case .mentalUnload:
            return "square.and.pencil"
        case .solveOneProblem:
            return "lightbulb.max.fill"
        case .scopeReduction:
            return "line.3.horizontal.decrease.circle.fill"
        case .taskBreakdown:
            return "square.split.2x2.fill"
        case .delegateOneThing:
            return "arrowshape.turn.up.right.fill"
        case .paperPlanning:
            return "note.text"
        case .protectPeakWindow:
            return "shield.lefthalf.filled"
        case .finishSmallWin:
            return "checkmark.seal.fill"
        case .timerSprint:
            return "timer"
        case .frictionCleanup:
            return "wand.and.stars"
        case .sleepReset:
            return "bed.double.fill"
        case .breathReset:
            return "wind"
        case .sensoryPause:
            return "drop.fill"
        case .sceneShift:
            return "arrow.triangle.swap"
        case .coolDownReset:
            return "snowflake"
        case .environmentReset:
            return "sparkles"
        case .mechanicalCare:
            return "house.fill"
        case .hydrationReset:
            return "drop.circle.fill"
        case .microRest:
            return "pause.circle.fill"
        case .analogReset:
            return "book.closed.fill"
        case .bodyScan:
            return "figure.mind.and.body"
        case .quickExercise:
            return "figure.run"
        case .walkingRegulation:
            return "figure.walk"
        case .softStretch:
            return "figure.cooldown"
        case .physicalDischarge:
            return "bolt.heart.fill"
        case .difficultMessage:
            return "message.fill"
        case .safeDraft:
            return "text.bubble.fill"
        case .supportMessage:
            return "person.2.fill"
        case .shareGoodMoment:
            return "heart.text.square.fill"
        case .deepDisconnect:
            return "moon.stars.fill"
        case .weeklyPlanning:
            return "calendar.badge.clock"
        case .valueReconnect:
            return "target"
        case .pleasureBoost:
            return "music.note"
        case .gratitudeMoment:
            return "heart.fill"
        case .celebrationBreak:
            return "party.popper.fill"
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
    let alternativeActions: [NextBestAction]
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
        alternativeActions: [NextBestAction] = [],
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
        self.alternativeActions = alternativeActions
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
