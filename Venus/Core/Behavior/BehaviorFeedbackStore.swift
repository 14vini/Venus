//
//  BehaviorFeedbackStore.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

protocol BehaviorFeedbackStoreProtocol {
    func trackSuggestion(kind: NextBestActionKind, at date: Date) async
    func trackStarted(kind: NextBestActionKind, at date: Date) async
    func trackCompleted(kind: NextBestActionKind, perceivedRelief: Int?, at date: Date) async
    func loadRecent(days: Int, referenceDate: Date) async -> [ActionFeedbackRecord]
    func actionHistorySummary(referenceDate: Date, lookbackDays: Int) async -> ActionHistorySummary
}

@MainActor
final class BehaviorFeedbackStore: BehaviorFeedbackStoreProtocol {
    private let defaults: UserDefaults
    private let key = "behavior.feedback.records.v1"
    private let maxStoredRecords = 800

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func trackSuggestion(kind: NextBestActionKind, at date: Date) async {
        await append(
            ActionFeedbackRecord(
                timestamp: date,
                kind: kind,
                stage: .suggested
            )
        )
    }

    func trackStarted(kind: NextBestActionKind, at date: Date) async {
        await append(
            ActionFeedbackRecord(
                timestamp: date,
                kind: kind,
                stage: .started
            )
        )
    }

    func trackCompleted(kind: NextBestActionKind, perceivedRelief: Int?, at date: Date) async {
        await append(
            ActionFeedbackRecord(
                timestamp: date,
                kind: kind,
                stage: .completed,
                perceivedRelief: perceivedRelief
            )
        )
    }

    func loadRecent(days: Int, referenceDate: Date) async -> [ActionFeedbackRecord] {
        guard days > 0 else { return [] }
        let start = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: referenceDate))
        guard let start else { return [] }
        return loadRecords()
            .filter { $0.timestamp >= start && $0.timestamp <= referenceDate }
            .sorted { $0.timestamp < $1.timestamp }
    }

    func actionHistorySummary(referenceDate: Date, lookbackDays: Int) async -> ActionHistorySummary {
        guard lookbackDays > 0 else { return .empty }
        let calendar = Calendar.current
        let start = Calendar.current.date(
            byAdding: .day,
            value: -(lookbackDays - 1),
            to: Calendar.current.startOfDay(for: referenceDate)
        ) ?? referenceDate
        let sevenDayStart = calendar.date(
            byAdding: .day,
            value: -6,
            to: calendar.startOfDay(for: referenceDate)
        ) ?? referenceDate

        let records = loadRecords()
            .filter { $0.timestamp >= start && $0.timestamp <= referenceDate }
            .sorted { $0.timestamp < $1.timestamp }

        guard !records.isEmpty else { return .empty }

        var lastSuggestedAt: [NextBestActionKind: Date] = [:]
        var suggestedKinds: [NextBestActionKind] = []
        var suggestedCategoryCountsLast7Days: [ActionSuggestionCategory: Int] = [:]
        var startedCountByKind: [NextBestActionKind: Int] = [:]
        var completedCountByKind: [NextBestActionKind: Int] = [:]
        var reliefSumByKind: [NextBestActionKind: Double] = [:]
        var reliefCountByKind: [NextBestActionKind: Int] = [:]

        for record in records {
            switch record.stage {
            case .suggested:
                lastSuggestedAt[record.kind] = record.timestamp
                suggestedKinds.append(record.kind)
                if record.timestamp >= sevenDayStart {
                    let category = record.kind.category
                    suggestedCategoryCountsLast7Days[category, default: 0] += 1
                }
            case .started:
                startedCountByKind[record.kind, default: 0] += 1
            case .completed:
                completedCountByKind[record.kind, default: 0] += 1
                if let perceivedRelief = record.perceivedRelief {
                    reliefSumByKind[record.kind, default: 0] += Double(perceivedRelief)
                    reliefCountByKind[record.kind, default: 0] += 1
                }
            }
        }

        var completionRateByKind: [NextBestActionKind: Double] = [:]
        for (kind, startedCount) in startedCountByKind {
            guard startedCount > 0 else { continue }
            let completed = completedCountByKind[kind, default: 0]
            completionRateByKind[kind] = Double(completed) / Double(startedCount)
        }

        var reliefAverageByKind: [NextBestActionKind: Double] = [:]
        for (kind, sum) in reliefSumByKind {
            let count = reliefCountByKind[kind, default: 0]
            guard count > 0 else { continue }
            reliefAverageByKind[kind] = sum / Double(count)
        }

        return ActionHistorySummary(
            lastSuggestedAt: lastSuggestedAt,
            recentSuggestedKinds: Array(suggestedKinds.suffix(8)),
            suggestedCategoryCountsLast7Days: suggestedCategoryCountsLast7Days,
            startedCountByKind: startedCountByKind,
            completionRateByKind: completionRateByKind,
            reliefAverageByKind: reliefAverageByKind
        )
    }

    private func append(_ record: ActionFeedbackRecord) async {
        var records = loadRecords()
        records.append(record)

        if records.count > maxStoredRecords {
            records = Array(records.suffix(maxStoredRecords))
        }

        saveRecords(records)
    }

    private func loadRecords() -> [ActionFeedbackRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        guard let records = try? JSONDecoder().decode([ActionFeedbackRecord].self, from: data) else { return [] }
        return records
    }

    private func saveRecords(_ records: [ActionFeedbackRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
