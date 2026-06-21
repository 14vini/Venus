//
//  PatternEngineUseCase.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

protocol PatternEngineUseCaseProtocol {
    func execute(referenceDate: Date) async throws -> PatternInsightsSnapshot?
}

final class PatternEngineUseCase: PatternEngineUseCaseProtocol {
    private let moodRepository: MoodRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let subscriptionStatusProvider: SubscriptionStatusProviderProtocol
    private let feedbackStore: BehaviorFeedbackStoreProtocol
    private let aggregateStore: BehaviorDailyAggregateStore
    private let snapshotCache: PatternSnapshotCache
    private let calendar: Calendar
    private let homeWindowDays: Int
    private let snapshotAlgorithmVersion: String

    init(
        moodRepository: MoodRepositoryProtocol,
        userProfileRepository: UserProfileRepositoryProtocol,
        subscriptionStatusProvider: SubscriptionStatusProviderProtocol,
        feedbackStore: BehaviorFeedbackStoreProtocol,
        aggregateStore: BehaviorDailyAggregateStore = BehaviorDailyAggregateStore(),
        snapshotCache: PatternSnapshotCache = PatternSnapshotCache(),
        calendar: Calendar = .current,
        homeWindowDays: Int = 21,
        snapshotAlgorithmVersion: String = "behavior-home-v6"
    ) {
        self.moodRepository = moodRepository
        self.userProfileRepository = userProfileRepository
        self.subscriptionStatusProvider = subscriptionStatusProvider
        self.feedbackStore = feedbackStore
        self.aggregateStore = aggregateStore
        self.snapshotCache = snapshotCache
        self.calendar = calendar
        self.homeWindowDays = homeWindowDays
        self.snapshotAlgorithmVersion = snapshotAlgorithmVersion
    }

    func execute(referenceDate: Date = Date()) async throws -> PatternInsightsSnapshot? {
        let dayKey = calendar.startOfDay(for: referenceDate)
        let windowStart = startOfDay(addingDays: -(homeWindowDays - 1), from: dayKey)
        let windowEnd = endOfDay(for: dayKey)
        let window = DateInterval(start: windowStart, end: windowEnd)

        async let moodsTask = moodRepository.getMoods(from: windowStart, to: referenceDate)
        async let profileTask = userProfileRepository.load()
        async let planTask = subscriptionStatusProvider.currentPlan()
        async let feedbackTask = feedbackStore.loadRecent(days: homeWindowDays, referenceDate: referenceDate)

        let moods = try await moodsTask
        guard !moods.isEmpty else {
            await snapshotCache.remove(dayKey: dayKey)
            return nil
        }

        let profile = try await profileTask
        let currentPlan = await planTask
        let feedbackRecords = await feedbackTask

        let profileContext = BehaviorEventIngestion.makeProfileContext(from: profile, calendar: calendar)
        let moodEvents = BehaviorEventIngestion.makeMoodEvents(from: moods, calendar: calendar)
        let todoEvents: [BehaviorTodoEvent] = []
        let feedbackEvents = BehaviorEventIngestion.makeFeedbackEvents(from: feedbackRecords, calendar: calendar)
        let activityBlueprints: [BehaviorActivityBlueprint] = []

        let dataVersion = makeDataVersion(
            dayKey: dayKey,
            moodEvents: moodEvents,
            todoEvents: todoEvents,
            feedbackEvents: feedbackEvents,
            activityBlueprints: activityBlueprints,
            profileContext: profileContext,
            plan: currentPlan
        )
        if let cachedSnapshot = await snapshotCache.snapshot(for: dayKey, dataVersion: dataVersion) {
            return cachedSnapshot
        }

        let actionHistory = await feedbackStore.actionHistorySummary(referenceDate: referenceDate, lookbackDays: 14)
        let latestMoodEvent = moodEvents.max(by: { $0.timestamp < $1.timestamp })
        let workerInput = PatternEngineWorkerInput(
            windowStart: window.start,
            windowEnd: window.end,
            referenceDate: referenceDate,
            dayKey: dayKey,
            calendarIdentifier: calendar.identifier,
            timeZoneIdentifier: calendar.timeZone.identifier,
            moodEvents: moodEvents,
            todoEvents: todoEvents,
            feedbackEvents: feedbackEvents,
            activityBlueprints: activityBlueprints,
            profileContext: profileContext,
            plan: currentPlan,
            latestMoodEvent: latestMoodEvent,
            actionHistory: actionHistory
        )

        let snapshot = await Task.detached(priority: .userInitiated) { [aggregateStore] in
            await PatternEngineUseCase.computeSnapshot(
                input: workerInput,
                aggregateStore: aggregateStore
            )
        }.value

        guard let snapshot else { return nil }
        await snapshotCache.store(dayKey: dayKey, dataVersion: dataVersion, snapshot: snapshot)
        await feedbackStore.trackSuggestion(action: snapshot.nextBestAction, at: referenceDate)
        return snapshot
    }

    private static func computeSnapshot(
        input: PatternEngineWorkerInput,
        aggregateStore: BehaviorDailyAggregateStore
    ) async -> PatternInsightsSnapshot? {
        var workerCalendar = Calendar(identifier: input.calendarIdentifier)
        if let timeZone = TimeZone(identifier: input.timeZoneIdentifier) {
            workerCalendar.timeZone = timeZone
        }

        let aggregates = await aggregateStore.update(
            window: DateInterval(start: input.windowStart, end: input.windowEnd),
            moodEvents: input.moodEvents,
            todoEvents: input.todoEvents,
            feedbackEvents: input.feedbackEvents
        )

        guard !aggregates.isEmpty else { return nil }
        let detector = BehaviorPatternDetector(calendar: workerCalendar)
        let analysis = detector.analyze(
            aggregates: aggregates,
            referenceDate: input.referenceDate,
            profile: input.profileContext
        )
        let baseline = Self.patternBaseline(from: aggregates, moodEvents: input.moodEvents)

        let latestAggregate = aggregates.last(where: { $0.dayKey == input.dayKey }) ?? aggregates.last
        let actionPolicyEngine = BehaviorActionPolicyEngine(calendar: workerCalendar)
        let actionSelection = actionPolicyEngine.selectRecommendations(
            latestMood: input.latestMoodEvent,
            latestAggregate: latestAggregate,
            analysis: analysis,
            profile: input.profileContext,
            history: input.actionHistory,
            referenceDate: input.referenceDate
        )
        let nextBestAction = actionSelection.primary

        let insightComposer = BehaviorInsightComposer(calendar: workerCalendar)
        let weeklyInsights = insightComposer.composeWeeklyInsights(
            analysis: analysis,
            aggregates: aggregates,
            referenceDate: input.referenceDate
        )
        let forecastEngine = BehaviorMoodForecastEngine(calendar: workerCalendar)
        let proForecast: ProMoodForecast?
        if input.plan == .pro && baseline.isReadyForWeeklyPatterns {
            proForecast = forecastEngine.makeForecast(
                aggregates: aggregates,
                moodEvents: input.moodEvents,
                analysis: analysis,
                nextAction: nextBestAction,
                actionHistory: input.actionHistory,
                referenceDate: input.referenceDate
            )
        } else {
            proForecast = nil
        }
        let actionWhy: ActionWhyInsight?
        let confidenceInsight: ConfidenceImprovementInsight?
        let triggerRecoveryInsight: TriggerRecoveryInsight?
        let exploreActionSuggestions: [ExploreActionSuggestion]

        if baseline.isReadyForWeeklyPatterns {
            actionWhy = insightComposer.composeActionWhy(
                nextAction: nextBestAction,
                analysis: analysis,
                weeklyInsights: weeklyInsights,
                proForecast: proForecast
            )
            confidenceInsight = Self.buildConfidenceInsight(
                analysis: analysis,
                weeklyInsights: weeklyInsights,
                aggregates: aggregates,
                actionHistory: input.actionHistory,
                profile: input.profileContext
            )
            triggerRecoveryInsight = Self.buildTriggerRecoveryInsight(
                analysis: analysis,
                weeklyInsights: weeklyInsights,
                confidenceInsight: confidenceInsight,
                latestMood: input.latestMoodEvent,
                nextAction: nextBestAction,
                proForecast: proForecast,
                profile: input.profileContext,
                referenceDate: input.referenceDate,
                plan: input.plan
            )
            exploreActionSuggestions = Self.buildExploreActionSuggestions(
                activities: input.activityBlueprints,
                analysis: analysis,
                nextAction: nextBestAction,
                latestMood: input.latestMoodEvent,
                profile: input.profileContext,
                actionHistory: input.actionHistory,
                referenceDate: input.referenceDate
            )
        } else {
            actionWhy = nil
            confidenceInsight = nil
            triggerRecoveryInsight = nil
            exploreActionSuggestions = []
        }

        return PatternInsightsSnapshot(
            nextBestAction: nextBestAction,
            alternativeActions: actionSelection.alternatives,
            weeklyTrend: analysis.weeklyTrend,
            patternAlert: baseline.isReadyForWeeklyPatterns ? analysis.primaryAlert : nil,
            weeklyInsights: baseline.isReadyForWeeklyPatterns ? weeklyInsights : nil,
            actionWhy: actionWhy,
            proMoodForecast: proForecast,
            confidenceInsight: confidenceInsight,
            triggerRecoveryInsight: triggerRecoveryInsight,
            exploreActionSuggestions: exploreActionSuggestions
        )
    }

    private static func patternBaseline(
        from aggregates: [BehaviorDailyAggregate],
        moodEvents: [BehaviorMoodEvent]
    ) -> PatternBaseline {
        let activeMoodDays = aggregates.filter { $0.moodEntries > 0 }.count
        return PatternBaseline(
            activeMoodDays: activeMoodDays,
            moodEntries: moodEvents.count
        )
    }

    private func makeDataVersion(
        dayKey: Date,
        moodEvents: [BehaviorMoodEvent],
        todoEvents: [BehaviorTodoEvent],
        feedbackEvents: [BehaviorActionFeedbackEvent],
        activityBlueprints: [BehaviorActivityBlueprint],
        profileContext: BehaviorProfileContext,
        plan: VenusPlan
    ) -> UInt64 {
        var digest = stableHash64(snapshotAlgorithmVersion)
        digest = combineHash(digest, stableHash64(String(Int(dayKey.timeIntervalSince1970))))
        digest = combineHash(digest, stableHash64(String(homeWindowDays)))

        digest = combineHash(digest, fingerprintMoodEvents(moodEvents))
        digest = combineHash(digest, fingerprintTodoEvents(todoEvents))
        digest = combineHash(digest, fingerprintFeedbackEvents(feedbackEvents))
        digest = combineHash(digest, fingerprintActivityBlueprints(activityBlueprints))
        digest = combineHash(digest, fingerprintProfile(profileContext))
        digest = combineHash(digest, stableHash64(plan.rawValue))
        return digest
    }

    private func startOfDay(addingDays offset: Int, from date: Date) -> Date {
        let base = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: offset, to: base) ?? base
    }

    private func endOfDay(for date: Date) -> Date {
        let dayStart = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        return nextDay.addingTimeInterval(-1)
    }

    private func fingerprintMoodEvents(_ events: [BehaviorMoodEvent]) -> UInt64 {
        var digest = stableHash64("moods:\(events.count)")
        for event in events {
            let timestampRaw = String(Int(event.timestamp.timeIntervalSince1970))
            let intensityRaw = String(event.intensity)
            let energyRaw = event.energyLevel?.rawValue ?? "-"
            let availableTimeRaw = event.availableTime?.rawValue ?? "-"
            let controlLevelRaw = event.controlLevel?.rawValue ?? "-"
            let sleepRaw = event.sleepQuality?.rawValue ?? "-"
            let clarityRaw = String(event.mentalClarity ?? -1)
            let stressRaw = String(event.stressSignalCount)
            let areaRaw = event.affectedArea ?? "-"
            let triggersRaw = event.triggers.joined(separator: ",")

            let eventRaw = "\(event.id.uuidString)|\(timestampRaw)|\(event.moodType.rawValue)|\(intensityRaw)|\(energyRaw)|\(availableTimeRaw)|\(controlLevelRaw)|\(sleepRaw)|\(clarityRaw)|\(stressRaw)|\(areaRaw)|\(triggersRaw)"
            digest = combineHash(digest, stableHash64(eventRaw))
        }
        return digest
    }

    private func fingerprintTodoEvents(_ events: [BehaviorTodoEvent]) -> UInt64 {
        var digest = stableHash64("todos:\(events.count)")
        for event in events {
            let eventRaw = [
                event.id.uuidString,
                String(Int(event.dayKey.timeIntervalSince1970)),
                event.type.rawValue,
                String(event.isCompleted),
                String(event.isSystemGenerated)
            ].joined(separator: "|")
            digest = combineHash(digest, stableHash64(eventRaw))
        }
        return digest
    }

    private func fingerprintFeedbackEvents(_ events: [BehaviorActionFeedbackEvent]) -> UInt64 {
        var digest = stableHash64("feedback:\(events.count)")
        for event in events {
            let eventRaw = [
                event.id.uuidString,
                String(Int(event.timestamp.timeIntervalSince1970)),
                event.kind.rawValue,
                event.stage.rawValue,
                String(event.perceivedRelief ?? -1)
            ].joined(separator: "|")
            digest = combineHash(digest, stableHash64(eventRaw))
        }
        return digest
    }

    private func fingerprintActivityBlueprints(_ blueprints: [BehaviorActivityBlueprint]) -> UInt64 {
        var digest = stableHash64("activities:\(blueprints.count)")
        for blueprint in blueprints {
            let raw = [
                blueprint.titleNormalized,
                blueprint.descriptionNormalized,
                blueprint.categoryNormalized,
                String(blueprint.durationMinutes),
                blueprint.iconName,
                blueprint.targetMoodKeys.sorted().joined(separator: ",")
            ].joined(separator: "|")
            digest = combineHash(digest, stableHash64(raw))
        }
        return digest
    }

    private func fingerprintProfile(_ profile: BehaviorProfileContext) -> UInt64 {
        let improvementAreasRaw = profile.improvementAreas.sorted().joined(separator: ",")
        let emotionalAreasRaw = profile.emotionalAreas.sorted().joined(separator: ",")
        let interestsRaw = profile.interests.sorted().joined(separator: ",")
        let workStartRaw = String(profile.workStartHour ?? -1)
        let workEndRaw = String(profile.workEndHour ?? -1)
        let studyStartRaw = String(profile.studyStartHour ?? -1)
        let studyEndRaw = String(profile.studyEndHour ?? -1)

        let profileRaw = [
            improvementAreasRaw,
            emotionalAreasRaw,
            interestsRaw,
            workStartRaw,
            workEndRaw,
            studyStartRaw,
            studyEndRaw
        ].joined(separator: "|")
        return stableHash64(profileRaw)
    }

    private func combineHash(_ lhs: UInt64, _ rhs: UInt64) -> UInt64 {
        var mixed = lhs ^ (rhs &+ 0x9E3779B97F4A7C15)
        mixed = (mixed << 7) | (mixed >> 57)
        mixed &*= 1_099_511_628_211
        return mixed
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
}

private struct PatternEngineWorkerInput: Sendable {
    let windowStart: Date
    let windowEnd: Date
    let referenceDate: Date
    let dayKey: Date
    let calendarIdentifier: Calendar.Identifier
    let timeZoneIdentifier: String
    let moodEvents: [BehaviorMoodEvent]
    let todoEvents: [BehaviorTodoEvent]
    let feedbackEvents: [BehaviorActionFeedbackEvent]
    let activityBlueprints: [BehaviorActivityBlueprint]
    let profileContext: BehaviorProfileContext
    let plan: VenusPlan
    let latestMoodEvent: BehaviorMoodEvent?
    let actionHistory: ActionHistorySummary
}

private struct PatternBaseline: Sendable {
    let activeMoodDays: Int
    let moodEntries: Int

    var isReadyForWeeklyPatterns: Bool {
        activeMoodDays >= 3 && moodEntries >= 4
    }
}

actor PatternSnapshotCache {
    private struct CacheEntry {
        let dataVersion: UInt64
        let snapshot: PatternInsightsSnapshot
        let cachedAt: Date
    }

    private var entriesByDay: [Date: CacheEntry] = [:]
    private let maxEntries = 8

    func snapshot(for dayKey: Date, dataVersion: UInt64) -> PatternInsightsSnapshot? {
        guard let entry = entriesByDay[dayKey] else { return nil }
        guard entry.dataVersion == dataVersion else { return nil }
        return entry.snapshot
    }

    func store(dayKey: Date, dataVersion: UInt64, snapshot: PatternInsightsSnapshot) {
        entriesByDay[dayKey] = CacheEntry(
            dataVersion: dataVersion,
            snapshot: snapshot,
            cachedAt: Date()
        )
        pruneIfNeeded()
    }

    func remove(dayKey: Date) {
        entriesByDay.removeValue(forKey: dayKey)
    }

    private func pruneIfNeeded() {
        guard entriesByDay.count > maxEntries else { return }
        let sortedDays = entriesByDay.keys.sorted { lhs, rhs in
            let lhsTime = entriesByDay[lhs]?.cachedAt ?? .distantPast
            let rhsTime = entriesByDay[rhs]?.cachedAt ?? .distantPast
            return lhsTime > rhsTime
        }
        for day in sortedDays.dropFirst(maxEntries) {
            entriesByDay.removeValue(forKey: day)
        }
    }
}
