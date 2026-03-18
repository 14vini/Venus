//
//  BehaviorActionPolicyEngine.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

struct BehaviorActionPolicyEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func selectAction(
        latestMood: BehaviorMoodEvent?,
        latestAggregate: BehaviorDailyAggregate?,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> NextBestAction {
        let hour = calendar.component(.hour, from: referenceDate)
        let dayKey = calendar.startOfDay(for: referenceDate)
        let todayPending = max(0, (latestAggregate?.todoTotal ?? 0) - (latestAggregate?.todoCompleted ?? 0))
        let lowClarityToday = (latestAggregate?.averageClarity ?? 10) <= 4
        let highStressToday = (latestAggregate?.stressSignalTotal ?? 0) > 0
        let dominantTrigger = analysis.indicators.dominantNegativeTrigger ?? ""
        let hasSleepImpact = analysis.indicators.hasSleepImpact
        let hasEmotionalProcrastination = analysis.indicators.hasEmotionalProcrastination
        let hasHabitCorrelation = analysis.indicators.hasHabitCorrelation
        let currentPeriod = dayPeriod(for: hour)
        let isInsideWorstPeriod = analysis.indicators.worstPeriod == currentPeriod
        let availableMinutes = latestMood?.availableTime?.maxMinutes ?? 12
        let controlLevel = latestMood?.controlLevel
        let highEnergyLowMoodConflict = latestMood?.energyLevel == .high && (latestMood?.moodScore ?? 0) <= -0.35

        var candidates: [ActionCandidate] = []

        if hasEmotionalProcrastination || todayPending >= 3 {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .resolveAvoidedTask,
                        title: "Destrave 1 tarefa evitada",
                        detail: "Escolha uma tarefa pendente de até 10 minutos e conclua agora.",
                        strategicReason: "Reduzir pendências cedo diminui sobrecarga cognitiva no restante do dia.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.92,
                    evidenceMatch: hasEmotionalProcrastination ? 0.92 : 0.74,
                    contextFit: contextualFit(
                        for: .resolveAvoidedTask,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .resolveAvoidedTask, history: history)
                )
            )
        }

        if hasSleepImpact || latestMood?.sleepQuality == .poor || latestMood?.sleepQuality == .fair {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .sleepReset,
                        title: hour >= 20 ? "Ajuste seu sono hoje" : "Proteja seu sono esta noite",
                        detail: hour >= 20
                            ? "Defina horário de deitar e inicie desaceleração 30 min antes."
                            : "Evite sobrecarga no fim do dia para chegar com energia melhor à noite.",
                        strategicReason: "Seu padrão recente mostra relação direta entre sono e qualidade emocional.",
                        estimatedMinutes: hour >= 20 ? 15 : 8
                    ),
                    urgency: hour >= 20 ? 0.85 : 0.60,
                    evidenceMatch: hasSleepImpact ? 0.90 : 0.70,
                    contextFit: contextualFit(
                        for: .sleepReset,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .sleepReset, history: history)
                )
            )
        }

        if latestMood?.energyLevel == .low || latestMood?.moodType == .tired || lowClarityToday {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .deepDisconnect,
                        title: "Desconecte por 20 minutos",
                        detail: "Pausa sem notificações para recuperar foco e reduzir ruído mental.",
                        strategicReason: "Energia baixa com baixa clareza piora decisão e aumenta impulsividade.",
                        estimatedMinutes: 20
                    ),
                    urgency: isInsideWorstPeriod ? 0.90 : 0.80,
                    evidenceMatch: isInsideWorstPeriod ? 0.90 : (lowClarityToday ? 0.86 : 0.70),
                    contextFit: contextualFit(
                        for: .deepDisconnect,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .deepDisconnect, history: history)
                )
            )
        }

        if analysis.indicators.lowClarityDays >= 3 {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .weeklyPlanning,
                        title: "Simplifique as 3 prioridades",
                        detail: "Defina apenas 3 prioridades reais e adie o restante.",
                        strategicReason: "Planejamento mais enxuto reduz carga mental e melhora consistência.",
                        estimatedMinutes: 12
                    ),
                    urgency: 0.72,
                    evidenceMatch: 0.85,
                    contextFit: contextualFit(
                        for: .weeklyPlanning,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .weeklyPlanning, history: history)
                )
            )
        }

        if hasHabitCorrelation {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .weeklyPlanning,
                        title: "Proteja 2 hábitos-base hoje",
                        detail: "Escolha 2 hábitos mínimos inegociáveis e execute antes do fim do dia.",
                        strategicReason: "Seu histórico mostra queda emocional quando a consistência de hábitos diminui.",
                        estimatedMinutes: 9
                    ),
                    urgency: 0.74,
                    evidenceMatch: 0.84,
                    contextFit: contextualFit(
                        for: .weeklyPlanning,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .weeklyPlanning, history: history)
                )
            )
        }

        if dominantTrigger.contains("relacion") || dominantTrigger.contains("famil") {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .difficultMessage,
                        title: "Envie a mensagem pendente",
                        detail: "Escreva uma mensagem curta e objetiva para destravar essa tensão.",
                        strategicReason: "Seu gatilho dominante aponta acúmulo emocional em conversas evitadas.",
                        estimatedMinutes: 8
                    ),
                    urgency: 0.70,
                    evidenceMatch: 0.82,
                    contextFit: contextualFit(
                        for: .difficultMessage,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .difficultMessage, history: history)
                )
            )
        }

        if highStressToday || analysis.indicators.highStressDays >= 2 {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .environmentReset,
                        title: "Reset rápido de ambiente",
                        detail: "Organize sua área principal por 10 minutos para reduzir fricção mental.",
                        strategicReason: "Seu padrão corporal de estresse responde bem à redução de desordem visual.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.68,
                    evidenceMatch: 0.78,
                    contextFit: contextualFit(
                        for: .environmentReset,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .environmentReset, history: history)
                )
            )
        }

        if highEnergyLowMoodConflict {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .resolveAvoidedTask,
                        title: "Canalize energia em 1 tarefa crítica",
                        detail: "Use essa energia para fechar uma tarefa de 8 a 10 minutos com impacto real.",
                        strategicReason: "Energia alta com humor baixo tende a virar irritação; execução curta converte tensão em progresso.",
                        estimatedMinutes: 9
                    ),
                    urgency: 0.86,
                    evidenceMatch: 0.87,
                    contextFit: contextualFit(
                        for: .resolveAvoidedTask,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .resolveAvoidedTask, history: history)
                )
            )
        }

        if latestMood?.moodType == .energetic || latestMood?.energyLevel == .high || latestMood?.moodType == .happy {
            candidates.append(
                ActionCandidate(
                    action: NextBestAction(
                        kind: .quickExercise,
                        title: "Movimente o corpo por 12 minutos",
                        detail: "Caminhada rápida ou exercício curto para canalizar energia.",
                        strategicReason: "Canalizar energia alta melhora foco e reduz dispersão.",
                        estimatedMinutes: 12
                    ),
                    urgency: 0.55,
                    evidenceMatch: 0.75,
                    contextFit: contextualFit(
                        for: .quickExercise,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideWorstPeriod
                    ),
                    adherenceLikelihood: adherenceScore(for: .quickExercise, history: history)
                )
            )
        }

        if candidates.isEmpty {
            candidates.append(
                contextualFallbackCandidate(
                    period: currentPeriod,
                    hour: hour,
                    profile: profile,
                    history: history,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideWorstPeriod
                )
            )
        }

        let ranked = candidates
            .map { candidate -> RankedCandidate in
                let score = finalScore(for: candidate, history: history, referenceDate: referenceDate)
                let tieBreaker = deterministicVariation(for: candidate.action.kind, dayKey: dayKey)
                return RankedCandidate(
                    candidate: candidate,
                    score: score,
                    tieBreaker: tieBreaker
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.score - rhs.score) < 0.0001 {
                    if lhs.tieBreaker == rhs.tieBreaker {
                        return lhs.candidate.action.estimatedMinutes < rhs.candidate.action.estimatedMinutes
                    }
                    return lhs.tieBreaker > rhs.tieBreaker
                }
                return lhs.score > rhs.score
            }

        return ranked.first?.candidate.action ?? candidates[0].action
    }

    private func finalScore(
        for candidate: ActionCandidate,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> Double {
        let kind = candidate.action.kind
        let novelty = noveltyScore(for: kind, history: history)
        let cooldownPenalty = cooldownPenalty(for: kind, history: history, referenceDate: referenceDate)
        let repetitionPenalty = categoryRepetitionPenalty(for: kind.category, history: history)
        let frictionPenalty = frictionPenalty(for: candidate)

        return
            0.35 * candidate.urgency +
            0.25 * candidate.evidenceMatch +
            0.20 * candidate.contextFit +
            0.10 * candidate.adherenceLikelihood +
            0.10 * novelty -
            cooldownPenalty -
            frictionPenalty -
            repetitionPenalty
    }

    private func noveltyScore(for kind: NextBestActionKind, history: ActionHistorySummary) -> Double {
        let recentCount = history.recentSuggestedKinds.filter { $0 == kind }.count
        return max(0, 1.0 - (Double(recentCount) / 4.0))
    }

    private func cooldownPenalty(
        for kind: NextBestActionKind,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> Double {
        guard let lastDate = history.lastSuggestedAt[kind] else { return 0 }
        let days = calendar.dateComponents([.day], from: lastDate, to: referenceDate).day ?? 99
        if days <= 0 { return 0.45 }
        if days == 1 { return 0.30 }
        if days == 2 { return 0.14 }
        return 0
    }

    private func categoryRepetitionPenalty(
        for category: ActionSuggestionCategory,
        history: ActionHistorySummary
    ) -> Double {
        let count = history.suggestedCategoryCountsLast7Days[category, default: 0]
        if count <= 2 { return 0 }
        if count == 3 { return 0.10 }
        if count == 4 { return 0.18 }
        if count == 5 { return 0.24 }
        if count >= 6 { return 0.30 }
        return 0
    }

    private func frictionPenalty(for candidate: ActionCandidate) -> Double {
        let minutes = candidate.action.estimatedMinutes
        let timePenalty: Double
        switch minutes {
        case ...8:
            timePenalty = 0.02
        case 9...12:
            timePenalty = 0.06
        case 13...18:
            timePenalty = 0.10
        default:
            timePenalty = 0.16
        }

        let contextPenalty = (1.0 - candidate.contextFit) * 0.08
        let adherencePenalty = candidate.adherenceLikelihood < 0.40 ? 0.06 : 0
        return min(0.30, timePenalty + contextPenalty + adherencePenalty)
    }

    private func adherenceScore(
        for kind: NextBestActionKind,
        history: ActionHistorySummary
    ) -> Double {
        if let rate = history.completionRateByKind[kind] {
            return min(1.0, max(0.25, rate))
        }
        let started = history.startedCountByKind[kind, default: 0]
        if started >= 2 {
            return 0.62
        }
        return 0.55
    }

    private func contextualFit(
        for kind: NextBestActionKind,
        profile: BehaviorProfileContext,
        hour: Int,
        availableMinutes: Int,
        controlLevel: MoodControlLevel?,
        isInsideCriticalWindow: Bool
    ) -> Double {
        var score = 0.5

        switch kind {
        case .sleepReset:
            if profile.improvementAreas.contains("sono") || profile.improvementAreas.contains("energia") {
                score += 0.24
            }
            if hour >= 19 {
                score += 0.18
            }
        case .resolveAvoidedTask:
            if profile.improvementAreas.contains("foco e produtividade") || profile.improvementAreas.contains("motivacao") {
                score += 0.22
            }
            if isInsideWorkOrStudyWindow(hour: hour, profile: profile) {
                score += 0.10
            }
        case .difficultMessage:
            if profile.improvementAreas.contains("relacionamentos") || profile.improvementAreas.contains("comunicacao") {
                score += 0.22
            }
            if profile.emotionalAreas.contains("solidao") || profile.emotionalAreas.contains("inseguranca") {
                score += 0.12
            }
        case .quickExercise:
            if profile.improvementAreas.contains("saude fisica") || profile.interests.contains("atividade fisica") {
                score += 0.20
            }
            if hour >= 7 && hour <= 18 {
                score += 0.10
            }
        case .deepDisconnect:
            if profile.emotionalAreas.contains("estresse") || profile.emotionalAreas.contains("overwhelm") {
                score += 0.22
            }
        case .weeklyPlanning:
            if profile.improvementAreas.contains("foco e produtividade") {
                score += 0.18
            }
        case .environmentReset:
            if profile.improvementAreas.contains("equilibrio de vida") || profile.improvementAreas.contains("ansiedade") {
                score += 0.16
            }
        }

        score += (timeBudgetFit(for: kind, availableMinutes: availableMinutes) - 0.5) * 0.36
        score += (controlFit(for: kind, controlLevel: controlLevel) - 0.5) * 0.28
        if isInsideCriticalWindow, kind == .deepDisconnect || kind == .resolveAvoidedTask || kind == .environmentReset {
            score += 0.08
        }

        return max(0, min(1, score))
    }

    private func isInsideWorkOrStudyWindow(hour: Int, profile: BehaviorProfileContext) -> Bool {
        if let start = profile.workStartHour, let end = profile.workEndHour, hour >= start, hour <= end {
            return true
        }
        if let start = profile.studyStartHour, let end = profile.studyEndHour, hour >= start, hour <= end {
            return true
        }
        return false
    }

    private func dayPeriod(for hour: Int) -> BehaviorDayPeriod {
        switch hour {
        case 6..<12:
            return .morning
        case 12..<18:
            return .afternoon
        case 18..<24:
            return .evening
        default:
            return .night
        }
    }

    private func contextualFallbackCandidate(
        period: BehaviorDayPeriod,
        hour: Int,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary,
        availableMinutes: Int,
        controlLevel: MoodControlLevel?,
        isInsideCriticalWindow: Bool
    ) -> ActionCandidate {
        if availableMinutes <= 5 {
            return ActionCandidate(
                action: NextBestAction(
                    kind: .deepDisconnect,
                    title: "Respire e reduza ruído por 5 minutos",
                    detail: "Pausa curta sem notificações para recuperar foco agora.",
                    strategicReason: "Janela curta com ação mínima ainda reduz sobrecarga e protege o restante do dia.",
                    estimatedMinutes: 5
                ),
                urgency: 0.60,
                evidenceMatch: 0.54,
                contextFit: contextualFit(
                    for: .deepDisconnect,
                    profile: profile,
                    hour: hour,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideCriticalWindow
                ),
                adherenceLikelihood: adherenceScore(for: .deepDisconnect, history: history)
            )
        }

        switch period {
        case .morning:
            return ActionCandidate(
                action: NextBestAction(
                    kind: .weeklyPlanning,
                    title: "Defina 1 prioridade crítica",
                    detail: "Escolha o único resultado essencial da manhã.",
                    strategicReason: "Clareza no início do dia reduz dispersão e melhora execução.",
                    estimatedMinutes: 6
                ),
                urgency: 0.54,
                evidenceMatch: 0.48,
                contextFit: contextualFit(
                    for: .weeklyPlanning,
                    profile: profile,
                    hour: hour,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideCriticalWindow
                ),
                adherenceLikelihood: adherenceScore(for: .weeklyPlanning, history: history)
            )
        case .afternoon:
            return ActionCandidate(
                action: NextBestAction(
                    kind: .resolveAvoidedTask,
                    title: "Feche 1 tarefa de 10 minutos",
                    detail: "Escolha uma pendência curta para recuperar tração.",
                    strategicReason: "Execução curta no meio do dia reduz backlog emocional.",
                    estimatedMinutes: 10
                ),
                urgency: 0.58,
                evidenceMatch: 0.50,
                contextFit: contextualFit(
                    for: .resolveAvoidedTask,
                    profile: profile,
                    hour: hour,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideCriticalWindow
                ),
                adherenceLikelihood: adherenceScore(for: .resolveAvoidedTask, history: history)
            )
        case .evening:
            if hour >= 21 {
                return ActionCandidate(
                    action: NextBestAction(
                        kind: .sleepReset,
                        title: "Proteja seu fechamento do dia",
                        detail: "Inicie um ritual curto de desaceleração para dormir melhor.",
                        strategicReason: "Noite bem encerrada reduz oscilação emocional no dia seguinte.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.64,
                    evidenceMatch: 0.52,
                    contextFit: contextualFit(
                        for: .sleepReset,
                        profile: profile,
                        hour: hour,
                        availableMinutes: availableMinutes,
                        controlLevel: controlLevel,
                        isInsideCriticalWindow: isInsideCriticalWindow
                    ),
                    adherenceLikelihood: adherenceScore(for: .sleepReset, history: history)
                )
            }
            return ActionCandidate(
                action: NextBestAction(
                    kind: .environmentReset,
                    title: "Reset visual de 10 minutos",
                    detail: "Organize seu espaço principal para reduzir sobrecarga.",
                    strategicReason: "Ambiente mais limpo tende a diminuir ruído cognitivo no fim do dia.",
                    estimatedMinutes: 10
                ),
                urgency: 0.56,
                evidenceMatch: 0.47,
                contextFit: contextualFit(
                    for: .environmentReset,
                    profile: profile,
                    hour: hour,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideCriticalWindow
                ),
                adherenceLikelihood: adherenceScore(for: .environmentReset, history: history)
            )
        case .night:
            return ActionCandidate(
                action: NextBestAction(
                    kind: .deepDisconnect,
                    title: "Desligue por 15 minutos",
                    detail: "Pause notificações e reduza estímulos antes de dormir.",
                    strategicReason: "Descompressão noturna melhora recuperação mental.",
                    estimatedMinutes: 15
                ),
                urgency: 0.60,
                evidenceMatch: 0.50,
                contextFit: contextualFit(
                    for: .deepDisconnect,
                    profile: profile,
                    hour: hour,
                    availableMinutes: availableMinutes,
                    controlLevel: controlLevel,
                    isInsideCriticalWindow: isInsideCriticalWindow
                ),
                adherenceLikelihood: adherenceScore(for: .deepDisconnect, history: history)
            )
        }
    }

    private func timeBudgetFit(for kind: NextBestActionKind, availableMinutes: Int) -> Double {
        let recommended = recommendedMinutes(for: kind)
        if availableMinutes >= recommended {
            return 1.0
        }
        if availableMinutes >= max(5, recommended - 3) {
            return 0.78
        }
        if availableMinutes >= max(3, recommended / 2) {
            return 0.56
        }
        return 0.35
    }

    private func controlFit(for kind: NextBestActionKind, controlLevel: MoodControlLevel?) -> Double {
        guard let controlLevel else { return 0.62 }
        switch controlLevel {
        case .low:
            switch kind {
            case .deepDisconnect, .sleepReset, .environmentReset:
                return 0.88
            case .resolveAvoidedTask, .difficultMessage:
                return 0.45
            case .quickExercise, .weeklyPlanning:
                return 0.60
            }
        case .medium:
            return 0.70
        case .high:
            switch kind {
            case .resolveAvoidedTask, .difficultMessage, .weeklyPlanning:
                return 0.90
            case .quickExercise, .sleepReset, .environmentReset, .deepDisconnect:
                return 0.72
            }
        }
    }

    private func recommendedMinutes(for kind: NextBestActionKind) -> Int {
        switch kind {
        case .resolveAvoidedTask:
            return 10
        case .sleepReset:
            return 10
        case .environmentReset:
            return 10
        case .quickExercise:
            return 12
        case .difficultMessage:
            return 8
        case .deepDisconnect:
            return 15
        case .weeklyPlanning:
            return 8
        }
    }

    private func deterministicVariation(for kind: NextBestActionKind, dayKey: Date) -> Double {
        let seed = Int(dayKey.timeIntervalSince1970)
        let hash = stableHash64("\(seed)|\(kind.rawValue)")
        return Double(hash % 10_000) / 10_000.0
    }

    private func stableHash64(_ value: String) -> UInt64 {
        let bytes = value.utf8
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }
}

private struct ActionCandidate {
    let action: NextBestAction
    let urgency: Double
    let evidenceMatch: Double
    let contextFit: Double
    let adherenceLikelihood: Double
}

private struct RankedCandidate {
    let candidate: ActionCandidate
    let score: Double
    let tieBreaker: Double
}
