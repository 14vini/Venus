//
//  BehaviorEventIngestion.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

enum BehaviorEventIngestion {
    static func makeProfileContext(
        from profile: UserProfile?,
        calendar: Calendar
    ) -> BehaviorProfileContext {
        guard let profile else { return .empty }

        return BehaviorProfileContext(
            improvementAreas: Set(profile.improvementAreas.map(BehaviorMoodScorer.normalize)),
            emotionalAreas: Set(profile.emotionalAreas.map(BehaviorMoodScorer.normalize)),
            interests: Set(profile.interests.map(BehaviorMoodScorer.normalize)),
            workStartHour: profile.workSchedule.map { calendar.component(.hour, from: $0.startTime) },
            workEndHour: profile.workSchedule.map { calendar.component(.hour, from: $0.endTime) },
            studyStartHour: profile.studySchedule.studies ? calendar.component(.hour, from: profile.studySchedule.startTime) : nil,
            studyEndHour: profile.studySchedule.studies ? calendar.component(.hour, from: profile.studySchedule.endTime) : nil
        )
    }

    static func makeMoodEvents(
        from moods: [Mood],
        calendar: Calendar
    ) -> [BehaviorMoodEvent] {
        moods.map { mood in
            BehaviorMoodEvent(
                id: mood.id,
                timestamp: mood.timestamp,
                dayKey: calendar.startOfDay(for: mood.timestamp),
                dayPeriod: period(for: mood.timestamp, calendar: calendar),
                moodType: mood.type,
                moodScore: BehaviorMoodScorer.score(for: mood),
                intensity: mood.intensity ?? 5,
                triggers: mood.triggers.map(BehaviorMoodScorer.normalize),
                affectedArea: mood.affectedArea.map { BehaviorMoodScorer.normalize($0.rawValue) },
                energyLevel: mood.energyLevel,
                availableTime: mood.availableTime,
                controlLevel: mood.controlLevel,
                mentalClarity: mood.mentalClarity,
                sleepQuality: mood.sleepQuality,
                stressSignalCount: BehaviorMoodScorer.stressSignalCount(in: mood.bodySignals)
            )
        }
    }

    static func makeTodoEvents(
        from todos: [TodoItem],
        calendar: Calendar
    ) -> [BehaviorTodoEvent] {
        todos.map { todo in
            BehaviorTodoEvent(
                id: todo.id,
                dayKey: calendar.startOfDay(for: todo.date),
                isCompleted: todo.isCompleted,
                type: todo.type,
                isSystemGenerated: todo.isSystemGenerated
            )
        }
    }

    static func makeFeedbackEvents(
        from records: [ActionFeedbackRecord],
        calendar: Calendar
    ) -> [BehaviorActionFeedbackEvent] {
        records.map { record in
            BehaviorActionFeedbackEvent(
                id: record.id,
                timestamp: record.timestamp,
                dayKey: calendar.startOfDay(for: record.timestamp),
                kind: record.kind,
                stage: record.stage,
                perceivedRelief: record.perceivedRelief
            )
        }
    }

    private static func period(for date: Date, calendar: Calendar) -> BehaviorDayPeriod {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 6..<12:
            return .morning
        case 12..<18:
            return .afternoon
        case 18..<24:
            return .evening
        default:
            return .night
        }
    }
}
