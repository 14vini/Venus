//
//  ReadinessModels.swift
//  Venus
//
//  Created by Kaua on 23/09/26.
//

import Foundation
import SwiftUI

// MARK: - Pillar Metric

public struct ReadinessPillarMetric: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let iconName: String
    public let isCompleted: Bool
    public let detail: String?

    public init(
        id: String = UUID().uuidString,
        title: String,
        iconName: String,
        isCompleted: Bool = true,
        detail: String? = nil
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.isCompleted = isCompleted
        self.detail = detail
    }
}

// MARK: - Chat Readiness Impact

public struct ChatReadinessImpact: Sendable, Equatable, Codable {
    public let scoreDelta: Double // e.g. -1.5 for heavy anxiety/burnout, +1.0 for clarity/relief
    public let isFocusImpacted: Bool?
    public let isBodyImpacted: Bool?
    public let isSleepImpacted: Bool?
    public let customStateTitle: String?
    public let customStateSubtitle: String?
    public let detectedInsight: String?
    public let timestamp: Date

    public init(
        scoreDelta: Double,
        isFocusImpacted: Bool? = nil,
        isBodyImpacted: Bool? = nil,
        isSleepImpacted: Bool? = nil,
        customStateTitle: String? = nil,
        customStateSubtitle: String? = nil,
        detectedInsight: String? = nil,
        timestamp: Date = Date()
    ) {
        self.scoreDelta = scoreDelta
        self.isFocusImpacted = isFocusImpacted
        self.isBodyImpacted = isBodyImpacted
        self.isSleepImpacted = isSleepImpacted
        self.customStateTitle = customStateTitle
        self.customStateSubtitle = customStateSubtitle
        self.detectedInsight = detectedInsight
        self.timestamp = timestamp
    }

    /// Impacto expira em 24h — evita score stale quando a conversa esfria.
    public var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 3600
    }
    public var isValid: Bool { !isExpired }
}

// MARK: - Readiness Level (0-100 alinhado ao README)

public enum ReadinessLevel: String, Equatable, Sendable {
    case peak        // 85-100
    case sustainable // 65-84
    case maintenance // 40-64
    case recovery    // <40

    public static func level(forScore10 score: Double) -> ReadinessLevel {
        let pct = max(0, min(10, score)) / 10 * 100
        switch pct {
        case 85...100: return .peak
        case 65..<85: return .sustainable
        case 40..<65: return .maintenance
        default: return .recovery
        }
    }

    public var emoji: String {
        switch self {
        case .peak: return "\u{1F680}"
        case .sustainable: return "\u{2696}\u{FE0F}"
        case .maintenance: return "\u{1F6E1}\u{FE0F}"
        case .recovery: return "\u{1FAAB}"
        }
    }
}

// MARK: - Breakdown (explicabilidade)

public struct ReadinessBreakdown: Equatable, Sendable {
    public let subjectiveScore: Double
    public let biometricScore: Double?
    public let biometricWeight: Double
    public let weeklyAdjustment: Double
    public let chatDelta: Double
    public let ecgCapped: Bool
    public let baselineDays: Int

    public init(
        subjectiveScore: Double,
        biometricScore: Double? = nil,
        biometricWeight: Double = 0,
        weeklyAdjustment: Double = 0,
        chatDelta: Double = 0,
        ecgCapped: Bool = false,
        baselineDays: Int = 0
    ) {
        self.subjectiveScore = subjectiveScore
        self.biometricScore = biometricScore
        self.biometricWeight = biometricWeight
        self.weeklyAdjustment = weeklyAdjustment
        self.chatDelta = chatDelta
        self.ecgCapped = ecgCapped
        self.baselineDays = baselineDays
    }

    public var hasReliableBiometrics: Bool {
        biometricScore != nil && baselineDays >= 3
    }
}

// MARK: - Readiness Assessment

public struct ReadinessEnergyAssessment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let score: Double // 0-10 (UI pode exibir percentage100)
    public let stateTitle: String
    public let stateSubtitle: String
    public let focusMetric: ReadinessPillarMetric
    public let bodyMetric: ReadinessPillarMetric
    public let sleepMetric: ReadinessPillarMetric
    public let biometricsUsed: Bool
    public let chatContextUsed: Bool
    public let timestamp: Date
    public let breakdown: ReadinessBreakdown?
    public let dataStale: Bool

    public init(
        id: UUID = UUID(),
        score: Double,
        stateTitle: String,
        stateSubtitle: String = "",
        focusMetric: ReadinessPillarMetric,
        bodyMetric: ReadinessPillarMetric,
        sleepMetric: ReadinessPillarMetric,
        biometricsUsed: Bool = false,
        chatContextUsed: Bool = false,
        timestamp: Date = Date(),
        breakdown: ReadinessBreakdown? = nil,
        dataStale: Bool = false
    ) {
        self.id = id
        self.score = score
        self.stateTitle = stateTitle
        self.stateSubtitle = stateSubtitle
        self.focusMetric = focusMetric
        self.bodyMetric = bodyMetric
        self.sleepMetric = sleepMetric
        self.biometricsUsed = biometricsUsed
        self.chatContextUsed = chatContextUsed
        self.timestamp = timestamp
        self.breakdown = breakdown
        self.dataStale = dataStale
    }

    public var percentage: Double {
        let clamped = max(0.0, min(10.0, score))
        return clamped / 10.0
    }

    /// 0-100 alinhado ao README (85-100 peak, etc.)
    public var percentage100: Int {
        Int((percentage * 100).rounded())
    }

    public var level: ReadinessLevel { ReadinessLevel.level(forScore10: score) }

    public var title: String { stateTitle }

    public var tintColor: Color {
        switch level {
        case .peak: return Color(hex: "00F5D4")
        case .sustainable: return Color(hex: "4ADE80")
        case .maintenance: return Color(hex: "FFE44A")
        case .recovery: return Color(hex: "FF9A6C")
        }
    }

    public static let sampleDefault = ReadinessEnergyAssessment(
        score: 8.0,
        stateTitle: "Go For It",
        stateSubtitle: "Disposição alta para tarefas que exigem foco e energia.",
        focusMetric: ReadinessPillarMetric(
            title: "Foco",
            iconName: "scope",
            isCompleted: true,
            detail: "Carga mental equilibrada"
        ),
        bodyMetric: ReadinessPillarMetric(
            title: "Corpo",
            iconName: "atom",
            isCompleted: true,
            detail: "Recuperação física estável"
        ),
        sleepMetric: ReadinessPillarMetric(
            title: "Sono",
            iconName: "bed.double.fill",
            isCompleted: true,
            detail: "Descanso restaurador"
        )
    )

    static func evaluate(
        todayMood: MoodType?,
        todayMoodItem: Mood?,
        weekMoods: [Mood] = [],
        hasRecentChat: Bool = false,
        biometrics: BiometricSnapshot? = nil,
        chatImpact: ChatReadinessImpact? = nil,
        aiStateTitle: String? = nil,
        aiStateSubtitle: String? = nil
    ) -> ReadinessEnergyAssessment {
        // 1. Subjetivo unificado: BehaviorMoodScorer quando há check-in completo,
        //    senão mapa fixo por MoodType. Normaliza -1.8..1.4 -> 0..10.
        var subjectiveScore: Double = 7.5
        if let item = todayMoodItem {
            let raw = BehaviorMoodScorer.score(for: item) // -1.8..1.4
            // Mapeamento linear: -1.8 -> 1.5, 0 -> 6.2, 1.4 -> 9.6
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

        // 1b. Ajuste semanal: usa weekMoods (antes ignorado).
        // Se a média dos últimos 7 dias está bem abaixo/acima de hoje, puxa 5% para a tendência.
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

        // 2. Biométrico com curvas suaves (sem cliffs) + baseline confiável
        var biometricScore: Double? = nil
        var biometricWeight: Double = 0.0
        var ecgCapped = false

        if let bio = biometrics, bio.hasBiometricData {
            var bioPillarScores: [Double] = []
            var weights: [Double] = []

            // A. HRV Recovery — interpolação suave em vez de degraus
            if let ratio = bio.recoveryRatio, bio.hasReliableBaseline {
                // ratio 0.75 -> ~3.5, 0.95 -> ~7.5, 1.05 -> ~8.8, 1.15 -> ~9.6
                let hrvScore = max(1.0, min(10.0, 7.5 + (ratio - 0.95) * 14.0))
                bioPillarScores.append(hrvScore)
                weights.append(2.0)
            } else if let rawHRV = bio.currentHRV {
                // Fallback só quando sem baseline: curva log-like, sem número mágico 60ms
                // 30ms -> ~4.5, 50ms -> ~7.0, 80ms -> ~8.8
                let rawScore = max(3.0, min(9.0, 2.0 + 10.0 * (1 - exp(-rawHRV / 45.0))))
                bioPillarScores.append(rawScore)
                weights.append(1.0)
            }

            // B. Sleep
            if let sleep = bio.sleepScore {
                bioPillarScores.append(sleep)
                weights.append(1.5)
            }

            // C. RHR — curva suave (sem degraus 58/68/78)
            if let rhr = bio.restingHeartRate {
                // 55 -> 9.3, 65 -> 8.0, 75 -> 6.4, 85 -> 4.2
                let rhrScore = max(1.0, min(10.0, 13.5 - Double(rhr) * 0.105))
                bioPillarScores.append(rhrScore)
                weights.append(1.0)
            }

            // D. ECG — NÃO entra na média; capa o score final e sinaliza
            if let sinus = bio.ecgSinusRhythm, !sinus {
                ecgCapped = true
            }

            if !bioPillarScores.isEmpty {
                let totalW = weights.reduce(0, +)
                let weighted = zip(bioPillarScores, weights).map(*).reduce(0, +) / max(0.001, totalW)
                biometricScore = weighted
                // Peso proporcional à completude: HRV+sono = 0.55, parcial = 0.30-0.45
                let hasHRV = bio.recoveryRatio != nil && bio.hasReliableBaseline
                let hasSleep = bio.sleepScore != nil
                if hasHRV && hasSleep { biometricWeight = 0.55 }
                else if hasHRV || hasSleep { biometricWeight = 0.40 }
                else { biometricWeight = 0.30 }
            }
        }

        // 3. Blend
        var finalScore: Double
        if let bioScore = biometricScore {
            finalScore = (bioScore * biometricWeight) + (subjectiveScore * (1.0 - biometricWeight))
        } else {
            finalScore = subjectiveScore
        }

        // ECG cap: ritmo não-sinusal limita a 4.5 e força Modo Respiro (não é diagnóstico)
        if ecgCapped {
            finalScore = min(finalScore, 4.5)
        }

        // 4. Chat — só se válido (<24h), sem boost grátis por só abrir o chat
        var chatApplied = false
        var chatDelta: Double = 0
        if let chat = chatImpact, chat.isValid {
            let clampedDelta = max(-2.5, min(1.8, chat.scoreDelta))
            // Delta pequeno (<0.4) é ruído — ignora
            if abs(clampedDelta) >= 0.4 {
                finalScore += clampedDelta
                chatDelta = clampedDelta
                chatApplied = true
            }
        }
        // REMOVIDO: +0.4 grátis por hasRecentChat (inflava score sem sinal emocional)

        finalScore = max(1.0, min(10.0, finalScore))

        // 5. Pilares
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

        // 6. Micro-copy (default alinhado a 0-100)
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

        let breakdown = ReadinessBreakdown(
            subjectiveScore: subjectiveScore,
            biometricScore: biometricScore,
            biometricWeight: biometricWeight,
            weeklyAdjustment: weeklyAdjustment,
            chatDelta: chatDelta,
            ecgCapped: ecgCapped,
            baselineDays: biometrics?.hrvBaselineDays ?? 0
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
