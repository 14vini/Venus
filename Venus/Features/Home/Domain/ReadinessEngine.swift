//
//  ReadinessEngine.swift
//  Venus
//
//  Created by Kaua on 29/09/26.
//

import Foundation
import SwiftUI

// MARK: - Readiness Engine Protocol

protocol ReadinessEngineProtocol: Sendable {
    func evaluate(
        todayMood: MoodType?,
        todayMoodItem: Mood?,
        weekMoods: [Mood],
        hasRecentChat: Bool,
        biometrics: BiometricSnapshot?,
        chatImpact: ChatReadinessImpact?,
        aiStateTitle: String?,
        aiStateSubtitle: String?
    ) -> ReadinessEnergyAssessment
}

// MARK: - Readiness Engine Implementation

final class ReadinessEngine: ReadinessEngineProtocol, @unchecked Sendable {
    static let shared = ReadinessEngine()

    init() {}

    func evaluate(
        todayMood: MoodType?,
        todayMoodItem: Mood?,
        weekMoods: [Mood] = [],
        hasRecentChat: Bool = false,
        biometrics: BiometricSnapshot? = nil,
        chatImpact: ChatReadinessImpact? = nil,
        aiStateTitle: String? = nil,
        aiStateSubtitle: String? = nil
    ) -> ReadinessEnergyAssessment {
        // 1. Subjetivo unificado
        var subjectiveScore: Double = 7.5
        if let item = todayMoodItem {
            let raw = BehaviorMoodScorer.score(for: item) // -1.8..1.4
            subjectiveScore = max(1.0, min(10.0, 6.2 + raw * 2.4))
        } else if let mood = todayMood {
            switch mood {
            case .energetic: subjectiveScore = 9.2
            case .happy: subjectiveScore = 8.2
            case .calm: subjectiveScore = 7.4
            case .tired: subjectiveScore = 4.2
            case .stressed: subjectiveScore = 3.2
            case .sad: subjectiveScore = 3.0
            }
        }

        // 1b. Ajuste semanal (tendência dos últimos 7 dias)
        var weeklyAdjustment: Double = 0
        if weekMoods.count >= 3 {
            let recent = weekMoods.suffix(14)
            let scores = recent.map { BehaviorMoodScorer.score(for: $0) }
            let avg = scores.reduce(0, +) / Double(max(1, scores.count))
            let weekly10 = max(1.0, min(10.0, 6.2 + avg * 2.4))
            weeklyAdjustment = (weekly10 - subjectiveScore) * 0.12
            weeklyAdjustment = max(-0.8, min(0.8, weeklyAdjustment))
        }
        subjectiveScore = max(1.0, min(10.0, subjectiveScore + weeklyAdjustment))

        // 2. Biométrica avançada
        var biometricScore: Double? = nil
        var biometricWeight: Double = 0.0
        var ecgCapped = false

        if let bio = biometrics, bio.hasBiometricData {
            var bioPillarScores: [Double] = []
            var weights: [Double] = []

            // A. HRV Recovery — relativo ao baseline individual de 7 dias
            if let ratio = bio.recoveryRatio, bio.hasReliableBaseline {
                let hrvScore = max(1.0, min(10.0, 7.5 + (ratio - 0.95) * 14.0))
                bioPillarScores.append(hrvScore)
                weights.append(2.2)
            } else if let rawHRV = bio.currentHRV {
                let rawScore = max(3.0, min(9.0, 2.0 + 10.0 * (1 - exp(-rawHRV / 45.0))))
                bioPillarScores.append(rawScore)
                weights.append(1.0)
            }

            // B. Sono (Duração + sono reparador REM/Profundo)
            if let sleep = bio.sleepScore {
                var adjustedSleep = sleep
                // Se frequência respiratória noturna estiver anormal (>18.5 br/min em repouso), penaliza levemente
                if let resp = bio.sleepRespiratoryRate, resp > 18.5 {
                    adjustedSleep = max(1.0, adjustedSleep - 0.8)
                }
                bioPillarScores.append(adjustedSleep)
                weights.append(1.8)
            }

            // C. RHR & Queda Noturna (Heart Rate Dip)
            if let rhr = bio.restingHeartRate {
                var rhrScore = max(1.0, min(10.0, 13.5 - Double(rhr) * 0.105))
                // Bônus/penalidade de dip noturno (queda saudável = 10% a 22%)
                if let dip = bio.heartRateDipPercentage {
                    if dip >= 10.0 && dip <= 22.0 {
                        rhrScore = min(10.0, rhrScore + 0.6) // Excelente recuperação autonômica
                    } else if dip < 3.0 {
                        rhrScore = max(1.0, rhrScore - 0.8) // Ausência de repouso cardíaco noturno
                    }
                }
                bioPillarScores.append(rhrScore)
                weights.append(1.2)
            }

            // D. Carga de Treino & Esforço Físico de Ontem
            if let activeEnergy = bio.yesterdayActiveEnergy, activeEnergy > 100 {
                let strainScore: Double
                if activeEnergy > 800 {
                    strainScore = 6.8 // Treino muito pesado: pede regeneração
                } else if activeEnergy > 450 {
                    strainScore = 8.2 // Treino saudável ativo
                } else {
                    strainScore = 7.5
                }
                bioPillarScores.append(strainScore)
                weights.append(0.8)
            }

            // E. ECG — Ritmo sinusal
            if let sinus = bio.ecgSinusRhythm, !sinus {
                ecgCapped = true
            }

            if !bioPillarScores.isEmpty {
                let totalW = weights.reduce(0, +)
                let weighted = zip(bioPillarScores, weights).map(*).reduce(0, +) / max(0.001, totalW)
                biometricScore = weighted

                let hasHRV = bio.recoveryRatio != nil && bio.hasReliableBaseline
                let hasSleep = bio.sleepScore != nil
                if hasHRV && hasSleep { biometricWeight = 0.58 }
                else if hasHRV || hasSleep { biometricWeight = 0.42 }
                else { biometricWeight = 0.30 }
            }
        }

        // 3. Blend Biometria + Subjetivo
        var finalScore: Double
        if let bioScore = biometricScore {
            finalScore = (bioScore * biometricWeight) + (subjectiveScore * (1.0 - biometricWeight))
        } else {
            finalScore = subjectiveScore
        }

        if ecgCapped {
            finalScore = min(finalScore, 4.5)
        }

        // 4. Chat Sentiment com Decaimento de Meia-Vida (Half-life de 6 horas)
        var chatApplied = false
        var chatDelta: Double = 0
        if let chat = chatImpact, chat.isValid {
            let effectiveDelta = chat.currentDelta
            let clampedDelta = max(-2.5, min(1.8, effectiveDelta))
            if abs(clampedDelta) >= 0.25 {
                finalScore += clampedDelta
                chatDelta = clampedDelta
                chatApplied = true
            }
        }

        finalScore = max(1.0, min(10.0, finalScore))

        // 5. Pilares (Foco, Corpo, Sono)
        let isSleepOk: Bool = {
            if let bioSleep = biometrics?.sleepScore {
                return bioSleep >= 6.5
            }
            if let sleepQuality = todayMoodItem?.sleepQuality {
                return sleepQuality == .good || sleepQuality == .excellent
            }
            if let chatSleep = chatImpact?.isSleepImpacted, chatApplied {
                return !chatSleep
            }
            return finalScore >= 5.5
        }()

        let isBodyOk: Bool = {
            if ecgCapped { return false }
            if let rhr = biometrics?.restingHeartRate, rhr > 85 {
                return false
            }
            if let dip = biometrics?.heartRateDipPercentage, dip < 2.0 {
                return false
            }
            if let bodySignals = todayMoodItem?.bodySignals {
                return !bodySignals.contains("Tensão muscular") && !bodySignals.contains("Cansaço físico")
            }
            if let chatBody = chatImpact?.isBodyImpacted, chatApplied {
                return !chatBody
            }
            return finalScore >= 5.0
        }()

        let isFocusOk: Bool = {
            if let ratio = biometrics?.recoveryRatio, ratio < 0.75 {
                return false
            }
            if let clarity = todayMoodItem?.mentalClarity {
                return clarity >= 4
            }
            if let chatFocus = chatImpact?.isFocusImpacted, chatApplied {
                return !chatFocus
            }
            return finalScore >= 5.0
        }()

        // 6. Micro-copy
        let resolvedTitle: String
        let resolvedSubtitle: String

        if let customTitle = chatImpact?.customStateTitle, !customTitle.isEmpty,
           let customSub = chatImpact?.customStateSubtitle, !customSub.isEmpty, chatApplied {
            resolvedTitle = customTitle
            resolvedSubtitle = customSub
        } else if let aiTitle = aiStateTitle, !aiTitle.isEmpty,
                  let aiSub = aiStateSubtitle, !aiSub.isEmpty {
            resolvedTitle = aiTitle
            resolvedSubtitle = aiSub
        } else {
            if finalScore >= 8.5 {
                resolvedTitle = "Go For It"
                resolvedSubtitle = "Bateria alta para focar e criar."
            } else if finalScore >= 6.5 {
                resolvedTitle = "Ritmo Fluido"
                resolvedSubtitle = "Mente serena e clareza para o dia."
            } else if finalScore >= 4.0 {
                resolvedTitle = "Ritmo Leve"
                resolvedSubtitle = "Equilibre tarefas e faça pausas."
            } else {
                resolvedTitle = ecgCapped ? "Modo Respiro" : "Poupe Bateria"
                resolvedSubtitle = ecgCapped
                    ? "Desacelere hoje e observe seu corpo."
                    : "Desacelere e priorize o essencial."
            }
        }

        // 7. Curva Intradiária Circadiana
        let intradayCurve = IntradayEnergyCurve.generate(baseScore: finalScore)

        // 8. Recomendação Inteligente de Ação
        let recommendation = ReadinessActionRecommendation.generate(
            score: finalScore,
            isFocusOk: isFocusOk,
            isBodyOk: isBodyOk,
            isSleepOk: isSleepOk,
            ecgCapped: ecgCapped
        )

        let breakdown = ReadinessBreakdown(
            subjectiveScore: subjectiveScore,
            biometricScore: biometricScore,
            biometricWeight: biometricWeight,
            weeklyAdjustment: weeklyAdjustment,
            chatDelta: chatDelta,
            ecgCapped: ecgCapped,
            baselineDays: biometrics?.hrvBaselineDays ?? 0,
            hrvBaselineAverage: biometrics?.hrvBaseline7Days,
            hrvCurrent: biometrics?.currentHRV,
            hrvRatio: biometrics?.recoveryRatio,
            sleepDurationHours: biometrics?.totalSleepHours,
            restorativeSleepHours: biometrics?.deepAndREMHours,
            restingHR: biometrics?.restingHeartRate,
            sleepingHR: biometrics?.sleepingHeartRate,
            hrDipPercentage: biometrics?.heartRateDipPercentage,
            sleepRespiratoryRate: biometrics?.sleepRespiratoryRate,
            yesterdayActiveEnergy: biometrics?.yesterdayActiveEnergy,
            yesterdayWorkoutDurationMinutes: biometrics?.yesterdayWorkoutDurationMinutes,
            recommendation: recommendation,
            intradayCurve: intradayCurve
        )

        return ReadinessEnergyAssessment(
            id: UUID(),
            score: finalScore,
            stateTitle: resolvedTitle,
            stateSubtitle: resolvedSubtitle,
            focusMetric: ReadinessPillarMetric(
                title: "Foco",
                iconName: "scope",
                isCompleted: isFocusOk,
                detail: isFocusOk ? "Clareza mental ativa" : "Atenção dividida"
            ),
            bodyMetric: ReadinessPillarMetric(
                title: "Corpo",
                iconName: "atom",
                isCompleted: isBodyOk,
                detail: ecgCapped ? "Observe seu ritmo — priorize descanso" : (isBodyOk ? "Recuperação física estável" : "Sinais de fadiga física")
            ),
            sleepMetric: ReadinessPillarMetric(
                title: "Sono",
                iconName: "bed.double.fill",
                isCompleted: isSleepOk,
                detail: isSleepOk ? "Descanso restaurador" : "Sono irregular"
            ),
            biometricsUsed: biometrics?.hasBiometricData ?? false,
            chatContextUsed: chatApplied,
            timestamp: Date(),
            breakdown: breakdown,
            dataStale: biometrics?.isStale ?? false
        )
    }
}
