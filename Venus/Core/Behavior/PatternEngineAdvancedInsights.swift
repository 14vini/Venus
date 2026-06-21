//
//  PatternEngineAdvancedInsights.swift
//  Venus
//
//  Created by Kaua on 22/02/26.
//

import Foundation

struct BehaviorActivityBlueprint: Sendable {
    let title: String
    let description: String
    let categoryDisplayName: String
    let categoryNormalized: String
    let durationMinutes: Int
    let iconName: String
    let targetMoodKeys: [String]
    let semanticBag: String
    let titleNormalized: String
    let descriptionNormalized: String
}

extension PatternEngineUseCase {
    static func buildConfidenceInsight(
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights,
        aggregates: [BehaviorDailyAggregate],
        actionHistory: ActionHistorySummary,
        profile: BehaviorProfileContext
    ) -> ConfidenceImprovementInsight {
        let recentWindow = Array(aggregates.suffix(14))
        let checkInConsistency = ratio(
            recentWindow.filter { $0.moodEntries > 0 }.count,
            recentWindow.count
        )
        let actionStartDays = recentWindow.filter { !$0.actionStartedByKind.isEmpty }.count
        let actionExecutionConsistency = ratio(actionStartDays, max(1, recentWindow.filter { $0.moodEntries > 0 }.count))
        let averageCompletionRate = average(actionHistory.completionRateByKind.values) ?? 0.55
        let trendBoost = trendBoost(for: analysis.weeklyTrend.direction)
        let profileBoost = profileConfidenceBoost(from: profile)

        let currentConfidence = clamp(
            0.25 +
            0.28 * checkInConsistency +
            0.21 * actionExecutionConsistency +
            0.17 * weeklyInsights.streakQualityScore +
            0.16 * averageCompletionRate +
            0.10 * weeklyInsights.leverageScore +
            trendBoost +
            profileBoost,
            min: 0.18,
            max: 0.90
        )

        let adaptationReserve = max(0.06, (1.0 - currentConfidence) * 0.46)
        let gain7Days = clamp(
            min(
                adaptationReserve,
                0.04 +
                0.10 * weeklyInsights.leverageScore +
                0.07 * weeklyInsights.streakQualityScore +
                0.05 * averageCompletionRate +
                max(0, trendBoost)
            ),
            min: 0.03,
            max: 0.22
        )
        let gain14Days = clamp(
            gain7Days * 1.62 + 0.04 * weeklyInsights.streakQualityScore,
            min: gain7Days + 0.02,
            max: 0.34
        )

        let projectedConfidence7Days = clamp(currentConfidence + gain7Days, min: 0.20, max: 0.95)
        let projectedConfidence14Days = clamp(currentConfidence + gain14Days, min: 0.22, max: 0.97)

        let keyLevers = confidenceLevers(
            analysis: analysis,
            weeklyInsights: weeklyInsights,
            checkInConsistency: checkInConsistency,
            actionExecutionConsistency: actionExecutionConsistency,
            profile: profile
        )

        let summary = """
        Mantendo check-in diário e 1 ação guiada por dia, sua autoconfiança tende a subir de \
        \(percent(currentConfidence)) para \(percent(projectedConfidence14Days)) em até 14 dias.
        """

        return ConfidenceImprovementInsight(
            currentConfidence: currentConfidence,
            projectedConfidence7Days: projectedConfidence7Days,
            projectedConfidence14Days: projectedConfidence14Days,
            confidenceGain7Days: projectedConfidence7Days - currentConfidence,
            confidenceGain14Days: projectedConfidence14Days - currentConfidence,
            keyLevers: keyLevers,
            personalizedSummary: summary
        )
    }

    static func buildTriggerRecoveryInsight(
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights,
        confidenceInsight: ConfidenceImprovementInsight?,
        latestMood: BehaviorMoodEvent?,
        nextAction: NextBestAction,
        proForecast: ProMoodForecast?,
        profile: BehaviorProfileContext,
        referenceDate: Date,
        plan: VenusPlan
    ) -> TriggerRecoveryInsight {
        let triggerName = weeklyInsights.dominantTrigger
            ?? analysis.indicators.dominantNegativeTrigger?.capitalized
            ?? "Sobrecarga mental"
        let confidenceGain = confidenceInsight?.confidenceGain7Days ?? 0.08
        let pressureIndex = triggerPressureIndex(analysis: analysis, latestMood: latestMood)

        let highlightedProjection: [TriggerRecoveryPoint] = [1, 3, 7].map { dayOffset in
            let progressFactor = log(Double(dayOffset) + 1) / log(8)
            var withoutAction = clamp(
                0.54 - pressureIndex * 0.36 + progressFactor * 0.08,
                min: 0.12,
                max: 0.82
            )
            var withAction = clamp(
                withoutAction + 0.05 + weeklyInsights.leverageScore * 0.16 * progressFactor + confidenceGain * 0.32,
                min: 0.16,
                max: 0.95
            )

            if let point = proForecast?.points.first(where: { $0.dayOffset == dayOffset }) {
                let noActionNormalized = normalizeMoodScore(point.projectedScore)
                let withActionNormalized = normalizeMoodScore(point.projectedScoreWithAction)
                withoutAction = 0.55 * withoutAction + 0.45 * noActionNormalized
                withAction = 0.55 * withAction + 0.45 * withActionNormalized
            }

            return TriggerRecoveryPoint(
                dayOffset: dayOffset,
                scoreWithoutAction: clamp(withoutAction, min: 0.10, max: 0.90),
                scoreWithAction: clamp(withAction, min: 0.14, max: 0.97)
            )
        }

        let allAreaProjections = buildTriggerAreaProjections(
            profile: profile,
            analysis: analysis,
            weeklyInsights: weeklyInsights,
            confidenceGain: confidenceGain,
            triggerName: triggerName,
            referenceDate: referenceDate
        )
        let visibleAreas = plan == .pro ? allAreaProjections : []
        let lockedCount = plan == .pro ? 0 : allAreaProjections.count

        let day7Delta = highlightedProjection
            .first(where: { $0.dayOffset == 7 })?
            .delta ?? 0
        let highlightedSummary = """
        Para o gatilho “\(triggerName)”, executar \(nextAction.title.lowercased()) agora tende a elevar \
        sua recuperação em \(percent(day7Delta)) até o dia 7.
        """

        return TriggerRecoveryInsight(
            highlightedTrigger: triggerName,
            highlightedSummary: highlightedSummary,
            highlightedProjection: highlightedProjection,
            additionalAreaProjections: visibleAreas,
            lockedAdditionalAreasCount: lockedCount
        )
    }

    static func buildExploreActionSuggestions(
        activities: [BehaviorActivityBlueprint],
        analysis: BehaviorPatternAnalysis,
        nextAction: NextBestAction,
        latestMood: BehaviorMoodEvent?,
        profile: BehaviorProfileContext,
        actionHistory: ActionHistorySummary,
        referenceDate: Date
    ) -> [ExploreActionSuggestion] {
        guard !activities.isEmpty else { return [] }

        let preferredCategories = preferredActivityCategories(
            for: nextAction.kind,
            analysis: analysis,
            latestMood: latestMood
        )
        let moodKey = latestMood.map { BehaviorMoodScorer.normalize($0.moodType.rawValue) }
        let availableMinutes = latestMood?.availableTime?.maxMinutes ?? 12
        let profileTokens = profile.improvementAreas
            .union(profile.emotionalAreas)
            .union(profile.interests)

        let ranked = activities.map { activity -> (BehaviorActivityBlueprint, Double, String) in
            let moodFit = scoreMoodFit(activity: activity, moodKey: moodKey)
            let timeFit = scoreTimeFit(activityMinutes: activity.durationMinutes, availableMinutes: availableMinutes)
            let categoryFit = preferredCategories[activity.categoryNormalized, default: 0.48]
            let signalFit = scoreSignalFit(activity: activity, analysis: analysis, latestMood: latestMood)
            let profileFit = scoreProfileFit(activity: activity, profileTokens: profileTokens)
            let repetitionPenalty = categoryRepetitionPenalty(
                categoryNormalized: activity.categoryNormalized,
                history: actionHistory
            )

            let score = clamp(
                0.24 * moodFit +
                0.20 * timeFit +
                0.22 * categoryFit +
                0.19 * signalFit +
                0.15 * profileFit -
                repetitionPenalty,
                min: 0.05,
                max: 0.99
            )
            let reason = buildSuggestionReason(
                moodFit: moodFit,
                timeFit: timeFit,
                categoryFit: categoryFit,
                signalFit: signalFit,
                profileFit: profileFit,
                nextAction: nextAction
            )

            return (activity, score, reason)
        }
        .sorted { lhs, rhs in
            if abs(lhs.1 - rhs.1) <= 0.0001 {
                let lhsSeed = stableUnitValue(seed: "\(lhs.0.titleNormalized)|\(referenceDate)")
                let rhsSeed = stableUnitValue(seed: "\(rhs.0.titleNormalized)|\(referenceDate)")
                return lhsSeed > rhsSeed
            }
            return lhs.1 > rhs.1
        }

        return ranked
            .prefix(6)
            .map { activity, score, reason in
                ExploreActionSuggestion(
                    activityTitle: activity.title,
                    activityDescription: activity.description,
                    activityCategory: activity.categoryDisplayName,
                    durationMinutes: activity.durationMinutes,
                    iconName: activity.iconName,
                    matchScore: score,
                    recommendationReason: reason
                )
            }
    }

    private static func preferredActivityCategories(
        for actionKind: NextBestActionKind,
        analysis: BehaviorPatternAnalysis,
        latestMood: BehaviorMoodEvent?
    ) -> [String: Double] {
        var weights: [String: Double]
        switch actionKind.category {
        case .execution:
            weights = ["foco": 0.95, "criatividade": 0.72, "relaxamento": 0.54]
        case .planning:
            weights = ["foco": 0.96, "criatividade": 0.76, "relaxamento": 0.56]
        case .communication:
            weights = ["social": 0.95, "relaxamento": 0.66]
        case .movement:
            weights = ["fisico": 0.98, "relaxamento": 0.60]
        case .recovery:
            weights = ["relaxamento": 0.98, "fisico": 0.58, "criatividade": 0.62]
        }

        if analysis.indicators.hasSleepImpact {
            weights["relaxamento"] = max(weights["relaxamento", default: 0.55], 0.92)
        }
        if analysis.indicators.hasEmotionalProcrastination {
            weights["foco"] = max(weights["foco", default: 0.55], 0.88)
        }
        if analysis.indicators.highStressDays >= 2 {
            weights["relaxamento"] = max(weights["relaxamento", default: 0.55], 0.90)
        }
        if latestMood?.moodType == .tired {
            weights["fisico"] = max(weights["fisico", default: 0.50], 0.72)
        }

        for key in ["relaxamento", "foco", "criatividade", "fisico", "social"] {
            weights[key] = weights[key, default: 0.44]
        }
        return weights
    }

    private static func scoreMoodFit(activity: BehaviorActivityBlueprint, moodKey: String?) -> Double {
        guard let moodKey else { return 0.58 }
        if activity.targetMoodKeys.isEmpty { return 0.60 }
        if activity.targetMoodKeys.contains(moodKey) { return 1.0 }
        return 0.34
    }

    private static func scoreTimeFit(activityMinutes: Int, availableMinutes: Int) -> Double {
        if activityMinutes <= availableMinutes {
            return 1.0
        }
        if activityMinutes <= availableMinutes + 5 {
            return 0.78
        }
        if activityMinutes <= availableMinutes + 15 {
            return 0.55
        }
        return 0.30
    }

    private static func scoreSignalFit(
        activity: BehaviorActivityBlueprint,
        analysis: BehaviorPatternAnalysis,
        latestMood: BehaviorMoodEvent?
    ) -> Double {
        var score = 0.48
        let category = activity.categoryNormalized

        if analysis.indicators.hasSleepImpact, category == "relaxamento" {
            score += 0.34
        }
        if analysis.indicators.hasEmotionalProcrastination, category == "foco" {
            score += 0.30
        }
        if analysis.indicators.highStressDays >= 2, category == "relaxamento" || category == "fisico" {
            score += 0.22
        }
        if let dominantTrigger = analysis.indicators.dominantNegativeTrigger,
           (dominantTrigger.contains("relacion") || dominantTrigger.contains("familia")),
           category == "social" {
            score += 0.26
        }
        if latestMood?.moodType == .sad, category == "social" || category == "relaxamento" {
            score += 0.16
        }
        if latestMood?.moodType == .energetic, category == "fisico" || category == "foco" {
            score += 0.16
        }

        return clamp(score, min: 0.15, max: 1.0)
    }

    private static func scoreProfileFit(
        activity: BehaviorActivityBlueprint,
        profileTokens: Set<String>
    ) -> Double {
        guard !profileTokens.isEmpty else { return 0.58 }

        let hits = profileTokens.filter { token in
            activity.semanticBag.contains(token)
        }.count

        var score = 0.50
        if hits > 0 {
            score += min(0.40, Double(hits) * 0.14)
        }

        if profileTokens.contains("atividade fisica"), activity.categoryNormalized == "fisico" {
            score += 0.16
        }
        if profileTokens.contains("foco e produtividade"), activity.categoryNormalized == "foco" {
            score += 0.16
        }
        if profileTokens.contains("ansiedade"), activity.categoryNormalized == "relaxamento" {
            score += 0.14
        }
        if profileTokens.contains("relacionamentos"), activity.categoryNormalized == "social" {
            score += 0.14
        }

        return clamp(score, min: 0.22, max: 1.0)
    }

    private static func categoryRepetitionPenalty(
        categoryNormalized: String,
        history: ActionHistorySummary
    ) -> Double {
        let mappedCategory: ActionSuggestionCategory?
        switch categoryNormalized {
        case "foco":
            mappedCategory = .execution
        case "relaxamento":
            mappedCategory = .recovery
        case "fisico":
            mappedCategory = .movement
        case "social":
            mappedCategory = .communication
        case "criatividade":
            mappedCategory = .planning
        default:
            mappedCategory = nil
        }

        guard let mappedCategory else { return 0 }
        let count = history.suggestedCategoryCountsLast7Days[mappedCategory, default: 0]
        if count <= 2 { return 0 }
        if count == 3 { return 0.05 }
        if count == 4 { return 0.08 }
        if count >= 5 { return 0.11 }
        return 0
    }

    private static func buildSuggestionReason(
        moodFit: Double,
        timeFit: Double,
        categoryFit: Double,
        signalFit: Double,
        profileFit: Double,
        nextAction: NextBestAction
    ) -> String {
        let strongest = [
            ("humor", moodFit),
            ("tempo", timeFit),
            ("categoria", categoryFit),
            ("padrão", signalFit),
            ("perfil", profileFit)
        ]
        .max(by: { $0.1 < $1.1 })?.0

        switch strongest {
        case "humor":
            return "Combina com seu estado emocional atual e facilita aderência imediata."
        case "tempo":
            return "Cabe no seu tempo disponível agora, reduzindo fricção para começar."
        case "categoria":
            return "Reforça sua ação principal de hoje: \(nextAction.title.lowercased())."
        case "perfil":
            return "Está alinhada com seu perfil e com as áreas que você quer evoluir."
        default:
            return "Ataca o padrão emocional mais relevante detectado nesta semana."
        }
    }

    private static func buildTriggerAreaProjections(
        profile: BehaviorProfileContext,
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights,
        confidenceGain: Double,
        triggerName: String,
        referenceDate: Date
    ) -> [TriggerAreaProjection] {
        let normalizedTrigger = BehaviorMoodScorer.normalize(triggerName)
        let catalog = areaCatalog(from: profile)

        return catalog
            .filter { !$0.normalizedKey.contains(normalizedTrigger) }
            .map { area in
                let seeded = stableUnitValue(seed: "\(area.normalizedKey)|\(referenceDate)")
                let areaAffinity = affinityForArea(area.normalizedKey, analysis: analysis)
                let day3 = clamp(
                    0.04 +
                    0.08 * weeklyInsights.leverageScore +
                    0.06 * confidenceGain +
                    areaAffinity +
                    seeded * 0.03,
                    min: 0.03,
                    max: 0.24
                )
                let day7 = clamp(
                    day3 * 1.62 + weeklyInsights.streakQualityScore * 0.06,
                    min: day3 + 0.02,
                    max: 0.42
                )
                let confidence = clamp(
                    0.42 +
                    0.34 * weeklyInsights.confidence +
                    0.12 * (1.0 - min(1.0, Double(analysis.indicators.recentDeclineDays) / 4.0)) +
                    seeded * 0.10,
                    min: 0.35,
                    max: 0.91
                )

                return TriggerAreaProjection(
                    area: area.displayName,
                    day3Delta: day3,
                    day7Delta: day7,
                    confidence: confidence
                )
            }
            .sorted { lhs, rhs in
                if abs(lhs.day7Delta - rhs.day7Delta) < 0.0001 {
                    return lhs.area < rhs.area
                }
                return lhs.day7Delta > rhs.day7Delta
            }
            .prefix(5)
            .map { $0 }
    }

    private static func areaCatalog(from profile: BehaviorProfileContext) -> [(normalizedKey: String, displayName: String)] {
        let defaults = [
            "sono",
            "foco e produtividade",
            "energia",
            "ansiedade",
            "autoconfianca",
            "estresse",
            "relacionamentos",
            "equilibrio de vida"
        ]

        let source = Array(profile.improvementAreas) + Array(profile.emotionalAreas) + defaults
        var seen = Set<String>()
        var result: [(String, String)] = []

        for raw in source {
            let normalized = BehaviorMoodScorer.normalize(raw)
            guard !normalized.isEmpty else { continue }
            guard !seen.contains(normalized) else { continue }
            seen.insert(normalized)
            result.append((normalized, displayName(forArea: normalized)))
        }

        return result
    }

    private static func displayName(forArea normalized: String) -> String {
        switch normalized {
        case "autoconfianca":
            return "Autoconfiança"
        case "foco e produtividade":
            return "Foco e produtividade"
        case "equilibrio de vida":
            return "Equilíbrio de vida"
        case "saude fisica":
            return "Saúde física"
        case "relacionamentos":
            return "Relacionamentos"
        case "ansiedade":
            return "Ansiedade"
        case "estresse":
            return "Estresse"
        case "sono":
            return "Sono"
        case "energia":
            return "Energia"
        default:
            return normalized
                .split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }
    }

    private static func affinityForArea(
        _ areaKey: String,
        analysis: BehaviorPatternAnalysis
    ) -> Double {
        if areaKey.contains("sono"), analysis.indicators.hasSleepImpact {
            return 0.09
        }
        if areaKey.contains("foco"), analysis.indicators.hasEmotionalProcrastination {
            return 0.08
        }
        if areaKey.contains("estresse") || areaKey.contains("ansiedade"),
           analysis.indicators.highStressDays >= 2 {
            return 0.08
        }
        if areaKey.contains("autoconfianca") {
            return 0.07
        }
        return 0.04
    }

    private static func triggerPressureIndex(
        analysis: BehaviorPatternAnalysis,
        latestMood: BehaviorMoodEvent?
    ) -> Double {
        var pressure = 0.44

        if analysis.weeklyTrend.direction == .declining {
            pressure += 0.14
        } else if analysis.weeklyTrend.direction == .stable {
            pressure += 0.05
        }

        pressure += min(0.14, Double(analysis.indicators.recentDeclineDays) * 0.04)
        pressure += min(0.12, Double(analysis.indicators.highStressDays) * 0.03)

        if let latestMood {
            if latestMood.moodScore <= -0.75 { pressure += 0.12 }
            if latestMood.controlLevel == .low { pressure += 0.08 }
            if latestMood.energyLevel == .low { pressure += 0.06 }
        }

        return clamp(pressure, min: 0.20, max: 0.92)
    }

    private static func confidenceLevers(
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights,
        checkInConsistency: Double,
        actionExecutionConsistency: Double,
        profile: BehaviorProfileContext
    ) -> [String] {
        var levers: [String] = []

        if checkInConsistency < 0.72 {
            levers.append("Manter check-in diário por 7 dias para estabilizar percepção emocional.")
        }
        if actionExecutionConsistency < 0.62 {
            levers.append("Executar uma microação por dia para fortalecer sensação de progresso.")
        }
        if analysis.indicators.hasSleepImpact {
            levers.append("Proteger o sono por 2 noites seguidas para reduzir reatividade emocional.")
        }
        if analysis.indicators.hasEmotionalProcrastination {
            levers.append("Fechar uma tarefa evitada antes das 17h para reduzir autocobrança.")
        }
        if let trigger = weeklyInsights.dominantTrigger {
            levers.append("Antecipar o gatilho “\(trigger)” com ação preventiva curta.")
        }

        if profile.emotionalAreas.contains("inseguranca") || profile.improvementAreas.contains("autoconfianca") {
            levers.append("Registrar 1 evidência de competência por dia para reforçar autoconfiança.")
        }

        if levers.isEmpty {
            levers = [
                "Manter check-in diário para reduzir decisões no modo automático.",
                "Concluir uma ação guiada curta por dia para consolidar consistência emocional."
            ]
        }

        return Array(levers.prefix(4))
    }

    private static func profileConfidenceBoost(from profile: BehaviorProfileContext) -> Double {
        var boost = 0.0
        if profile.improvementAreas.contains("autoconfianca") { boost += 0.03 }
        if profile.emotionalAreas.contains("inseguranca") { boost += 0.02 }
        if profile.improvementAreas.contains("foco e produtividade") { boost += 0.01 }
        return min(0.05, boost)
    }

    private static func trendBoost(for direction: WeeklyTrendDirection) -> Double {
        switch direction {
        case .improving:
            return 0.06
        case .stable:
            return 0.02
        case .declining:
            return -0.05
        }
    }

    private static func normalizeMoodScore(_ score: Double) -> Double {
        clamp((score + 1.8) / 3.2, min: 0.0, max: 1.0)
    }

    private static func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        guard denominator > 0 else { return 0 }
        return Double(numerator) / Double(denominator)
    }

    private static func average<C: Collection>(_ values: C) -> Double? where C.Element == Double {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func stableUnitValue(seed: String) -> Double {
        let hash = stableHash64(seed)
        return Double(hash % 10_000) / 10_000.0
    }

    private static func stableHash64(_ value: String) -> UInt64 {
        let bytes = value.utf8
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in bytes {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return hash
    }

    private static func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
