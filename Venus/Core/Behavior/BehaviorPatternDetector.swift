//
//  BehaviorPatternDetector.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

struct BehaviorPatternDetector {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func analyze(
        aggregates: [BehaviorDailyAggregate],
        referenceDate: Date,
        profile: BehaviorProfileContext
    ) -> BehaviorPatternAnalysis {
        let currentWeekStart = startOfDay(addingDays: -6, from: referenceDate)
        let previousWeekStart = startOfDay(addingDays: -13, from: referenceDate)
        let last21Start = startOfDay(addingDays: -20, from: referenceDate)
        let last14Start = startOfDay(addingDays: -13, from: referenceDate)

        let currentWeek = aggregates.filter { $0.dayKey >= currentWeekStart && $0.dayKey <= referenceDate }
        let previousWeek = aggregates.filter { $0.dayKey >= previousWeekStart && $0.dayKey < currentWeekStart }
        let last21Days = aggregates.filter { $0.dayKey >= last21Start && $0.dayKey <= referenceDate }
        let last14Days = aggregates.filter { $0.dayKey >= last14Start && $0.dayKey <= referenceDate }
        let totalMoodEntries = aggregates.reduce(0) { partialResult, day in
            partialResult + day.moodEntries
        }
        let isSparseHistory = totalMoodEntries < 3

        let trend = buildWeeklyTrend(currentWeek: currentWeek, previousWeek: previousWeek)
        var signals: [PatternSignal] = []

        if let triggerSignal = dominantTriggerSignal(from: currentWeek, referenceDate: referenceDate) {
            signals.append(triggerSignal)
        }

        if let sleepSignal = sleepImpactSignal(from: last14Days) {
            signals.append(sleepSignal)
        }

        if let procrastinationSignal = emotionalProcrastinationSignal(from: last14Days) {
            signals.append(procrastinationSignal)
        }

        if let clarityStressSignal = lowClarityStressSignal(from: currentWeek) {
            signals.append(clarityStressSignal)
        }

        let weekdayTrend = weekdaySeasonalitySignals(from: last21Days)
        signals.append(contentsOf: weekdayTrend.signals)
        let periodTrend = dayPeriodSeasonalitySignals(from: last21Days)
        signals.append(contentsOf: periodTrend.signals)

        if let habitSignal = habitCorrelationSignal(from: last14Days) {
            signals.append(habitSignal)
        }

        if isSparseHistory {
            signals = signals.map { signal in
                PatternSignal(
                    key: signal.key,
                    impact: signal.impact,
                    recurrence: signal.recurrence * 0.75,
                    confidence: signal.confidence * 0.55,
                    controllability: signal.controllability,
                    detail: signal.detail,
                    suggestedFocus: signal.suggestedFocus
                )
            }
        }

        let dominantNegativeTrigger = signals
            .first(where: { $0.key.hasPrefix("trigger:") && $0.impact < 0 })?
            .key
            .replacingOccurrences(of: "trigger:", with: "")

        let lowClarityDays = currentWeek.filter { ($0.averageClarity ?? 10) <= 4.0 }.count
        let highStressDays = currentWeek.filter { $0.stressSignalTotal > 0 }.count
        let hasSleepImpact = signals.contains(where: { $0.key == "sleep-impact" })
        let hasEmotionalProcrastination = signals.contains(where: { $0.key == "emotional-procrastination" })
        let hasHabitCorrelation = signals.contains(where: { $0.key == "habit-correlation" })
        let recentDeclineDays = recentDeclineDays(in: currentWeek)

        let indicators = BehaviorPatternIndicators(
            dominantNegativeTrigger: dominantNegativeTrigger,
            bestWeekday: weekdayTrend.bestWeekday,
            worstWeekday: weekdayTrend.worstWeekday,
            bestPeriod: periodTrend.bestPeriod,
            worstPeriod: periodTrend.worstPeriod,
            recentDeclineDays: recentDeclineDays,
            hasSleepImpact: hasSleepImpact,
            hasEmotionalProcrastination: hasEmotionalProcrastination,
            hasHabitCorrelation: hasHabitCorrelation,
            lowClarityDays: lowClarityDays,
            highStressDays: highStressDays
        )

        let alert = makePrimaryAlert(from: signals, indicators: indicators)

        return BehaviorPatternAnalysis(
            weeklyTrend: trend,
            indicators: indicators,
            signals: rankSignals(signals, profile: profile),
            primaryAlert: alert
        )
    }

    private func buildWeeklyTrend(
        currentWeek: [BehaviorDailyAggregate],
        previousWeek: [BehaviorDailyAggregate]
    ) -> WeeklyEmotionalTrend {
        let currentScore = averageMoodScore(currentWeek) ?? 0
        let previousScore = averageMoodScore(previousWeek)
        let delta = currentScore - (previousScore ?? currentScore)
        let volatility = standardDeviation(currentWeek.map(\.averageMoodScore))

        let direction: WeeklyTrendDirection
        if previousScore == nil {
            if currentScore >= 0.20 {
                direction = .improving
            } else if currentScore <= -0.20 {
                direction = .declining
            } else {
                direction = .stable
            }
        } else if delta >= 0.20 {
            direction = .improving
        } else if delta <= -0.20 {
            direction = .declining
        } else {
            direction = .stable
        }

        let summary: String
        let oscillation = volatility >= 0.55 ? " Com oscilacao diaria alta." : ""
        switch direction {
        case .improving:
            summary = "Seu estado emocional melhorou na comparacao semanal.\(oscillation)"
        case .stable:
            summary = "Seu padrao emocional esta estavel nesta semana.\(oscillation)"
        case .declining:
            summary = "Seu estado emocional mostrou queda nesta semana.\(oscillation)"
        }

        return WeeklyEmotionalTrend(
            direction: direction,
            summary: summary,
            currentWeekScore: currentScore,
            previousWeekScore: previousScore
        )
    }

    private func dominantTriggerSignal(
        from days: [BehaviorDailyAggregate],
        referenceDate: Date
    ) -> PatternSignal? {
        var triggerStats: [String: (count: Int, scoreSum: Double, recencyScore: Double)] = [:]

        for day in days where day.moodEntries > 0 {
            let dayAge = max(
                0,
                calendar.dateComponents([.day], from: day.dayKey, to: referenceDate).day ?? 0
            )
            let recencyWeight = 1.0 / Double(dayAge + 1)

            for (trigger, count) in day.triggerCounts where !trigger.isEmpty {
                let cappedCount = min(3, count)
                triggerStats[trigger, default: (0, 0, 0)].count += cappedCount
                triggerStats[trigger, default: (0, 0, 0)].scoreSum += day.averageMoodScore * Double(cappedCount)
                triggerStats[trigger, default: (0, 0, 0)].recencyScore += Double(cappedCount) * recencyWeight
            }
        }

        let topRecentTriggerKeys = Set(
            triggerStats
                .sorted { lhs, rhs in
                    if lhs.value.recencyScore == rhs.value.recencyScore {
                        return lhs.value.count > rhs.value.count
                    }
                    return lhs.value.recencyScore > rhs.value.recencyScore
                }
                .prefix(8)
                .map(\.key)
        )

        guard let best = triggerStats
            .compactMap({ trigger, stats -> (String, Int, Double, Double)? in
                guard topRecentTriggerKeys.contains(trigger) else { return nil }
                guard stats.count >= 2 else { return nil }
                let average = stats.scoreSum / Double(max(1, stats.count))
                guard average <= -0.15 else { return nil }
                return (trigger, stats.count, average, stats.recencyScore)
            })
            .sorted(by: { lhs, rhs in
                if lhs.1 == rhs.1 {
                    if lhs.2 == rhs.2 {
                        return lhs.3 > rhs.3
                    }
                    return lhs.2 < rhs.2
                }
                return lhs.1 > rhs.1
            })
            .first else { return nil }

        let recurrence = min(1.0, Double(best.1) / 5.0)
        let confidence = min(1.0, Double(best.1) / 6.0)

        return PatternSignal(
            key: "trigger:\(best.0)",
            impact: best.2,
            recurrence: recurrence,
            confidence: confidence,
            controllability: 0.74,
            detail: "O gatilho '\(best.0.capitalized)' apareceu \(best.1)x com valencia emocional mais baixa.",
            suggestedFocus: "Reduza exposicao a esse gatilho nas proximas 48h."
        )
    }

    private func sleepImpactSignal(from days: [BehaviorDailyAggregate]) -> PatternSignal? {
        let poorDays = days.filter { ($0.sleepPoorCount + $0.sleepFairCount) > ($0.sleepGoodCount + $0.sleepExcellentCount) && $0.moodEntries > 0 }
        let goodDays = days.filter { ($0.sleepGoodCount + $0.sleepExcellentCount) > ($0.sleepPoorCount + $0.sleepFairCount) && $0.moodEntries > 0 }

        guard poorDays.count >= 2, goodDays.count >= 2 else { return nil }

        let poorAvg = averageMoodScore(poorDays) ?? 0
        let goodAvg = averageMoodScore(goodDays) ?? 0
        let impact = poorAvg - goodAvg

        guard impact <= -0.18 else { return nil }

        let samples = poorDays.count + goodDays.count
        return PatternSignal(
            key: "sleep-impact",
            impact: impact,
            recurrence: min(1.0, Double(poorDays.count) / 5.0),
            confidence: min(1.0, Double(samples) / 8.0),
            controllability: 0.88,
            detail: "Nos dias de sono ruim, seu humor ficou em media \(abs(impact).formatted(.number.precision(.fractionLength(2)))) pontos pior.",
            suggestedFocus: "Ajustar sono por 2 noites tende a reduzir sobrecarga."
        )
    }

    private func emotionalProcrastinationSignal(from days: [BehaviorDailyAggregate]) -> PatternSignal? {
        let highStrainDays = days.filter { day in
            day.moodEntries > 0
                && day.todoTotal > 0
                && (day.averageMoodScore <= -0.35 || day.lowEnergyCount > (day.mediumEnergyCount + day.highEnergyCount))
        }
        let neutralDays = days.filter { day in
            day.moodEntries > 0
                && day.todoTotal > 0
                && day.averageMoodScore > -0.20
        }

        guard highStrainDays.count >= 2, neutralDays.count >= 2 else { return nil }

        let highCompletion = highStrainDays.map(\.todoCompletionRate).reduce(0, +) / Double(highStrainDays.count)
        let neutralCompletion = neutralDays.map(\.todoCompletionRate).reduce(0, +) / Double(neutralDays.count)
        let delta = highCompletion - neutralCompletion

        guard delta <= -0.12 else { return nil }

        return PatternSignal(
            key: "emotional-procrastination",
            impact: delta,
            recurrence: min(1.0, Double(highStrainDays.count) / 6.0),
            confidence: min(1.0, Double(highStrainDays.count + neutralDays.count) / 10.0),
            controllability: 0.82,
            detail: "Quando sua carga emocional aumenta, sua taxa de conclusao cai de forma recorrente.",
            suggestedFocus: "Destravar 1 tarefa curta em dias pesados reduz acumulacao."
        )
    }

    private func lowClarityStressSignal(from days: [BehaviorDailyAggregate]) -> PatternSignal? {
        let lowClarityDays = days.filter { ($0.averageClarity ?? 10) <= 4.0 }.count
        let stressDays = days.filter { $0.stressSignalTotal > 0 }.count

        guard lowClarityDays >= 3, stressDays >= 2 else { return nil }

        return PatternSignal(
            key: "low-clarity-stress",
            impact: -0.30,
            recurrence: min(1.0, Double(lowClarityDays) / 7.0),
            confidence: min(1.0, Double(lowClarityDays + stressDays) / 10.0),
            controllability: 0.70,
            detail: "Baixa clareza mental e sinais corporais de estresse se repetiram nesta semana.",
            suggestedFocus: "Reduzir carga cognitiva e simplificar prioridades."
        )
    }

    private func weekdaySeasonalitySignals(
        from days: [BehaviorDailyAggregate]
    ) -> (signals: [PatternSignal], bestWeekday: Int?, worstWeekday: Int?) {
        var buckets: [Int: [Double]] = [:]

        for day in days where day.moodEntries > 0 {
            let weekday = calendar.component(.weekday, from: day.dayKey)
            buckets[weekday, default: []].append(day.averageMoodScore)
        }

        let ranked = buckets.compactMap { weekday, scores -> (Int, Double, Int)? in
            guard scores.count >= 2 else { return nil }
            return (weekday, scores.reduce(0, +) / Double(scores.count), scores.count)
        }
        .sorted { $0.1 < $1.1 }

        guard !ranked.isEmpty else { return ([], nil, nil) }

        let best = ranked.max(by: { $0.1 < $1.1 })
        let worst = ranked.min(by: { $0.1 < $1.1 })

        var signals: [PatternSignal] = []
        if let worst, worst.1 <= -0.28 {
            signals.append(
                PatternSignal(
                    key: "weekday-drop:\(worst.0)",
                    impact: worst.1,
                    recurrence: min(1.0, Double(worst.2) / 4.0),
                    confidence: min(1.0, Double(worst.2) / 5.0),
                    controllability: 0.64,
                    detail: "\(weekdayName(for: worst.0)) aparece como seu ponto de maior queda emocional.",
                    suggestedFocus: "Antecipar esse dia com agenda mais leve e uma micro-acao preventiva."
                )
            )
        }

        return (signals, best?.0, worst?.0)
    }

    private func dayPeriodSeasonalitySignals(
        from days: [BehaviorDailyAggregate]
    ) -> (signals: [PatternSignal], bestPeriod: BehaviorDayPeriod?, worstPeriod: BehaviorDayPeriod?) {
        var buckets: [BehaviorDayPeriod: (scoreSum: Double, sampleCount: Int)] = [:]

        for day in days where day.moodEntries > 0 {
            for period in BehaviorDayPeriod.allCases {
                let count = day.moodCountByPeriod[period, default: 0]
                guard count > 0 else { continue }
                let sum = day.moodScoreSumByPeriod[period, default: 0]
                buckets[period, default: (0, 0)].scoreSum += sum
                buckets[period, default: (0, 0)].sampleCount += count
            }
        }

        let ranked = buckets.compactMap { period, stats -> (BehaviorDayPeriod, Double, Int)? in
            guard stats.sampleCount >= 3 else { return nil }
            return (period, stats.scoreSum / Double(stats.sampleCount), stats.sampleCount)
        }
        .sorted { $0.1 < $1.1 }

        guard !ranked.isEmpty else { return ([], nil, nil) }

        let best = ranked.max(by: { $0.1 < $1.1 })
        let worst = ranked.min(by: { $0.1 < $1.1 })

        var signals: [PatternSignal] = []
        if let worst, worst.1 <= -0.25 {
            signals.append(
                PatternSignal(
                    key: "period-drop:\(worst.0.rawValue)",
                    impact: worst.1,
                    recurrence: min(1.0, Double(worst.2) / 7.0),
                    confidence: min(1.0, Double(worst.2) / 9.0),
                    controllability: 0.78,
                    detail: "\(dayPeriodName(for: worst.0)) tem concentrado suas quedas emocionais mais fortes.",
                    suggestedFocus: "Programe uma micro-acao preventiva nesse periodo por 3 dias."
                )
            )
        }

        return (signals, best?.0, worst?.0)
    }

    private func habitCorrelationSignal(from days: [BehaviorDailyAggregate]) -> PatternSignal? {
        let valid = days.filter { $0.moodEntries > 0 && $0.habitTotal > 0 }
        guard valid.count >= 4 else { return nil }

        let highCompletionDays = valid.filter { ($0.habitCompletionRate ?? 0) >= 0.67 }
        let lowCompletionDays = valid.filter { ($0.habitCompletionRate ?? 1) <= 0.33 }

        guard highCompletionDays.count >= 2, lowCompletionDays.count >= 2 else { return nil }

        let highMood = averageMoodScore(highCompletionDays) ?? 0
        let lowMood = averageMoodScore(lowCompletionDays) ?? 0
        let impact = lowMood - highMood

        guard impact <= -0.15 else { return nil }

        return PatternSignal(
            key: "habit-correlation",
            impact: impact,
            recurrence: min(1.0, Double(lowCompletionDays.count) / 6.0),
            confidence: min(1.0, Double(valid.count) / 10.0),
            controllability: 0.90,
            detail: "Dias com habitos abaixo de 33% tiveram humor medio \(abs(impact).formatted(.number.precision(.fractionLength(2)))) pontos pior.",
            suggestedFocus: "Proteja 2 habitos-base mesmo em dias dificeis para estabilizar o humor."
        )
    }

    private func makePrimaryAlert(
        from signals: [PatternSignal],
        indicators: BehaviorPatternIndicators
    ) -> PatternAlert? {
        let severeSignal = signals
            .sorted { severity(of: $0) > severity(of: $1) }
            .first

        if let severeSignal, severity(of: severeSignal) >= 0.16, severeSignal.impact < 0 {
            return PatternAlert(
                title: alertTitle(for: severeSignal, indicators: indicators),
                detail: severeSignal.detail
            )
        }

        return nil
    }

    private func rankSignals(
        _ signals: [PatternSignal],
        profile: BehaviorProfileContext
    ) -> [PatternSignal] {
        signals.sorted { lhs, rhs in
            let lhsScore = severity(of: lhs) + profileBoost(for: lhs, profile: profile)
            let rhsScore = severity(of: rhs) + profileBoost(for: rhs, profile: profile)
            return lhsScore > rhsScore
        }
    }

    private func severity(of signal: PatternSignal) -> Double {
        let base = abs(min(signal.impact, 0)) * signal.recurrence * signal.confidence
        return base * (0.55 + 0.45 * signal.controllability)
    }

    private func profileBoost(for signal: PatternSignal, profile: BehaviorProfileContext) -> Double {
        if signal.key == "sleep-impact" && profile.improvementAreas.contains("sono") {
            return 0.08
        }
        if signal.key == "emotional-procrastination" && profile.improvementAreas.contains("foco e produtividade") {
            return 0.08
        }
        if signal.key == "habit-correlation" && (profile.improvementAreas.contains("disciplina") || profile.improvementAreas.contains("consistencia")) {
            return 0.07
        }
        if signal.key.hasPrefix("trigger:") {
            let trigger = signal.key.replacingOccurrences(of: "trigger:", with: "")
            if profile.emotionalAreas.contains(trigger) || profile.improvementAreas.contains(trigger) {
                return 0.07
            }
        }
        return 0
    }

    private func alertTitle(for signal: PatternSignal, indicators: BehaviorPatternIndicators) -> String {
        if signal.key == "emotional-procrastination" {
            return "Procrastinacao emocional detectada"
        }
        if signal.key == "sleep-impact" {
            return "Sono influenciando seu humor"
        }
        if signal.key == "low-clarity-stress" {
            return "Baixa clareza com estresse recorrente"
        }
        if signal.key == "habit-correlation" {
            return "Habitos influenciando seu estado emocional"
        }
        if signal.key.hasPrefix("weekday-drop:"), let worstWeekday = indicators.worstWeekday {
            return "\(weekdayName(for: worstWeekday)) com queda recorrente"
        }
        if signal.key.hasPrefix("period-drop:"), let worstPeriod = indicators.worstPeriod {
            return "Queda recorrente na \(dayPeriodName(for: worstPeriod))"
        }
        if signal.key.hasPrefix("trigger:"), let trigger = indicators.dominantNegativeTrigger {
            return "Gatilho recorrente: \(trigger.capitalized)"
        }
        return "Padrao recorrente detectado"
    }

    private func averageMoodScore(_ days: [BehaviorDailyAggregate]) -> Double? {
        let valid = days.filter { $0.moodEntries > 0 }
        guard !valid.isEmpty else { return nil }
        let dailyScores = valid.map(\.averageMoodScore)
        return robustAverage(dailyScores)
    }

    private func robustAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        if values.count < 5 {
            return values.reduce(0, +) / Double(values.count)
        }

        let sorted = values.sorted()
        let trimCount = max(1, Int(Double(sorted.count) * 0.10))
        let trimmed = sorted.dropFirst(trimCount).dropLast(trimCount)
        guard !trimmed.isEmpty else {
            return sorted.reduce(0, +) / Double(sorted.count)
        }
        return trimmed.reduce(0, +) / Double(trimmed.count)
    }

    private func recentDeclineDays(in days: [BehaviorDailyAggregate]) -> Int {
        let validDays = days
            .filter { $0.moodEntries > 0 }
            .sorted { $0.dayKey < $1.dayKey }
        guard validDays.count >= 2 else { return 0 }

        let trailing = Array(validDays.suffix(4))
        guard trailing.count >= 2 else { return 0 }

        var decline = 0
        for index in stride(from: trailing.count - 1, to: 0, by: -1) {
            let current = trailing[index].averageMoodScore
            let previous = trailing[index - 1].averageMoodScore
            if current <= previous - 0.10 {
                decline += 1
            } else {
                break
            }
        }
        return decline
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func weekdayName(for weekday: Int) -> String {
        let weekdays = [
            1: "Domingo",
            2: "Segunda",
            3: "Terca",
            4: "Quarta",
            5: "Quinta",
            6: "Sexta",
            7: "Sabado"
        ]
        return weekdays[weekday] ?? "Dia"
    }

    private func dayPeriodName(for period: BehaviorDayPeriod) -> String {
        switch period {
        case .morning:
            return "manha"
        case .afternoon:
            return "tarde"
        case .evening:
            return "noite"
        case .night:
            return "madrugada"
        }
    }

    private func startOfDay(addingDays offset: Int, from date: Date) -> Date {
        let base = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: offset, to: base) ?? base
    }
}
