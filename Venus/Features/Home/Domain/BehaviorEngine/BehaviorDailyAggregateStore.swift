//
//  BehaviorDailyAggregateStore.swift
//  Venus
//
//  Created by Kaua on 20/02/26.
//

import Foundation

actor BehaviorDailyAggregateStore {
    private var moodEventsByID: [UUID: BehaviorMoodEvent] = [:]
    private var todoEventsByID: [UUID: BehaviorTodoEvent] = [:]
    private var feedbackEventsByID: [UUID: BehaviorActionFeedbackEvent] = [:]
    private var aggregatesByDay: [Date: BehaviorDailyAggregate] = [:]
    private var currentWindow: DateInterval?

    func update(
        window: DateInterval,
        moodEvents: [BehaviorMoodEvent],
        todoEvents: [BehaviorTodoEvent],
        feedbackEvents: [BehaviorActionFeedbackEvent]
    ) -> [BehaviorDailyAggregate] {
        if shouldReset(window: window) {
            reset(window: window)
            fullIngest(
                moodEvents: moodEvents,
                todoEvents: todoEvents,
                feedbackEvents: feedbackEvents
            )
        } else {
            syncMoodEvents(moodEvents)
            syncTodoEvents(todoEvents)
            syncFeedbackEvents(feedbackEvents)
        }

        pruneAggregates(outside: window)
        return aggregatesByDay.values.sorted { $0.dayKey < $1.dayKey }
    }

    private func shouldReset(window: DateInterval) -> Bool {
        guard let currentWindow else { return true }
        return currentWindow.start != window.start || currentWindow.end != window.end
    }

    private func reset(window: DateInterval) {
        currentWindow = window
        moodEventsByID.removeAll(keepingCapacity: true)
        todoEventsByID.removeAll(keepingCapacity: true)
        feedbackEventsByID.removeAll(keepingCapacity: true)
        aggregatesByDay.removeAll(keepingCapacity: true)
    }

    private func fullIngest(
        moodEvents: [BehaviorMoodEvent],
        todoEvents: [BehaviorTodoEvent],
        feedbackEvents: [BehaviorActionFeedbackEvent]
    ) {
        for event in moodEvents {
            moodEventsByID[event.id] = event
            applyMood(event)
        }
        for event in todoEvents {
            todoEventsByID[event.id] = event
            applyTodo(event)
        }
        for event in feedbackEvents {
            feedbackEventsByID[event.id] = event
            applyFeedback(event)
        }
    }

    private func syncMoodEvents(_ events: [BehaviorMoodEvent]) {
        let incoming = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        for (id, oldEvent) in moodEventsByID where incoming[id] == nil {
            revertMood(oldEvent)
            moodEventsByID.removeValue(forKey: id)
        }

        for (id, newEvent) in incoming {
            if let oldEvent = moodEventsByID[id] {
                guard oldEvent != newEvent else { continue }
                revertMood(oldEvent)
                applyMood(newEvent)
                moodEventsByID[id] = newEvent
            } else {
                applyMood(newEvent)
                moodEventsByID[id] = newEvent
            }
        }
    }

    private func syncTodoEvents(_ events: [BehaviorTodoEvent]) {
        let incoming = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        for (id, oldEvent) in todoEventsByID where incoming[id] == nil {
            revertTodo(oldEvent)
            todoEventsByID.removeValue(forKey: id)
        }

        for (id, newEvent) in incoming {
            if let oldEvent = todoEventsByID[id] {
                guard oldEvent != newEvent else { continue }
                revertTodo(oldEvent)
                applyTodo(newEvent)
                todoEventsByID[id] = newEvent
            } else {
                applyTodo(newEvent)
                todoEventsByID[id] = newEvent
            }
        }
    }

    private func syncFeedbackEvents(_ events: [BehaviorActionFeedbackEvent]) {
        let incoming = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        for (id, oldEvent) in feedbackEventsByID where incoming[id] == nil {
            revertFeedback(oldEvent)
            feedbackEventsByID.removeValue(forKey: id)
        }

        for (id, newEvent) in incoming {
            if let oldEvent = feedbackEventsByID[id] {
                guard oldEvent != newEvent else { continue }
                revertFeedback(oldEvent)
                applyFeedback(newEvent)
                feedbackEventsByID[id] = newEvent
            } else {
                applyFeedback(newEvent)
                feedbackEventsByID[id] = newEvent
            }
        }
    }

    private func applyMood(_ event: BehaviorMoodEvent) {
        var aggregate = aggregatesByDay[event.dayKey] ?? BehaviorDailyAggregate(dayKey: event.dayKey)
        aggregate.moodEntries += 1
        aggregate.moodScoreSum += event.moodScore
        aggregate.intensitySum += Double(event.intensity)
        aggregate.stressSignalTotal += event.stressSignalCount
        incrementCount(&aggregate.moodCountByPeriod, key: event.dayPeriod)
        aggregate.moodScoreSumByPeriod[event.dayPeriod, default: 0] += event.moodScore

        switch event.energyLevel {
        case .low:
            aggregate.lowEnergyCount += 1
        case .medium:
            aggregate.mediumEnergyCount += 1
        case .high:
            aggregate.highEnergyCount += 1
        case nil:
            break
        }

        if let clarity = event.mentalClarity {
            aggregate.clarityCount += 1
            aggregate.claritySum += Double(clarity)
        }

        switch event.sleepQuality {
        case .poor:
            aggregate.sleepPoorCount += 1
        case .fair:
            aggregate.sleepFairCount += 1
        case .good:
            aggregate.sleepGoodCount += 1
        case .excellent:
            aggregate.sleepExcellentCount += 1
        case nil:
            break
        }

        for trigger in event.triggers {
            incrementCount(&aggregate.triggerCounts, key: trigger)
        }
        if let affectedArea = event.affectedArea {
            incrementCount(&aggregate.areaCounts, key: affectedArea)
        }
        incrementCount(&aggregate.moodTypeCounts, key: event.moodType)

        aggregatesByDay[event.dayKey] = aggregate
    }

    private func revertMood(_ event: BehaviorMoodEvent) {
        guard var aggregate = aggregatesByDay[event.dayKey] else { return }

        aggregate.moodEntries = max(0, aggregate.moodEntries - 1)
        aggregate.moodScoreSum -= event.moodScore
        aggregate.intensitySum -= Double(event.intensity)
        aggregate.stressSignalTotal = max(0, aggregate.stressSignalTotal - event.stressSignalCount)
        incrementCount(&aggregate.moodCountByPeriod, key: event.dayPeriod, by: -1)
        let periodScore = (aggregate.moodScoreSumByPeriod[event.dayPeriod] ?? 0) - event.moodScore
        if abs(periodScore) < 0.0001 {
            aggregate.moodScoreSumByPeriod.removeValue(forKey: event.dayPeriod)
        } else {
            aggregate.moodScoreSumByPeriod[event.dayPeriod] = periodScore
        }

        switch event.energyLevel {
        case .low:
            aggregate.lowEnergyCount = max(0, aggregate.lowEnergyCount - 1)
        case .medium:
            aggregate.mediumEnergyCount = max(0, aggregate.mediumEnergyCount - 1)
        case .high:
            aggregate.highEnergyCount = max(0, aggregate.highEnergyCount - 1)
        case nil:
            break
        }

        if let clarity = event.mentalClarity {
            aggregate.clarityCount = max(0, aggregate.clarityCount - 1)
            aggregate.claritySum -= Double(clarity)
        }

        switch event.sleepQuality {
        case .poor:
            aggregate.sleepPoorCount = max(0, aggregate.sleepPoorCount - 1)
        case .fair:
            aggregate.sleepFairCount = max(0, aggregate.sleepFairCount - 1)
        case .good:
            aggregate.sleepGoodCount = max(0, aggregate.sleepGoodCount - 1)
        case .excellent:
            aggregate.sleepExcellentCount = max(0, aggregate.sleepExcellentCount - 1)
        case nil:
            break
        }

        for trigger in event.triggers {
            incrementCount(&aggregate.triggerCounts, key: trigger, by: -1)
        }
        if let affectedArea = event.affectedArea {
            incrementCount(&aggregate.areaCounts, key: affectedArea, by: -1)
        }
        incrementCount(&aggregate.moodTypeCounts, key: event.moodType, by: -1)

        saveOrDeleteAggregate(aggregate)
    }

    private func applyTodo(_ event: BehaviorTodoEvent) {
        var aggregate = aggregatesByDay[event.dayKey] ?? BehaviorDailyAggregate(dayKey: event.dayKey)
        aggregate.todoTotal += 1
        if event.isCompleted {
            aggregate.todoCompleted += 1
        }
        if event.isSystemGenerated {
            aggregate.todoSystemGenerated += 1
        }
        if isHabitType(event.type) {
            aggregate.habitTotal += 1
            if event.isCompleted {
                aggregate.habitCompleted += 1
            }
        }
        incrementCount(&aggregate.todoByType, key: event.type)
        aggregatesByDay[event.dayKey] = aggregate
    }

    private func revertTodo(_ event: BehaviorTodoEvent) {
        guard var aggregate = aggregatesByDay[event.dayKey] else { return }
        aggregate.todoTotal = max(0, aggregate.todoTotal - 1)
        if event.isCompleted {
            aggregate.todoCompleted = max(0, aggregate.todoCompleted - 1)
        }
        if event.isSystemGenerated {
            aggregate.todoSystemGenerated = max(0, aggregate.todoSystemGenerated - 1)
        }
        if isHabitType(event.type) {
            aggregate.habitTotal = max(0, aggregate.habitTotal - 1)
            if event.isCompleted {
                aggregate.habitCompleted = max(0, aggregate.habitCompleted - 1)
            }
        }
        incrementCount(&aggregate.todoByType, key: event.type, by: -1)
        saveOrDeleteAggregate(aggregate)
    }

    private func applyFeedback(_ event: BehaviorActionFeedbackEvent) {
        var aggregate = aggregatesByDay[event.dayKey] ?? BehaviorDailyAggregate(dayKey: event.dayKey)

        switch event.stage {
        case .suggested:
            incrementCount(&aggregate.actionSuggestedByKind, key: event.kind)
        case .started:
            incrementCount(&aggregate.actionStartedByKind, key: event.kind)
        case .completed:
            incrementCount(&aggregate.actionCompletedByKind, key: event.kind)
            if let relief = event.perceivedRelief {
                aggregate.reliefCount += 1
                aggregate.reliefSum += Double(relief)
            }
        }

        aggregatesByDay[event.dayKey] = aggregate
    }

    private func revertFeedback(_ event: BehaviorActionFeedbackEvent) {
        guard var aggregate = aggregatesByDay[event.dayKey] else { return }

        switch event.stage {
        case .suggested:
            incrementCount(&aggregate.actionSuggestedByKind, key: event.kind, by: -1)
        case .started:
            incrementCount(&aggregate.actionStartedByKind, key: event.kind, by: -1)
        case .completed:
            incrementCount(&aggregate.actionCompletedByKind, key: event.kind, by: -1)
            if let relief = event.perceivedRelief {
                aggregate.reliefCount = max(0, aggregate.reliefCount - 1)
                aggregate.reliefSum -= Double(relief)
            }
        }

        saveOrDeleteAggregate(aggregate)
    }

    private func saveOrDeleteAggregate(_ aggregate: BehaviorDailyAggregate) {
        let isEmpty = aggregate.moodEntries == 0
            && aggregate.todoTotal == 0
            && aggregate.actionSuggestedByKind.isEmpty
            && aggregate.actionStartedByKind.isEmpty
            && aggregate.actionCompletedByKind.isEmpty
            && aggregate.reliefCount == 0

        if isEmpty {
            aggregatesByDay.removeValue(forKey: aggregate.dayKey)
        } else {
            aggregatesByDay[aggregate.dayKey] = aggregate
        }
    }

    private func pruneAggregates(outside window: DateInterval) {
        for (day, _) in aggregatesByDay where day < window.start || day > window.end {
            aggregatesByDay.removeValue(forKey: day)
        }
    }

    private func incrementCount<Key: Hashable>(
        _ dictionary: inout [Key: Int],
        key: Key,
        by value: Int = 1
    ) {
        let next = (dictionary[key] ?? 0) + value
        if next <= 0 {
            dictionary.removeValue(forKey: key)
        } else {
            dictionary[key] = next
        }
    }

    private func isHabitType(_ type: TodoType) -> Bool {
        type == .routine || type == .health
    }
}
