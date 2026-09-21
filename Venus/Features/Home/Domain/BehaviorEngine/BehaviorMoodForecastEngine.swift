//
//  BehaviorMoodForecastEngine.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

struct BehaviorMoodForecastEngine {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func makeForecast(
        aggregates: [BehaviorDailyAggregate],
        moodEvents: [BehaviorMoodEvent],
        analysis: BehaviorPatternAnalysis,
        nextAction: NextBestAction,
        actionHistory: ActionHistorySummary,
        referenceDate: Date
    ) -> ProMoodForecast? {
        let today = calendar.startOfDay(for: referenceDate)
        let start = calendar.date(byAdding: .day, value: -20, to: today) ?? today

        let relevantAggregates = aggregates
            .filter { $0.dayKey >= start && $0.dayKey <= today && $0.moodEntries > 0 }
            .sorted { $0.dayKey < $1.dayKey }
        guard !relevantAggregates.isEmpty else { return nil }

        let relevantMoodEvents = moodEvents
            .filter { $0.timestamp >= start && $0.timestamp <= referenceDate }
            .sorted { $0.timestamp < $1.timestamp }

        let dailyScores = relevantAggregates.map(\.averageMoodScore)
        let baseline = expWeightedMean(dailyScores, alpha: 0.40)
        let trend = shortTermTrend(dailyScores)
        let volatility = standardDeviation(Array(dailyScores.suffix(10)))

        let habitCompletion = averageHabitCompletion(relevantAggregates) ?? 0.5
        let pendingPressure = averagePendingPressure(relevantAggregates)
        let stressLoad = averageStressLoad(relevantAggregates)
        let sleepBalance = sleepBalanceIndex(relevantAggregates)
        let clarityLevel = averageClarityLevel(relevantAggregates) ?? 0.5
        let lowControlRatio = lowControlRatio(in: relevantMoodEvents)
        let shortTimeRatio = shortTimeRatio(in: relevantMoodEvents)

        let components: [String: Double] = [
            "trend": clamp(trend, min: -0.45, max: 0.45) * 0.42,
            "habit": (habitCompletion - 0.5) * 0.26,
            "sleep": sleepBalance * 0.24,
            "clarity": (clarityLevel - 0.5) * 0.18,
            "stress": -(stressLoad - 0.35) * 0.32,
            "taskPressure": -(pendingPressure - 0.35) * 0.24,
            "control": -max(0, lowControlRatio - 0.35) * 0.16,
            "timeBudget": -max(0, shortTimeRatio - 0.45) * 0.10,
            "decline": -Double(min(analysis.indicators.recentDeclineDays, 3)) * 0.05,
            "volatility": -max(0, volatility - 0.35) * 0.18
        ]

        let rawDrift = components.values.reduce(0, +)
        let dailyDrift = clamp(rawDrift, min: -0.34, max: 0.34)

        let actionBoost = makeActionBoost(
            actionKind: nextAction.kind,
            analysis: analysis,
            history: actionHistory,
            lowControlRatio: lowControlRatio,
            shortTimeRatio: shortTimeRatio
        )

        let baseConfidence = makeConfidence(
            sampleCount: dailyScores.count,
            volatility: volatility,
            dailyDrift: dailyDrift,
            moodEvents: relevantMoodEvents
        )

        let horizons = [1, 3, 7]
        let points = horizons.map { dayOffset in
            let horizonFactor = sqrt(Double(dayOffset))
            let projectedScore = clampMoodScore(baseline + dailyDrift * horizonFactor)
            let actionPersistence = 1.0 + min(0.35, Double(dayOffset - 1) * 0.06)
            let projectedWithAction = clampMoodScore(projectedScore + actionBoost * actionPersistence)
            let confidenceFactor: Double

            switch dayOffset {
            case 1:
                confidenceFactor = 1.0
            case 3:
                confidenceFactor = 0.90
            default:
                confidenceFactor = 0.82
            }

            return MoodForecastPoint(
                dayOffset: dayOffset,
                projectedScore: projectedScore,
                projectedScoreWithAction: projectedWithAction,
                confidence: clamp(baseConfidence * confidenceFactor, min: 0.30, max: 0.93)
            )
        }

        return ProMoodForecast(
            generatedAt: referenceDate,
            baselineScore: baseline,
            confidence: baseConfidence,
            rationale: makeRationale(components: components, actionBoost: actionBoost),
            riskAlert: makeRiskAlert(points: points, analysis: analysis, stressLoad: stressLoad),
            points: points
        )
    }

    private func makeActionBoost(
        actionKind: NextBestActionKind,
        analysis: BehaviorPatternAnalysis,
        history: ActionHistorySummary,
        lowControlRatio: Double,
        shortTimeRatio: Double
    ) -> Double {
        let baseBoost = baseBoost(for: actionKind)
        let evidenceBoost = evidenceBoost(for: actionKind, signals: analysis.signals)

        let completionRate = history.completionRateByKind[actionKind] ?? 0.55
        let completionBoost = (completionRate - 0.55) * 0.12

        let reliefAverage = history.reliefAverageByKind[actionKind]
        let reliefBoost: Double
        if let reliefAverage {
            reliefBoost = ((reliefAverage - 3.0) / 2.0) * 0.08
        } else {
            reliefBoost = 0
        }

        let contextBoost = contextualBoost(
            for: actionKind,
            lowControlRatio: lowControlRatio,
            shortTimeRatio: shortTimeRatio
        )

        return clamp(baseBoost + evidenceBoost + completionBoost + reliefBoost + contextBoost, min: 0.03, max: 0.28)
    }

    private func baseBoost(for kind: NextBestActionKind) -> Double {
        switch kind.category {
        case .execution:
            return 0.11
        case .recovery:
            return kind == .sleepReset ? 0.12 : 0.09
        case .planning:
            return 0.08
        case .communication:
            return 0.10
        case .movement:
            return 0.09
        }
    }

    private func evidenceBoost(
        for kind: NextBestActionKind,
        signals: [PatternSignal]
    ) -> Double {
        let relevantSignals = signals.filter { signal in
            matches(signal: signal, actionKind: kind)
        }

        let strength = relevantSignals
            .map(signalStrength(of:))
            .max() ?? 0

        return min(0.12, strength * 0.70)
    }

    private func matches(signal: PatternSignal, actionKind: NextBestActionKind) -> Bool {
        switch actionKind.category {
        case .execution:
            return signal.key == "emotional-procrastination"
                || signal.key == "habit-correlation"
                || signal.key == "low-clarity-stress"
                || signal.key.hasPrefix("weekday-drop:")
        case .recovery:
            if actionKind == .sleepReset || actionKind == .microRest {
                return signal.key == "sleep-impact"
                    || signal.key == "low-clarity-stress"
                    || signal.key.hasPrefix("period-drop:")
            }
            return signal.key == "low-clarity-stress"
                || signal.key.hasPrefix("period-drop:")
                || signal.key == "sleep-impact"
        case .movement:
            return signal.key.hasPrefix("period-drop:")
                || signal.key == "habit-correlation"
        case .communication:
            if signal.key.hasPrefix("trigger:") {
                let rawTrigger = signal.key.replacingOccurrences(of: "trigger:", with: "")
                return rawTrigger.contains("relacion")
                    || rawTrigger.contains("famil")
                    || rawTrigger.contains("comunic")
            }
            return false
        case .planning:
            return signal.key == "habit-correlation"
                || signal.key == "emotional-procrastination"
                || signal.key.hasPrefix("weekday-drop:")
        }
    }

    private func signalStrength(of signal: PatternSignal) -> Double {
        let base = abs(min(signal.impact, 0)) * signal.recurrence * signal.confidence
        return base * (0.55 + 0.45 * signal.controllability)
    }

    private func contextualBoost(
        for actionKind: NextBestActionKind,
        lowControlRatio: Double,
        shortTimeRatio: Double
    ) -> Double {
        switch actionKind.category {
        case .recovery:
            return max(0, lowControlRatio - 0.30) * 0.08
        case .execution, .planning:
            let lowBudgetPenalty = max(0, shortTimeRatio - 0.50) * 0.06
            return -lowBudgetPenalty
        case .communication:
            return max(0, lowControlRatio - 0.45) * -0.05
        case .movement:
            return max(0, shortTimeRatio - 0.50) * -0.04
        }
    }

    private func makeConfidence(
        sampleCount: Int,
        volatility: Double,
        dailyDrift: Double,
        moodEvents: [BehaviorMoodEvent]
    ) -> Double {
        let sampleScore = min(1.0, Double(sampleCount) / 10.0)
        let stabilityScore = max(0.30, 1.0 - min(1.0, volatility / 1.3))
        let completenessScore = coverageScore(moodEvents)
        let driftPenalty = min(0.30, abs(dailyDrift) * 0.45)

        let confidence =
            0.36 +
            0.30 * sampleScore +
            0.20 * stabilityScore +
            0.14 * completenessScore -
            driftPenalty

        return clamp(confidence, min: 0.34, max: 0.90)
    }

    private func coverageScore(_ moodEvents: [BehaviorMoodEvent]) -> Double {
        guard !moodEvents.isEmpty else { return 0.20 }
        let total = Double(moodEvents.count)
        let energyCoverage = Double(moodEvents.filter { $0.energyLevel != nil }.count) / total
        let sleepCoverage = Double(moodEvents.filter { $0.sleepQuality != nil }.count) / total
        let clarityCoverage = Double(moodEvents.filter { $0.mentalClarity != nil }.count) / total
        let controlCoverage = Double(moodEvents.filter { $0.controlLevel != nil }.count) / total
        let timeCoverage = Double(moodEvents.filter { $0.availableTime != nil }.count) / total

        return (energyCoverage + sleepCoverage + clarityCoverage + controlCoverage + timeCoverage) / 5.0
    }

    private func makeRationale(
        components: [String: Double],
        actionBoost: Double
    ) -> String {
        let drivers = components
            .sorted { abs($0.value) > abs($1.value) }
            .filter { abs($0.value) >= 0.03 }
            .prefix(2)

        let driverText = drivers.map { key, value -> String in
            switch key {
            case "trend":
                return value >= 0
                    ? "seu historico recente aponta recuperacao gradual"
                    : "seu historico recente aponta queda emocional"
            case "sleep":
                return value >= 0
                    ? "sua qualidade de sono tem protegido seu estado"
                    : "o sono irregular tem puxado seu estado para baixo"
            case "taskPressure":
                return value >= 0
                    ? "a pressao de tarefas esta sob controle"
                    : "o acumulo de tarefas tem aumentado a sobrecarga"
            case "stress":
                return value >= 0
                    ? "os sinais de estresse reduziram"
                    : "os sinais de estresse ainda estao altos"
            case "habit":
                return value >= 0
                    ? "a consistencia de habitos esta ajudando seu equilibrio"
                    : "a queda de habitos esta afetando seu equilibrio"
            default:
                return value >= 0
                    ? "voce tem fator de protecao ativo no momento"
                    : "ha um fator de risco recorrente ativo no momento"
            }
        }

        let explanation = driverText.isEmpty
            ? "A previsao usa a combinacao de humor, energia, tarefas e consistencia recente."
            : "A previsao considera principalmente \(driverText.joined(separator: " e "))."

        let actionImpact = " Executar a micro-acao tende a adicionar cerca de +\(actionBoost.formatted(.number.precision(.fractionLength(2)))) ao score previsto no curto prazo."
        return explanation + actionImpact
    }

    private func makeRiskAlert(
        points: [MoodForecastPoint],
        analysis: BehaviorPatternAnalysis,
        stressLoad: Double
    ) -> String? {
        guard let dayOne = points.first(where: { $0.dayOffset == 1 }) else { return nil }
        if dayOne.projectedScoreWithAction <= -0.85 {
            return "Risco alto de queda nas proximas 24h. Priorize micro-acoes de protecao e reduza carga."
        }
        if analysis.indicators.recentDeclineDays >= 2 && stressLoad >= 0.55 {
            return "Risco moderado de continuidade da queda. Ative protocolo de recuperacao por 48h."
        }
        return nil
    }

    private func shortTermTrend(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        if values.count < 6 {
            let first = values.first ?? 0
            let last = values.last ?? 0
            return (last - first) / Double(max(1, values.count - 1))
        }
        let recent = Array(values.suffix(3))
        let previous = Array(values.dropLast(3).suffix(3))
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let previousAvg = previous.reduce(0, +) / Double(previous.count)
        return recentAvg - previousAvg
    }

    private func expWeightedMean(_ values: [Double], alpha: Double) -> Double {
        guard let first = values.first else { return 0 }
        return values.dropFirst().reduce(first) { partial, value in
            alpha * value + (1 - alpha) * partial
        }
    }

    private func averageHabitCompletion(_ days: [BehaviorDailyAggregate]) -> Double? {
        let values = days.compactMap(\.habitCompletionRate)
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func averagePendingPressure(_ days: [BehaviorDailyAggregate]) -> Double {
        let values = days.map { day -> Double in
            guard day.todoTotal > 0 else { return 0.30 }
            let pending = max(0, day.todoTotal - day.todoCompleted)
            return Double(pending) / Double(day.todoTotal)
        }
        guard !values.isEmpty else { return 0.30 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func averageStressLoad(_ days: [BehaviorDailyAggregate]) -> Double {
        let values = days.map { day in
            min(1.0, Double(day.stressSignalTotal) / 5.0)
        }
        guard !values.isEmpty else { return 0.35 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func sleepBalanceIndex(_ days: [BehaviorDailyAggregate]) -> Double {
        let totals = days.reduce(into: (good: 0, bad: 0, total: 0)) { partial, day in
            let good = day.sleepGoodCount + day.sleepExcellentCount
            let bad = day.sleepPoorCount + day.sleepFairCount
            partial.good += good
            partial.bad += bad
            partial.total += good + bad
        }
        guard totals.total > 0 else { return 0 }
        return Double(totals.good - totals.bad) / Double(totals.total)
    }

    private func averageClarityLevel(_ days: [BehaviorDailyAggregate]) -> Double? {
        let values = days.compactMap(\.averageClarity)
        guard !values.isEmpty else { return nil }
        let average = values.reduce(0, +) / Double(values.count)
        return clamp((average - 1.0) / 9.0, min: 0, max: 1)
    }

    private func lowControlRatio(in moodEvents: [BehaviorMoodEvent]) -> Double {
        let withControl = moodEvents.compactMap(\.controlLevel)
        guard !withControl.isEmpty else { return 0.35 }
        let lowCount = withControl.filter { $0 == .low }.count
        return Double(lowCount) / Double(withControl.count)
    }

    private func shortTimeRatio(in moodEvents: [BehaviorMoodEvent]) -> Double {
        let withTime = moodEvents.compactMap(\.availableTime)
        guard !withTime.isEmpty else { return 0.40 }
        let shortCount = withTime.filter { $0 == .fiveMinutes }.count
        return Double(shortCount) / Double(withTime.count)
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func clampMoodScore(_ value: Double) -> Double {
        clamp(value, min: -1.8, max: 1.4)
    }

    private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}
