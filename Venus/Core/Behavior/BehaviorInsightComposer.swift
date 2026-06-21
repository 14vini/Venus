//
//  BehaviorInsightComposer.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

struct BehaviorInsightComposer {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func composeWeeklyInsights(
        analysis: BehaviorPatternAnalysis,
        aggregates: [BehaviorDailyAggregate],
        referenceDate: Date
    ) -> WeeklyStrategicInsights {
        let negativeSignals = analysis.signals
            .filter { $0.impact < 0 }
        let negativeSignal = negativeSignals
            .sorted { leverageScore(of: $0) > leverageScore(of: $1) }
            .first

        let dominantTrigger = analysis.indicators.dominantNegativeTrigger?.capitalized
        let bestDay = analysis.indicators.bestWeekday.map(weekdayName(for:))
        let criticalWindow = analysis.indicators.worstPeriod.map {
            "Sua janela crítica recorrente é a \(dayPeriodName(for: $0))."
        }
        let sleepCounterfactual = sleepCounterfactualText(from: negativeSignals)
        let worstRecurringPattern: String
        if let negativeSignal {
            worstRecurringPattern = negativeSignal.detail
        } else if let worstPeriod = analysis.indicators.worstPeriod {
            worstRecurringPattern = "Maior oscilação emocional na \(dayPeriodName(for: worstPeriod))."
        } else {
            worstRecurringPattern = "Sem padrão negativo recorrente forte nesta semana."
        }

        let behavioralFocus: String
        if let negativeSignal {
            behavioralFocus = negativeSignal.suggestedFocus
        } else if analysis.indicators.hasHabitCorrelation {
            behavioralFocus = "Proteja dois hábitos-base diários para manter estabilidade emocional."
        } else {
            behavioralFocus = "Manter consistência de check-ins e executar 1 microação por dia."
        }
        let leverage = negativeSignal.map(leverageScore(of:)) ?? 0.22
        let streakQualityScore = calculateStreakQuality(from: aggregates, referenceDate: referenceDate)
        let recoveryProtocol = makeRecoveryProtocolIfNeeded(
            analysis: analysis,
            referenceDate: referenceDate
        )

        let confidenceBase = negativeSignal?.confidence ?? 0.45
        let confidence = min(1.0, max(0.35, confidenceBase))

        return WeeklyStrategicInsights(
            dominantTrigger: dominantTrigger,
            bestDay: bestDay,
            criticalWindow: criticalWindow,
            sleepCounterfactual: sleepCounterfactual,
            worstRecurringPattern: worstRecurringPattern,
            behavioralFocus: behavioralFocus,
            leverageScore: leverage,
            streakQualityScore: streakQualityScore,
            recoveryProtocol: recoveryProtocol,
            confidence: confidence
        )
    }

    func composeActionWhy(
        nextAction: NextBestAction,
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights,
        proForecast: ProMoodForecast?
    ) -> ActionWhyInsight {
        var evidence: [ActionWhyEvidence] = []

        let topNegativeSignals = analysis.signals
            .filter { $0.impact < 0 }
            .sorted { severity(of: $0) > severity(of: $1) }
            .prefix(2)

        for signal in topNegativeSignals {
            evidence.append(
                ActionWhyEvidence(
                    title: evidenceTitle(for: signal),
                    detail: signal.detail
                )
            )
        }

        evidence.append(
            ActionWhyEvidence(
                title: "Foco comportamental",
                detail: weeklyInsights.behavioralFocus
            )
        )

        if let forecast = proForecast,
           let dayOne = forecast.points.first(where: { $0.dayOffset == 1 }) {
            let delta = dayOne.actionDelta
            if delta > 0.02 {
                evidence.append(
                    ActionWhyEvidence(
                        title: "Impacto estimado em 24h",
                        detail: "Executar a micro-acao pode melhorar sua projecao em +\(delta.formatted(.number.precision(.fractionLength(2)))) no proximo dia."
                    )
                )
            }
        }

        if evidence.isEmpty {
            evidence.append(
                ActionWhyEvidence(
                    title: "Razao estrategica",
                    detail: nextAction.strategicReason
                )
            )
        }

        let summary = makeActionWhySummary(
            analysis: analysis,
            weeklyInsights: weeklyInsights
        )

        let signalConfidence = analysis.signals.first?.confidence ?? 0.45
        let forecastConfidence = proForecast?.confidence ?? 0.52
        let confidence = min(
            1.0,
            max(
                0.35,
                0.55 * signalConfidence +
                0.25 * weeklyInsights.confidence +
                0.20 * forecastConfidence
            )
        )

        return ActionWhyInsight(
            summary: summary,
            evidence: evidence,
            confidence: confidence
        )
    }

    private func severity(of signal: PatternSignal) -> Double {
        let base = abs(min(signal.impact, 0)) * signal.recurrence * signal.confidence
        return base * (0.55 + 0.45 * signal.controllability)
    }

    private func leverageScore(of signal: PatternSignal) -> Double {
        abs(min(signal.impact, 0))
            * signal.recurrence
            * signal.confidence
            * signal.controllability
    }

    private func sleepCounterfactualText(from signals: [PatternSignal]) -> String? {
        guard let sleepSignal = signals.first(where: { $0.key == "sleep-impact" && $0.impact < 0 }) else {
            return nil
        }
        let delta = abs(sleepSignal.impact)
        return "Nos dias com sono bom, seu score ficou +\(delta.formatted(.number.precision(.fractionLength(2)))) em média."
    }

    private func makeRecoveryProtocolIfNeeded(
        analysis: BehaviorPatternAnalysis,
        referenceDate: Date
    ) -> RecoveryProtocol? {
        let shouldActivate = analysis.indicators.recentDeclineDays >= 2
            || (analysis.weeklyTrend.direction == .declining && analysis.indicators.highStressDays >= 2)
        guard shouldActivate else { return nil }

        let weekday = weekdayName(for: calendar.component(.weekday, from: referenceDate))
        return RecoveryProtocol(
            title: "Protocolo de recuperação 48h",
            steps: [
                "Hoje (\(weekday)): conclua 1 tarefa curta de até 10 minutos.",
                "Nas próximas 24h: proteger janela de sono e reduzir estímulos noturnos.",
                "Nas próximas 48h: manter 2 hábitos-base e revisar sobrecarga da agenda."
            ]
        )
    }

    private func calculateStreakQuality(
        from aggregates: [BehaviorDailyAggregate],
        referenceDate: Date
    ) -> Double {
        let weekStart = calendar.date(
            byAdding: .day,
            value: -6,
            to: calendar.startOfDay(for: referenceDate)
        ) ?? referenceDate

        let weekDays = aggregates.filter { $0.dayKey >= weekStart && $0.dayKey <= referenceDate }
        guard !weekDays.isEmpty else { return 0.15 }

        let checkInDays = weekDays.filter { $0.moodEntries > 0 }.count
        let actionStartDays = weekDays.filter { !$0.actionStartedByKind.isEmpty }.count
        let actionCompletionDays = weekDays.filter { !$0.actionCompletedByKind.isEmpty }.count

        let checkInConsistency = Double(checkInDays) / 7.0
        let actionExecutionRate = Double(actionStartDays) / Double(max(1, checkInDays))
        let actionCompletionRate = Double(actionCompletionDays) / Double(max(1, actionStartDays))

        let score =
            0.50 * checkInConsistency +
            0.30 * actionExecutionRate +
            0.20 * actionCompletionRate

        return min(1.0, max(0.0, score))
    }

    private func weekdayName(for weekday: Int) -> String {
        let weekdays = [
            1: "Domingo",
            2: "Segunda",
            3: "Terça",
            4: "Quarta",
            5: "Quinta",
            6: "Sexta",
            7: "Sábado"
        ]
        return weekdays[weekday] ?? "Dia"
    }

    private func dayPeriodName(for period: BehaviorDayPeriod) -> String {
        switch period {
        case .morning:
            return "manhã"
        case .afternoon:
            return "tarde"
        case .evening:
            return "noite"
        case .night:
            return "madrugada"
        }
    }

    private func evidenceTitle(for signal: PatternSignal) -> String {
        if signal.key == "sleep-impact" {
            return "Padrão de sono"
        }
        if signal.key == "emotional-procrastination" {
            return "Execução sob carga emocional"
        }
        if signal.key == "habit-correlation" {
            return "Consistência de hábitos"
        }
        if signal.key == "low-clarity-stress" {
            return "Clareza e estresse"
        }
        if signal.key.hasPrefix("trigger:") {
            return "Gatilho recorrente"
        }
        if signal.key.hasPrefix("weekday-drop:") {
            return "Dia da semana com queda"
        }
        if signal.key.hasPrefix("period-drop:") {
            return "Janela crítica do dia"
        }
        return "Padrão detectado"
    }

    private func makeActionWhySummary(
        analysis: BehaviorPatternAnalysis,
        weeklyInsights: WeeklyStrategicInsights
    ) -> String {
        let mirrorEngine = MirrorEngine()
        let insight = mirrorEngine.generateReflection(insights: weeklyInsights, analysis: analysis)
        return insight.reflectionText
    }
}
