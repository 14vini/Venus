//
//  BehaviorMoodClusterResolver.swift
//  Venus
//
//  Created by Kaua on 18/03/26.
//

import Foundation

struct ResolvedMoodCluster: Equatable, Sendable {
    let cluster: MoodCluster
    let confidence: Double
}

enum BehaviorMoodClusterResolver {
    static func resolve(
        latestMood: BehaviorMoodEvent?,
        latestAggregate: BehaviorDailyAggregate?,
        analysis: BehaviorPatternAnalysis
    ) -> [ResolvedMoodCluster] {
        guard let latestMood else { return [] }

        let dominantTrigger = analysis.indicators.dominantNegativeTrigger ?? latestMood.triggers.first ?? ""
        let affectedArea = latestMood.affectedArea ?? ""
        let pendingTasks = max(0, (latestAggregate?.todoTotal ?? 0) - (latestAggregate?.todoCompleted ?? 0))
        let clarityBaseline = latestAggregate?.averageClarity ?? Double(latestMood.mentalClarity ?? 7)
        let lowClarity = clarityBaseline <= 4.5
        let controlLow = latestMood.controlLevel == .low
        let energyLow = latestMood.energyLevel == .low
        let energyHigh = latestMood.energyLevel == .high
        let sleepFragile = latestMood.sleepQuality == .poor || latestMood.sleepQuality == .fair
        let intensity = latestMood.intensity

        var scores: [MoodCluster: Double] = [:]

        func bump(_ cluster: MoodCluster, _ amount: Double) {
            scores[cluster, default: 0] += amount
        }

        switch latestMood.moodType {
        case .stressed:
            bump(.estressado, 1.0)
            if controlLow || intensity >= 8 {
                bump(.ansioso, 0.72)
            }
            if pendingTasks >= 3 || lowClarity || areaLooksLikeWork(affectedArea) {
                bump(.sobrecarregado, 0.78)
            }
            if triggerLooksRelational(dominantTrigger) || (energyHigh && intensity >= 7) {
                bump(.irritado, 0.70)
            }
        case .sad:
            bump(.triste, 1.0)
            if energyLow && controlLow && lowClarity {
                bump(.apatico, 0.82)
            }
            if areaLooksLikeWork(affectedArea) || analysis.indicators.hasEmotionalProcrastination {
                bump(.desmotivado, 0.76)
            }
        case .tired:
            bump(.cansadoFisico, sleepFragile || energyLow ? 1.0 : 0.76)
            if lowClarity || analysis.indicators.highStressDays >= 2 || latestMood.stressSignalCount >= 2 {
                bump(.cansadoMental, 0.86)
            }
        case .calm:
            bump(.calmo, 0.84)
            if !lowClarity && (latestMood.controlLevel == .high || areaLooksLikeWork(affectedArea)) {
                bump(.focado, 0.92)
            }
        case .happy:
            bump(.feliz, 0.90)
            if energyHigh {
                bump(.energizado, 0.68)
            }
            if !lowClarity && areaLooksLikeWork(affectedArea) {
                bump(.focado, 0.64)
            }
        case .energetic:
            bump(.energizado, 1.0)
            if !lowClarity || areaLooksLikeWork(affectedArea) {
                bump(.focado, 0.82)
            }
        }

        if analysis.indicators.hasSleepImpact {
            bump(.cansadoFisico, 0.28)
            bump(.cansadoMental, 0.24)
        }
        if analysis.indicators.hasEmotionalProcrastination {
            bump(.desmotivado, 0.24)
            bump(.sobrecarregado, 0.18)
        }
        if analysis.indicators.highStressDays >= 2 {
            bump(.estressado, 0.26)
            bump(.sobrecarregado, 0.20)
        }
        if let worstPeriod = analysis.indicators.worstPeriod, latestMood.dayPeriod == worstPeriod {
            switch latestMood.moodType {
            case .stressed:
                bump(.ansioso, 0.12)
                bump(.sobrecarregado, 0.12)
            case .sad:
                bump(.triste, 0.10)
                bump(.desmotivado, 0.10)
            case .tired:
                bump(.cansadoMental, 0.10)
            case .calm:
                bump(.calmo, 0.08)
            case .happy:
                bump(.feliz, 0.08)
            case .energetic:
                bump(.energizado, 0.08)
            }
        }

        let ranked = scores
            .filter { $0.value > 0.15 }
            .sorted { lhs, rhs in
                if abs(lhs.value - rhs.value) < 0.0001 {
                    return lhs.key.rawValue < rhs.key.rawValue
                }
                return lhs.value > rhs.value
            }

        guard let topScore = ranked.first?.value else {
            return [ResolvedMoodCluster(cluster: latestMood.moodType.cluster, confidence: 0.55)]
        }

        return ranked
            .prefix(3)
            .filter { $0.value >= topScore - 0.32 }
            .map { entry in
                ResolvedMoodCluster(
                    cluster: entry.key,
                    confidence: max(0.36, min(0.96, entry.value / max(1.0, topScore)))
                )
            }
    }

    private static func areaLooksLikeWork(_ area: String) -> Bool {
        area.contains("trabalho") || area.contains("estudo") || area.contains("disciplina") || area.contains("finan")
    }

    private static func triggerLooksRelational(_ trigger: String) -> Bool {
        trigger.contains("relacion") || trigger.contains("famil") || trigger.contains("social") || trigger.contains("conflit")
    }
}
