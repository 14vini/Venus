//
//  BehaviorActionPolicyEngine.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

struct BehaviorActionSelection: Sendable {
    let primary: NextBestAction
    let alternatives: [NextBestAction]
}

struct BehaviorActionPolicyEngine {
    private let calendar: Calendar
    private let richEngine: RichRecommendationEngine

    init(
        calendar: Calendar = .current,
        richEngine: RichRecommendationEngine = RichRecommendationEngine()
    ) {
        self.calendar = calendar
        self.richEngine = richEngine
    }

    func selectRecommendations(
        latestMood: BehaviorMoodEvent?,
        latestAggregate: BehaviorDailyAggregate?,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> BehaviorActionSelection {
        let runtime = RecommendationRuntimeContext(
            calendar: calendar,
            latestMood: latestMood,
            latestAggregate: latestAggregate,
            analysis: analysis,
            profile: profile,
            referenceDate: referenceDate
        )

        var candidates = makeHeuristicCandidates(
            runtime: runtime,
            analysis: analysis,
            profile: profile,
            history: history
        )

        candidates.append(
            contentsOf: makeRichCandidates(
                runtime: runtime,
                analysis: analysis,
                profile: profile,
                history: history
            )
        )

        if candidates.isEmpty {
            candidates.append(fallbackCandidate(runtime: runtime, profile: profile, history: history))
        }

        let ranked = deduplicatedCandidates(from: candidates)
            .map { candidate -> RankedCandidate in
                let score = finalScore(for: candidate, history: history, referenceDate: referenceDate)
                let tieBreaker = deterministicVariation(for: candidate.action.actionKey, dayKey: runtime.dayKey)
                return RankedCandidate(candidate: candidate, score: score, tieBreaker: tieBreaker)
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

        let primary = ranked.first?.candidate.action ?? candidates[0].action
        let alternatives = buildAlternatives(from: ranked.dropFirst().map(\.candidate.action), primary: primary)

        return BehaviorActionSelection(primary: primary, alternatives: alternatives)
    }

    func selectAction(
        latestMood: BehaviorMoodEvent?,
        latestAggregate: BehaviorDailyAggregate?,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> NextBestAction {
        selectRecommendations(
            latestMood: latestMood,
            latestAggregate: latestAggregate,
            analysis: analysis,
            profile: profile,
            history: history,
            referenceDate: referenceDate
        ).primary
    }

    private func makeHeuristicCandidates(
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary
    ) -> [ActionCandidate] {
        var candidates: [ActionCandidate] = []

        if analysis.indicators.hasEmotionalProcrastination || runtime.todayPending >= 3 {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .resolveAvoidedTask,
                        title: "Destrave uma tarefa importante",
                        detail: "Escolha a pendência mais curta que ainda pesa na sua cabeça e faça só até o ponto de conclusão.",
                        strategicReason: "Pendência que fica martelando costuma drenar mais energia do que uma ação curta para encerrá-la.",
                        estimatedMinutes: min(max(runtime.availableMinutes, 8), 12)
                    ),
                    urgency: 0.90,
                    evidenceMatch: analysis.indicators.hasEmotionalProcrastination ? 0.92 : 0.76,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if analysis.indicators.hasSleepImpact || runtime.sleepFragile {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .sleepReset,
                        title: runtime.hour >= 20 ? "Proteger seu sono hoje" : "Poupar energia para mais tarde",
                        detail: runtime.hour >= 20
                            ? "Faça um fechamento mais leve agora para chegar na noite com menos ruído."
                            : "Baixe a exigência no resto do dia para não pagar essa conta mais tarde.",
                        strategicReason: "Seu padrão recente mostra que quando o sono piora, o restante do dia costuma pesar junto.",
                        estimatedMinutes: runtime.hour >= 20 ? 15 : 8
                    ),
                    urgency: runtime.hour >= 20 ? 0.84 : 0.66,
                    evidenceMatch: analysis.indicators.hasSleepImpact ? 0.92 : 0.72,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if runtime.lowClarityToday || runtime.latestMood?.moodType == .tired {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .analogReset,
                        title: "Reset mental sem telas",
                        detail: "Saia das notificações e faça algo físico simples por alguns minutos para aliviar o excesso de estímulo.",
                        strategicReason: "Quando a clareza cai, insistir no mesmo canal costuma piorar a saturação mental.",
                        estimatedMinutes: min(max(runtime.availableMinutes, 7), 15)
                    ),
                    urgency: runtime.isInsideWorstPeriod ? 0.88 : 0.78,
                    evidenceMatch: runtime.lowClarityToday ? 0.88 : 0.72,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if analysis.indicators.lowClarityDays >= 3 {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .scopeReduction,
                        title: "Reduzir o escopo do dia",
                        detail: "Escolha o que realmente fica de pé hoje e tire o restante da frente sem culpa.",
                        strategicReason: "Quando o excesso vira padrão, simplificar costuma ajudar mais do que tentar dar conta de tudo.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.76,
                    evidenceMatch: 0.84,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if analysis.indicators.hasHabitCorrelation {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .paperPlanning,
                        title: "Proteger os dois apoios do seu dia",
                        detail: "Defina dois hábitos mínimos que sustentam você hoje e deixe o resto em segundo plano.",
                        strategicReason: "Seu histórico aponta que pequenos apoios consistentes seguram melhor seu ritmo do que cobranças grandes.",
                        estimatedMinutes: 8
                    ),
                    urgency: 0.72,
                    evidenceMatch: 0.80,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if runtime.triggerLooksRelational {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .safeDraft,
                        title: "Esboçar a conversa que pesa",
                        detail: "Escreva uma versão curta do que precisa ser dito antes de decidir se envia agora.",
                        strategicReason: "Quando a tensão é relacional, um rascunho seguro costuma baixar o peso sem te jogar no impulso.",
                        estimatedMinutes: 8
                    ),
                    urgency: 0.70,
                    evidenceMatch: 0.84,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if runtime.highStressToday || analysis.indicators.highStressDays >= 2 {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .frictionCleanup,
                        title: "Tirar fricção do ambiente",
                        detail: "Limpe sua área principal e deixe só o que ajuda você a respirar melhor agora.",
                        strategicReason: "Menos ruído visual costuma aliviar pressão corporal e facilitar o próximo passo.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.70,
                    evidenceMatch: 0.80,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if runtime.highEnergyLowMoodConflict {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .physicalDischarge,
                        title: "Descarregar a tensão pelo corpo",
                        detail: "Use essa energia acesa em movimento curto e guiado antes de voltar para qualquer decisão.",
                        strategicReason: "Energia alta com humor ruim costuma virar irritação ou impulsividade se ficar sem direção.",
                        estimatedMinutes: min(max(runtime.availableMinutes, 8), 15)
                    ),
                    urgency: 0.88,
                    evidenceMatch: 0.89,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        if runtime.latestMood?.moodType == .energetic || runtime.latestMood?.moodType == .happy {
            candidates.append(
                candidate(
                    action: NextBestAction(
                        kind: .protectPeakWindow,
                        title: "Aproveitar seu melhor pico",
                        detail: "Escolha uma frente que importa e proteja esse embalo antes que ele se espalhe demais.",
                        strategicReason: "Estado bom tende a render mais quando recebe direção clara cedo.",
                        estimatedMinutes: 10
                    ),
                    urgency: 0.60,
                    evidenceMatch: 0.72,
                    profile: profile,
                    history: history,
                    runtime: runtime
                )
            )
        }

        return candidates
    }

    private func makeRichCandidates(
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary
    ) -> [ActionCandidate] {
        guard runtime.latestMood != nil else { return [] }

        let clusters = BehaviorMoodClusterResolver.resolve(
            latestMood: runtime.latestMood,
            latestAggregate: runtime.latestAggregate,
            analysis: analysis
        )
        guard !clusters.isEmpty else { return [] }

        let valuePriority = inferredValuePriority(profile: profile, area: runtime.areaKey)
        let lastCategory = lastRichCategory(from: history)

        return clusters.flatMap { resolvedCluster in
            let moderators = Moderators(
                tempoMinutos: runtime.availableMinutes,
                energia: runtime.energyToken,
                controle: runtime.controlToken,
                clareza: runtime.clarityToken,
                area: runtime.areaKey,
                riscoAlto: false,
                horario: runtime.referenceDate
            )
            let context = UserContext(
                mood: resolvedCluster.cluster,
                intensity: runtime.latestMood?.intensity ?? 5,
                moderators: moderators,
                valuePriority: valuePriority,
                area: runtime.areaKey,
                blockedTask: nil,
                easyTask: nil,
                helpsHistory: [:],
                lastActionCategory: lastCategory
            )

            return richEngine
                .rankedSuggestions(for: context, limit: 6)
                .map { variant in
                    let action = makeRichAction(
                        variant: variant,
                        cluster: resolvedCluster.cluster,
                        runtime: runtime,
                        analysis: analysis
                    )
                    let evidenceMatch = richEvidenceMatch(
                        variant: variant,
                        cluster: resolvedCluster,
                        runtime: runtime,
                        analysis: analysis
                    )
                    let urgency = richUrgency(
                        variant: variant,
                        cluster: resolvedCluster.cluster,
                        runtime: runtime,
                        analysis: analysis
                    )

                    return ActionCandidate(
                        action: action,
                        urgency: urgency,
                        evidenceMatch: evidenceMatch,
                        contextFit: contextualFit(
                            for: action.kind,
                            profile: profile,
                            hour: runtime.hour,
                            availableMinutes: runtime.availableMinutes,
                            controlLevel: runtime.latestMood?.controlLevel,
                            isInsideCriticalWindow: runtime.isInsideWorstPeriod,
                            areaKey: runtime.areaKey
                        ),
                        adherenceLikelihood: adherenceScore(for: action.kind, history: history)
                    )
                }
        }
    }

    private func makeRichAction(
        variant: ActionVariant,
        cluster: MoodCluster,
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis
    ) -> NextBestAction {
        let kind = mapRichKind(for: variant)
        let strategy = richStrategicReason(
            for: variant,
            cluster: cluster,
            runtime: runtime,
            analysis: analysis
        )

        return NextBestAction(
            actionKey: variant.id.uuidString,
            kind: kind,
            title: variant.title,
            detail: variant.detail,
            strategicReason: strategy,
            estimatedMinutes: variant.duration
        )
    }

    private func richStrategicReason(
        for variant: ActionVariant,
        cluster: MoodCluster,
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis
    ) -> String {
        let whyPool = RichRecommendationEngine.defaultPlaybook[cluster]?.copyWhy ?? []
        let baseReason = whyPool.isEmpty
            ? "Essa ação combina bem com o seu estado atual."
            : whyPool[Int(stableHash64(variant.id.uuidString) % UInt64(whyPool.count))]

        var additions: [String] = []

        if runtime.availableMinutes <= 5 && variant.duration <= 5 {
            additions.append("Ela também cabe no tempo que você disse ter agora.")
        }

        if let areaTag = variant.areaTag {
            switch areaTag {
            case "trabalho":
                additions.append("Ela conversa direto com a parte do seu dia que está pesando mais.")
            case "relacao":
                additions.append("Ela toca justamente a área de vínculo e conversa que tende a ficar sensível nesse estado.")
            default:
                break
            }
        }

        if analysis.indicators.hasSleepImpact && (variant.category == "sono" || variant.category == "respiracao") {
            additions.append("Também ajuda a evitar que o cansaço empurre o resto do dia para baixo.")
        }

        return ([baseReason] + additions).joined(separator: " ")
    }

    private func richEvidenceMatch(
        variant: ActionVariant,
        cluster: ResolvedMoodCluster,
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis
    ) -> Double {
        var score = 0.56 + cluster.confidence * 0.24

        if let area = runtime.areaKey, let tag = variant.areaTag, area == tag {
            score += 0.10
        }
        if runtime.availableMinutes >= variant.duration {
            score += 0.06
        }
        if analysis.indicators.hasSleepImpact && (variant.category == "sono" || variant.category == "respiracao") {
            score += 0.06
        }
        if analysis.indicators.hasEmotionalProcrastination && (variant.category == "organizacao" || variant.category == "behavioral_activation") {
            score += 0.06
        }
        if runtime.triggerLooksRelational && (variant.category == "conexao" || variant.category == "relacionamento") {
            score += 0.06
        }

        return max(0.30, min(0.98, score))
    }

    private func richUrgency(
        variant: ActionVariant,
        cluster: MoodCluster,
        runtime: RecommendationRuntimeContext,
        analysis: BehaviorPatternAnalysis
    ) -> Double {
        var score = 0.52

        if runtime.isInsideWorstPeriod {
            score += 0.08
        }
        if runtime.availableMinutes >= variant.duration {
            score += 0.06
        }
        if runtime.todayPending >= 3 && (variant.category == "organizacao" || variant.category == "behavioral_activation") {
            score += 0.07
        }
        if runtime.highStressToday && (variant.category == "respiracao" || variant.category == "movimento" || variant.category == "grounding") {
            score += 0.07
        }

        switch cluster {
        case .ansioso, .irritado, .estressado:
            if variant.category == "respiracao" || variant.category == "grounding" || variant.category == "dbt" {
                score += 0.10
            }
        case .sobrecarregado:
            if variant.category == "organizacao" || variant.category == "problem_solving" {
                score += 0.10
            }
        case .triste, .desmotivado:
            if variant.category == "behavioral_activation" || variant.category == "conexao" || variant.category == "act_valor" {
                score += 0.08
            }
        case .apatico, .cansadoFisico, .cansadoMental:
            if variant.category == "auto_cuidado" || variant.category == "sono" || variant.category == "manutencao" {
                score += 0.10
            }
        case .calmo, .feliz, .energizado, .focado:
            if variant.category == "behavioral_activation" || variant.category == "organizacao" {
                score += 0.07
            }
        }

        if analysis.indicators.recentDeclineDays >= 2 {
            score += 0.04
        }

        return max(0.30, min(0.96, score))
    }

    private func fallbackCandidate(
        runtime: RecommendationRuntimeContext,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary
    ) -> ActionCandidate {
        if runtime.availableMinutes <= 5 {
            return candidate(
                action: NextBestAction(
                    kind: .breathReset,
                    title: "Respirar e reduzir o ruído",
                    detail: "Faça uma pausa curta para baixar a pressão antes de decidir o próximo passo.",
                    strategicReason: "Quando o tempo é curto, uma ação mínima ainda pode devolver mais clareza para o restante do dia.",
                    estimatedMinutes: 5
                ),
                urgency: 0.60,
                evidenceMatch: 0.54,
                profile: profile,
                history: history,
                runtime: runtime
            )
        }

        switch runtime.currentPeriod {
        case .morning:
            return candidate(
                action: NextBestAction(
                    kind: .paperPlanning,
                    title: "Definir a prioridade de verdade",
                    detail: "Escolha o que mais importa nesta manhã e solte o resto por enquanto.",
                    strategicReason: "Clareza cedo poupa energia para o resto do dia.",
                    estimatedMinutes: 6
                ),
                urgency: 0.58,
                evidenceMatch: 0.50,
                profile: profile,
                history: history,
                runtime: runtime
            )
        case .afternoon:
            return candidate(
                action: NextBestAction(
                    kind: .finishSmallWin,
                    title: "Buscar uma pequena vitória",
                    detail: "Conclua uma pendência curta para recuperar tração no meio do dia.",
                    strategicReason: "Uma vitória simples no meio do caminho costuma devolver senso de avanço.",
                    estimatedMinutes: 10
                ),
                urgency: 0.60,
                evidenceMatch: 0.52,
                profile: profile,
                history: history,
                runtime: runtime
            )
        case .evening:
            return candidate(
                action: NextBestAction(
                    kind: runtime.hour >= 21 ? .sleepReset : .environmentReset,
                    title: runtime.hour >= 21 ? "Começar a desacelerar" : "Dar um reset no espaço",
                    detail: runtime.hour >= 21
                        ? "Proteja seu fechamento do dia antes que o cansaço fique mais pesado."
                        : "Deixe o seu espaço mais leve para o fim do dia não te esmagar junto.",
                    strategicReason: "No fim do dia, menos atrito costuma valer mais do que tentar apertar mais uma tarefa.",
                    estimatedMinutes: 10
                ),
                urgency: 0.64,
                evidenceMatch: 0.50,
                profile: profile,
                history: history,
                runtime: runtime
            )
        case .night:
            return candidate(
                action: NextBestAction(
                    kind: .deepDisconnect,
                    title: "Desligar um pouco antes de dormir",
                    detail: "Fique alguns minutos sem tela nem cobrança para o corpo entender que o dia está fechando.",
                    strategicReason: "Recuperação noturna começa antes de deitar.",
                    estimatedMinutes: 15
                ),
                urgency: 0.62,
                evidenceMatch: 0.50,
                profile: profile,
                history: history,
                runtime: runtime
            )
        }
    }

    private func candidate(
        action: NextBestAction,
        urgency: Double,
        evidenceMatch: Double,
        profile: BehaviorProfileContext,
        history: ActionHistorySummary,
        runtime: RecommendationRuntimeContext
    ) -> ActionCandidate {
        ActionCandidate(
            action: action,
            urgency: urgency,
            evidenceMatch: evidenceMatch,
            contextFit: contextualFit(
                for: action.kind,
                profile: profile,
                hour: runtime.hour,
                availableMinutes: runtime.availableMinutes,
                controlLevel: runtime.latestMood?.controlLevel,
                isInsideCriticalWindow: runtime.isInsideWorstPeriod,
                areaKey: runtime.areaKey
            ),
            adherenceLikelihood: adherenceScore(for: action.kind, history: history)
        )
    }

    private func deduplicatedCandidates(from candidates: [ActionCandidate]) -> [ActionCandidate] {
        var bestByKey: [String: ActionCandidate] = [:]

        for candidate in candidates {
            let key = candidate.action.actionKey
            if let current = bestByKey[key] {
                let currentScore = candidate.urgency + candidate.evidenceMatch + candidate.contextFit + candidate.adherenceLikelihood
                let bestScore = current.urgency + current.evidenceMatch + current.contextFit + current.adherenceLikelihood
                if currentScore > bestScore {
                    bestByKey[key] = candidate
                }
            } else {
                bestByKey[key] = candidate
            }
        }

        return Array(bestByKey.values)
    }

    private func buildAlternatives(
        from rankedActions: [NextBestAction],
        primary: NextBestAction
    ) -> [NextBestAction] {
        var alternatives: [NextBestAction] = []
        var seenKeys: Set<String> = [primary.actionKey]
        var seenKinds: Set<NextBestActionKind> = [primary.kind]

        for action in rankedActions where alternatives.count < 4 {
            guard !seenKeys.contains(action.actionKey) else { continue }

            if !seenKinds.contains(action.kind) || alternatives.count >= 2 {
                alternatives.append(action)
                seenKeys.insert(action.actionKey)
                seenKinds.insert(action.kind)
            }
        }

        return alternatives
    }

    private func finalScore(
        for candidate: ActionCandidate,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> Double {
        let action = candidate.action
        let novelty = noveltyScore(for: action, history: history)
        let cooldownPenalty = cooldownPenalty(for: action, history: history, referenceDate: referenceDate)
        let repetitionPenalty = categoryRepetitionPenalty(for: action.kind.category, history: history)
        let frictionPenalty = frictionPenalty(for: candidate)

        return
            0.32 * candidate.urgency +
            0.26 * candidate.evidenceMatch +
            0.18 * candidate.contextFit +
            0.10 * candidate.adherenceLikelihood +
            0.14 * novelty -
            cooldownPenalty -
            frictionPenalty -
            repetitionPenalty
    }

    private func noveltyScore(for action: NextBestAction, history: ActionHistorySummary) -> Double {
        let exactRecentCount = history.recentSuggestedActionKeys.filter { $0 == action.actionKey }.count
        let kindRecentCount = history.recentSuggestedKinds.filter { $0 == action.kind }.count

        let exactNovelty = max(0, 1.0 - (Double(exactRecentCount) / 3.0))
        let familyNovelty = max(0.10, 1.0 - (Double(kindRecentCount) / 5.0))
        return 0.70 * exactNovelty + 0.30 * familyNovelty
    }

    private func cooldownPenalty(
        for action: NextBestAction,
        history: ActionHistorySummary,
        referenceDate: Date
    ) -> Double {
        if let lastDate = history.lastSuggestedAtByActionKey[action.actionKey] {
            let days = calendar.dateComponents([.day], from: lastDate, to: referenceDate).day ?? 99
            if days <= 0 { return 0.50 }
            if days == 1 { return 0.34 }
            if days == 2 { return 0.16 }
        }

        guard let lastKindDate = history.lastSuggestedAt[action.kind] else { return 0 }
        let days = calendar.dateComponents([.day], from: lastKindDate, to: referenceDate).day ?? 99
        if days <= 0 { return 0.14 }
        if days == 1 { return 0.08 }
        return 0
    }

    private func categoryRepetitionPenalty(
        for category: ActionSuggestionCategory,
        history: ActionHistorySummary
    ) -> Double {
        let count = history.suggestedCategoryCountsLast7Days[category, default: 0]
        if count <= 2 { return 0 }
        if count == 3 { return 0.09 }
        if count == 4 { return 0.16 }
        if count == 5 { return 0.23 }
        if count >= 6 { return 0.30 }
        return 0
    }

    private func frictionPenalty(for candidate: ActionCandidate) -> Double {
        let minutes = candidate.action.estimatedMinutes
        let timePenalty: Double
        switch minutes {
        case ...6:
            timePenalty = 0.01
        case 7...10:
            timePenalty = 0.05
        case 11...16:
            timePenalty = 0.10
        default:
            timePenalty = 0.16
        }

        let contextPenalty = (1.0 - candidate.contextFit) * 0.08
        let adherencePenalty = candidate.adherenceLikelihood < 0.40 ? 0.05 : 0
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
            return 0.64
        }

        switch kind.category {
        case .recovery:
            return 0.68
        case .movement:
            return 0.58
        case .communication:
            return 0.46
        case .planning:
            return 0.56
        case .execution:
            return 0.52
        }
    }

    private func contextualFit(
        for kind: NextBestActionKind,
        profile: BehaviorProfileContext,
        hour: Int,
        availableMinutes: Int,
        controlLevel: MoodControlLevel?,
        isInsideCriticalWindow: Bool,
        areaKey: String?
    ) -> Double {
        var score = 0.5

        switch kind.category {
        case .execution:
            if profile.improvementAreas.contains("foco e produtividade") || profile.improvementAreas.contains("motivacao") {
                score += 0.22
            }
            if isInsideWorkOrStudyWindow(hour: hour, profile: profile) {
                score += 0.10
            }
        case .planning:
            if profile.improvementAreas.contains("foco e produtividade") || profile.improvementAreas.contains("equilibrio de vida") {
                score += 0.18
            }
        case .communication:
            if profile.improvementAreas.contains("relacionamentos") || profile.improvementAreas.contains("comunicacao") {
                score += 0.22
            }
            if profile.emotionalAreas.contains("solidao") || profile.emotionalAreas.contains("inseguranca") {
                score += 0.10
            }
        case .movement:
            if profile.improvementAreas.contains("saude fisica") || profile.interests.contains("atividade fisica") {
                score += 0.20
            }
            if hour >= 7 && hour <= 20 {
                score += 0.08
            }
        case .recovery:
            if profile.improvementAreas.contains("sono") || profile.improvementAreas.contains("ansiedade") || profile.emotionalAreas.contains("estresse") {
                score += 0.18
            }
        }

        switch kind {
        case .sleepReset, .microRest:
            if profile.improvementAreas.contains("sono") || profile.improvementAreas.contains("energia") {
                score += 0.16
            }
            if hour >= 19 {
                score += 0.14
            }
        case .valueReconnect:
            if profile.improvementAreas.contains("motivacao") || profile.emotionalAreas.contains("desanimo") {
                score += 0.12
            }
        case .safeDraft, .supportMessage, .shareGoodMoment:
            if let areaKey, areaKey.contains("relacao") || areaKey.contains("social") || areaKey.contains("famil") {
                score += 0.10
            }
        case .protectPeakWindow, .finishSmallWin, .resolveAvoidedTask:
            if let areaKey, areaKey.contains("trabalho") || areaKey.contains("estudo") || areaKey.contains("disciplina") {
                score += 0.10
            }
        default:
            break
        }

        score += (timeBudgetFit(for: kind, availableMinutes: availableMinutes) - 0.5) * 0.36
        score += (controlFit(for: kind, controlLevel: controlLevel) - 0.5) * 0.28

        if isInsideCriticalWindow && (kind.category == .recovery || kind == .resolveAvoidedTask || kind == .protectPeakWindow) {
            score += 0.07
        }

        return max(0, min(1, score))
    }

    private func timeBudgetFit(for kind: NextBestActionKind, availableMinutes: Int) -> Double {
        let recommended = recommendedMinutes(for: kind)
        if availableMinutes >= recommended {
            return 1.0
        }
        if availableMinutes >= max(5, recommended - 3) {
            return 0.80
        }
        if availableMinutes >= max(3, recommended / 2) {
            return 0.58
        }
        return 0.35
    }

    private func controlFit(for kind: NextBestActionKind, controlLevel: MoodControlLevel?) -> Double {
        guard let controlLevel else { return 0.62 }

        switch controlLevel {
        case .low:
            switch kind.category {
            case .recovery:
                return 0.88
            case .movement:
                return 0.66
            case .planning:
                return 0.52
            case .communication:
                return 0.40
            case .execution:
                return 0.44
            }
        case .medium:
            return 0.72
        case .high:
            switch kind.category {
            case .execution, .planning:
                return 0.90
            case .communication:
                return 0.82
            case .movement:
                return 0.78
            case .recovery:
                return 0.74
            }
        }
    }

    private func recommendedMinutes(for kind: NextBestActionKind) -> Int {
        switch kind {
        case .breathReset, .sensoryPause, .sceneShift, .hydrationReset, .bodyScan:
            return 5
        case .microRest, .supportMessage, .shareGoodMoment, .gratitudeMoment:
            return 6
        case .firstStepActivation, .mentalUnload, .scopeReduction, .taskBreakdown, .delegateOneThing, .finishSmallWin, .safeDraft, .pleasureBoost, .celebrationBreak:
            return 8
        case .resolveAvoidedTask, .paperPlanning, .protectPeakWindow, .frictionCleanup, .sleepReset, .environmentReset, .mechanicalCare, .quickExercise, .walkingRegulation, .softStretch, .difficultMessage, .deepDisconnect, .valueReconnect:
            return 10
        case .solveOneProblem, .timerSprint, .coolDownReset, .analogReset, .physicalDischarge, .weeklyPlanning:
            return 12
        }
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

    private func deterministicVariation(for actionKey: String, dayKey: Date) -> Double {
        let seed = Int(dayKey.timeIntervalSince1970)
        let hash = stableHash64("\(seed)|\(actionKey)")
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

    private func mapRichKind(for variant: ActionVariant) -> NextBestActionKind {
        let title = BehaviorMoodScorer.normalize(variant.title)
        let category = BehaviorMoodScorer.normalize(variant.category)

        switch category {
        case "respiracao":
            return .breathReset
        case "organizacao":
            if title.contains("brain dump") || title.contains("anotar o que drena") || title.contains("nomear o que esta") {
                return .mentalUnload
            }
            if title.contains("remova") || title.contains("sai da lista") || title.contains("a/b/c") || title.contains("prioridades") {
                return .scopeReduction
            }
            if title.contains("dividir") || title.contains("3 passos") {
                return .taskBreakdown
            }
            if title.contains("delegar") {
                return .delegateOneThing
            }
            if title.contains("papel") || title.contains("planejar") || title.contains("revisao") || title.contains("proxima hora") {
                return .paperPlanning
            }
            if title.contains("proteger") || title.contains("janela") || title.contains("blindar") {
                return .protectPeakWindow
            }
            if title.contains("limpar") || title.contains("distra") || title.contains("pressoes") {
                return .frictionCleanup
            }
            if title.contains("primeiro") || title.contains("setup") || title.contains("tijolo") {
                return .firstStepActivation
            }
            return .weeklyPlanning
        case "problem_solving":
            return title.contains("delegar") ? .delegateOneThing : .solveOneProblem
        case "movimento":
            if title.contains("along") {
                return .softStretch
            }
            if title.contains("descarga") || title.contains("vigor") {
                return .physicalDischarge
            }
            if title.contains("caminh") || title.contains("passeio") {
                return .walkingRegulation
            }
            return .quickExercise
        case "grounding":
            if title.contains("cena") {
                return .sceneShift
            }
            if title.contains("sem telas") || title.contains("analog") {
                return .analogReset
            }
            return .sensoryPause
        case "dbt", "distress_tolerance":
            return .coolDownReset
        case "relacionamento":
            return title.contains("rascunho") ? .safeDraft : .difficultMessage
        case "conexao":
            return title.contains("coisa boa") || title.contains("encontro") ? .shareGoodMoment : .supportMessage
        case "auto_cuidado":
            if title.contains("agua") || title.contains("hidr") || title.contains("checagem") {
                return .hydrationReset
            }
            if title.contains("musica") {
                return .pleasureBoost
            }
            if title.contains("sono") || title.contains("noite") {
                return .sleepReset
            }
            if title.contains("mecanico") || title.contains("autocuidado") {
                return .mechanicalCare
            }
            return .deepDisconnect
        case "behavioral_activation":
            if title.contains("celebra") {
                return .celebrationBreak
            }
            if title.contains("sprint") {
                return .timerSprint
            }
            if title.contains("finalizar") || title.contains("fechar") {
                return .finishSmallWin
            }
            if title.contains("impulso") || title.contains("primeiro") {
                return .firstStepActivation
            }
            return .resolveAvoidedTask
        case "act_valor":
            return .valueReconnect
        case "manutencao":
            if title.contains("lavadora") || title.contains("lixo") || title.contains("mecanico") {
                return .mechanicalCare
            }
            return .environmentReset
        case "sono":
            return title.contains("microdescanso") || title.contains("soneca") ? .microRest : .sleepReset
        case "motivacao":
            return .celebrationBreak
        case "gratidao":
            return .gratitudeMoment
        default:
            return .deepDisconnect
        }
    }

    private func inferredValuePriority(profile: BehaviorProfileContext, area: String?) -> String? {
        if let area, area.contains("relacao") || area.contains("social") || area.contains("famil") {
            return "conexao"
        }
        if profile.emotionalAreas.contains("solidao") || profile.improvementAreas.contains("relacionamentos") {
            return "conexao"
        }
        return nil
    }

    private func lastRichCategory(from history: ActionHistorySummary) -> String? {
        guard let lastKind = history.recentSuggestedKinds.last else { return nil }
        switch lastKind.category {
        case .execution:
            return "behavioral_activation"
        case .planning:
            return "organizacao"
        case .communication:
            return "conexao"
        case .movement:
            return "movimento"
        case .recovery:
            return "respiracao"
        }
    }
}

private struct RecommendationRuntimeContext {
    let calendar: Calendar
    let latestMood: BehaviorMoodEvent?
    let latestAggregate: BehaviorDailyAggregate?
    let analysis: BehaviorPatternAnalysis
    let profile: BehaviorProfileContext
    let referenceDate: Date

    let hour: Int
    let dayKey: Date
    let currentPeriod: BehaviorDayPeriod
    let todayPending: Int
    let lowClarityToday: Bool
    let highStressToday: Bool
    let isInsideWorstPeriod: Bool
    let availableMinutes: Int
    let areaKey: String?
    let sleepFragile: Bool
    let highEnergyLowMoodConflict: Bool
    let triggerLooksRelational: Bool
    let energyToken: String?
    let controlToken: String?
    let clarityToken: String?

    init(
        calendar: Calendar,
        latestMood: BehaviorMoodEvent?,
        latestAggregate: BehaviorDailyAggregate?,
        analysis: BehaviorPatternAnalysis,
        profile: BehaviorProfileContext,
        referenceDate: Date
    ) {
        self.calendar = calendar
        self.latestMood = latestMood
        self.latestAggregate = latestAggregate
        self.analysis = analysis
        self.profile = profile
        self.referenceDate = referenceDate

        let resolvedHour = calendar.component(.hour, from: referenceDate)
        let resolvedDayKey = calendar.startOfDay(for: referenceDate)
        let resolvedCurrentPeriod = Self.dayPeriod(for: resolvedHour)

        hour = resolvedHour
        dayKey = resolvedDayKey
        currentPeriod = resolvedCurrentPeriod
        todayPending = max(0, (latestAggregate?.todoTotal ?? 0) - (latestAggregate?.todoCompleted ?? 0))
        lowClarityToday = (latestAggregate?.averageClarity ?? Double(latestMood?.mentalClarity ?? 7)) <= 4.0
        highStressToday = (latestAggregate?.stressSignalTotal ?? 0) > 0 || (latestMood?.stressSignalCount ?? 0) > 0
        isInsideWorstPeriod = analysis.indicators.worstPeriod.map { $0 == resolvedCurrentPeriod } ?? false
        availableMinutes = latestMood?.availableTime?.maxMinutes ?? 12
        areaKey = latestMood?.affectedArea
        sleepFragile = latestMood?.sleepQuality == .poor || latestMood?.sleepQuality == .fair
        highEnergyLowMoodConflict = latestMood?.energyLevel == .high && (latestMood?.moodScore ?? 0) <= -0.35

        let dominantTrigger = analysis.indicators.dominantNegativeTrigger ?? latestMood?.triggers.first ?? ""
        triggerLooksRelational = dominantTrigger.contains("relacion")
            || dominantTrigger.contains("famil")
            || dominantTrigger.contains("social")
            || dominantTrigger.contains("conflit")

        energyToken = latestMood?.energyLevel.map { level in
            switch level {
            case .low: return "baixa"
            case .medium: return "media"
            case .high: return "alta"
            }
        }
        controlToken = latestMood?.controlLevel.map { level in
            switch level {
            case .low: return "baixo"
            case .medium: return "medio"
            case .high: return "alto"
            }
        }
        clarityToken = latestMood?.mentalClarity.map { clarity in
            if clarity <= 3 { return "baixa" }
            if clarity <= 7 { return "media" }
            return "alta"
        }
    }

    private static func dayPeriod(for hour: Int) -> BehaviorDayPeriod {
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
