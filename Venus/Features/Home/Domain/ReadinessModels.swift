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

// MARK: - Chat Readiness Impact with Exponential Half-Life Decay

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

    /// Fator de decaimento suave com meia-vida de 6 horas
    public var decayFactor: Double {
        let ageHours = Date().timeIntervalSince(timestamp) / 3600.0
        guard ageHours < 24.0 else { return 0.0 }
        return pow(2.0, -ageHours / 6.0)
    }

    /// Delta ponderado pelo tempo decorrido
    public var currentDelta: Double {
        scoreDelta * decayFactor
    }

    /// Impacto expira em 24h ou quando o efeito atenuado cai abaixo do limiar de ruído
    public var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 24 * 3600 || abs(currentDelta) < 0.2
    }
    public var isValid: Bool { !isExpired }
}

// MARK: - Readiness Level (0-100)

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
        case .peak: return "🚀"
        case .sustainable: return "⚖️"
        case .maintenance: return "🛡️"
        case .recovery: return "🪫"
        }
    }

    public var title: String {
        switch self {
        case .peak: return "Pico de Energia"
        case .sustainable: return "Ritmo Sustentável"
        case .maintenance: return "Manutenção"
        case .recovery: return "Modo Recuperação"
        }
    }
}

// MARK: - Intraday Circadian Energy Curve

public struct IntradayEnergyPoint: Identifiable, Equatable, Sendable {
    public let id: String
    public let hour: Int
    public let timeLabel: String
    public let phaseName: String
    public let energyMultiplier: Double // 0.65 to 1.15 relative to base readiness
    public let estimatedScore: Double // 0 to 10
    public let isPastOrCurrent: Bool

    public init(
        id: String = UUID().uuidString,
        hour: Int,
        timeLabel: String,
        phaseName: String,
        energyMultiplier: Double,
        estimatedScore: Double,
        isPastOrCurrent: Bool
    ) {
        self.id = id
        self.hour = hour
        self.timeLabel = timeLabel
        self.phaseName = phaseName
        self.energyMultiplier = energyMultiplier
        self.estimatedScore = estimatedScore
        self.isPastOrCurrent = isPastOrCurrent
    }
}

public struct IntradayEnergyCurve: Equatable, Sendable {
    public let points: [IntradayEnergyPoint]
    public let currentPhaseName: String
    public let currentPhaseSuggestion: String
    public let currentEnergyScore: Double

    public static func generate(baseScore: Double, date: Date = Date()) -> IntradayEnergyCurve {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)

        // Circadian milestones
        let milestones: [(hour: Int, label: String, phase: String, mult: Double)] = [
            (8, "08h", "Despertar", 0.90),
            (11, "11h", "Pico Matinal", 1.10),
            (14, "14h", "Vale Pós-Almoço", 0.78),
            (17, "17h", "Segundo Fôlego", 0.95),
            (21, "21h", "Desaceleração", 0.65)
        ]

        var generatedPoints: [IntradayEnergyPoint] = []
        for m in milestones {
            let estimated = max(1.0, min(10.0, baseScore * m.mult))
            let isPast = currentHour >= m.hour
            generatedPoints.append(
                IntradayEnergyPoint(
                    hour: m.hour,
                    timeLabel: m.label,
                    phaseName: m.phase,
                    energyMultiplier: m.mult,
                    estimatedScore: estimated,
                    isPastOrCurrent: isPast
                )
            )
        }

        // Determine current circadian phase & suggestion
        let phase: String
        let suggestion: String
        let currentMultiplier: Double

        switch currentHour {
        case 5..<10:
            phase = "Ativação Matinal"
            suggestion = "Beba água, faça luz solar direta nos olhos e defina suas 3 prioridades do dia."
            currentMultiplier = 0.90
        case 10..<13:
            phase = "Pico de Foco Cognitivo"
            suggestion = "Melhor momento do dia para tarefas complexas, tomadas de decisão e raciocínio profundo."
            currentMultiplier = 1.10
        case 13..<16:
            phase = "Vale Digestivo & Transição"
            suggestion = "Queda natural do ritmo biológico. Faça uma pausa breve, caminhe e evite decisões pesadas."
            currentMultiplier = 0.78
        case 16..<20:
            phase = "Segundo Fôlego & Execução"
            suggestion = "Retomada da energia. Ótimo para fechar tarefas pendentes, treinos ou organização do dia seguinte."
            currentMultiplier = 0.95
        default:
            phase = "Desaceleração Noturna"
            suggestion = "Reduza a intensidade das luzes e telas. Prepare corpo e mente para o descanso."
            currentMultiplier = 0.65
        }

        let currentEnergy = max(1.0, min(10.0, baseScore * currentMultiplier))

        return IntradayEnergyCurve(
            points: generatedPoints,
            currentPhaseName: phase,
            currentPhaseSuggestion: suggestion,
            currentEnergyScore: currentEnergy
        )
    }

    public static let sampleDefault = generate(baseScore: 8.0)
}

// MARK: - Action Recommendation

public struct ReadinessActionRecommendation: Equatable, Sendable {
    public enum ActionCategory: String, Sendable, Equatable {
        case focus
        case breath
        case movement
        case rest
        case talkToVenus
    }

    public let title: String
    public let subtitle: String
    public let iconName: String
    public let category: ActionCategory
    public let actionButtonTitle: String

    public static func generate(
        score: Double,
        isFocusOk: Bool,
        isBodyOk: Bool,
        isSleepOk: Bool,
        ecgCapped: Bool
    ) -> ReadinessActionRecommendation {
        if ecgCapped {
            return ReadinessActionRecommendation(
                title: "Modo Proteção Cardíaca",
                subtitle: "Ritmo cardíaco atípico detectado. Priorize repouso e evite treinos pesados hoje.",
                iconName: "heart.text.square.fill",
                category: .rest,
                actionButtonTitle: "Desacelerar"
            )
        }

        if !isSleepOk {
            return ReadinessActionRecommendation(
                title: "Ritual Noturno Antecipado",
                subtitle: "Sono reparador abaixo da média. Evite cafeína à tarde e programe 20 min sem telas antes de deitar.",
                iconName: "bed.double.fill",
                category: .rest,
                actionButtonTitle: "Proteger Sono"
            )
        }

        if !isFocusOk {
            return ReadinessActionRecommendation(
                title: "Descarregar Pensamentos",
                subtitle: "Sua mente está com sobrecarga mental. Faça um rápido brain-dump com Venus.",
                iconName: "sparkles",
                category: .talkToVenus,
                actionButtonTitle: "Desabafar com Venus"
            )
        }

        if !isBodyOk {
            return ReadinessActionRecommendation(
                title: "Recuperação & Pausa Ativa",
                subtitle: "Sinais de fadiga física ou alta carga muscular. Faça alongamento leve e hidrate-se.",
                iconName: "figure.walk",
                category: .movement,
                actionButtonTitle: "Pausa Ativa"
            )
        }

        if score >= 8.5 {
            return ReadinessActionRecommendation(
                title: "Janela de Alta Performance",
                subtitle: "Sua bateria e sistema nervoso estão no topo. Aproveite para criar e resolver o mais difícil.",
                iconName: "flame.fill",
                category: .focus,
                actionButtonTitle: "Foco Total"
            )
        }

        return ReadinessActionRecommendation(
            title: "Ritmo Fluido Sustentável",
            subtitle: "Equilíbrio estável. Trabalhe em blocos de foco e respeite suas pausas naturais.",
            iconName: "leaf.fill",
            category: .breath,
            actionButtonTitle: "Manter Ritmo"
        )
    }

    public static let sampleDefault = generate(
        score: 8.0,
        isFocusOk: true,
        isBodyOk: true,
        isSleepOk: true,
        ecgCapped: false
    )
}

// MARK: - Breakdown (Explicabilidade Completa)

public struct ReadinessBreakdown: Equatable, Sendable {
    public let subjectiveScore: Double
    public let biometricScore: Double?
    public let biometricWeight: Double
    public let weeklyAdjustment: Double
    public let chatDelta: Double
    public let ecgCapped: Bool
    public let baselineDays: Int

    // Métricas detalhadas
    public let hrvBaselineAverage: Double?
    public let hrvCurrent: Double?
    public let hrvRatio: Double?
    public let sleepDurationHours: Double?
    public let restorativeSleepHours: Double?
    public let restingHR: Double?
    public let sleepingHR: Double?
    public let hrDipPercentage: Double?
    public let sleepRespiratoryRate: Double?
    public let yesterdayActiveEnergy: Double?
    public let yesterdayWorkoutDurationMinutes: Double?
    public let recommendation: ReadinessActionRecommendation
    public let intradayCurve: IntradayEnergyCurve

    public init(
        subjectiveScore: Double,
        biometricScore: Double? = nil,
        biometricWeight: Double = 0,
        weeklyAdjustment: Double = 0,
        chatDelta: Double = 0,
        ecgCapped: Bool = false,
        baselineDays: Int = 0,
        hrvBaselineAverage: Double? = nil,
        hrvCurrent: Double? = nil,
        hrvRatio: Double? = nil,
        sleepDurationHours: Double? = nil,
        restorativeSleepHours: Double? = nil,
        restingHR: Double? = nil,
        sleepingHR: Double? = nil,
        hrDipPercentage: Double? = nil,
        sleepRespiratoryRate: Double? = nil,
        yesterdayActiveEnergy: Double? = nil,
        yesterdayWorkoutDurationMinutes: Double? = nil,
        recommendation: ReadinessActionRecommendation = .sampleDefault,
        intradayCurve: IntradayEnergyCurve = .sampleDefault
    ) {
        self.subjectiveScore = subjectiveScore
        self.biometricScore = biometricScore
        self.biometricWeight = biometricWeight
        self.weeklyAdjustment = weeklyAdjustment
        self.chatDelta = chatDelta
        self.ecgCapped = ecgCapped
        self.baselineDays = baselineDays
        self.hrvBaselineAverage = hrvBaselineAverage
        self.hrvCurrent = hrvCurrent
        self.hrvRatio = hrvRatio
        self.sleepDurationHours = sleepDurationHours
        self.restorativeSleepHours = restorativeSleepHours
        self.restingHR = restingHR
        self.sleepingHR = sleepingHR
        self.hrDipPercentage = hrDipPercentage
        self.sleepRespiratoryRate = sleepRespiratoryRate
        self.yesterdayActiveEnergy = yesterdayActiveEnergy
        self.yesterdayWorkoutDurationMinutes = yesterdayWorkoutDurationMinutes
        self.recommendation = recommendation
        self.intradayCurve = intradayCurve
    }

    public var hasReliableBiometrics: Bool {
        biometricScore != nil && baselineDays >= 3
    }
}

// MARK: - Readiness Energy Assessment

public struct ReadinessEnergyAssessment: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let score: Double // 0-10
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

    /// 0-100
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
        ),
        breakdown: ReadinessBreakdown(
            subjectiveScore: 8.0,
            biometricScore: 8.2,
            biometricWeight: 0.58,
            baselineDays: 7,
            hrvBaselineAverage: 55.0,
            hrvCurrent: 58.0,
            hrvRatio: 1.05,
            sleepDurationHours: 7.8,
            restorativeSleepHours: 2.2,
            restingHR: 62.0,
            sleepingHR: 54.0,
            hrDipPercentage: 12.9,
            sleepRespiratoryRate: 14.5,
            yesterdayActiveEnergy: 450.0,
            yesterdayWorkoutDurationMinutes: 40.0
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
        ReadinessEngine.shared.evaluate(
            todayMood: todayMood,
            todayMoodItem: todayMoodItem,
            weekMoods: weekMoods,
            hasRecentChat: hasRecentChat,
            biometrics: biometrics,
            chatImpact: chatImpact,
            aiStateTitle: aiStateTitle,
            aiStateSubtitle: aiStateSubtitle
        )
    }
}
