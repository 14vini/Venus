//
//  MoodModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import SwiftData

@Model
class MoodModel {
    @Attribute(.unique) var id: UUID
    var typeRawValue: String
    var intensity: Int?
    var triggersPayload: String?
    var affectedAreaRawValue: String?
    var energyLevelRawValue: String?
    var availableTimeRawValue: String?
    var controlLevelRawValue: String?
    var mentalClarity: Int?
    var sleepQualityRawValue: String?
    var bodySignalsPayload: String?
    var note: String?
    var timestamp: Date
    
    init(mood: Mood) {
        self.id = mood.id
        self.typeRawValue = mood.type.rawValue
        self.intensity = mood.intensity
        self.triggersPayload = Self.serializeStringArray(mood.triggers)
        self.affectedAreaRawValue = mood.affectedArea?.rawValue
        self.energyLevelRawValue = mood.energyLevel?.rawValue
        self.availableTimeRawValue = mood.availableTime?.rawValue
        self.controlLevelRawValue = mood.controlLevel?.rawValue
        self.mentalClarity = mood.mentalClarity
        self.sleepQualityRawValue = mood.sleepQuality?.rawValue
        self.bodySignalsPayload = Self.serializeStringArray(mood.bodySignals)
        self.note = mood.note
        self.timestamp = mood.timestamp
    }
    
    func toDomain() -> Mood? {
        guard let type = MoodType(rawValue: typeRawValue) else { return nil }
        let legacyMetadata = LegacyMoodNoteMetadata.parse(from: note)
        return Mood(
            id: id,
            type: type,
            intensity: intensity ?? legacyMetadata.intensity,
            triggers: Self.deserializeStringArray(from: triggersPayload) ?? legacyMetadata.triggers,
            affectedArea: affectedAreaRawValue.flatMap(MoodAffectedArea.init(rawValue:)),
            energyLevel: energyLevelRawValue.flatMap(MoodEnergyLevel.init(rawValue:)),
            availableTime: availableTimeRawValue.flatMap(MoodAvailableTime.init(rawValue:)),
            controlLevel: controlLevelRawValue.flatMap(MoodControlLevel.init(rawValue:)),
            mentalClarity: mentalClarity,
            sleepQuality: sleepQualityRawValue.flatMap(MoodSleepQuality.init(rawValue:)),
            bodySignals: Self.deserializeStringArray(from: bodySignalsPayload) ?? [],
            note: note,
            timestamp: timestamp
        )
    }

    private static func serializeStringArray(_ values: [String]) -> String? {
        guard !values.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(values) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func deserializeStringArray(from payload: String?) -> [String]? {
        guard let payload, !payload.isEmpty else { return nil }

        if let data = payload.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            return decoded.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }

        return payload
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct LegacyMoodNoteMetadata {
    let intensity: Int?
    let triggers: [String]

    static func parse(from note: String?) -> LegacyMoodNoteMetadata {
        guard let note else {
            return LegacyMoodNoteMetadata(intensity: nil, triggers: [])
        }

        var intensity: Int?
        var triggers: [String] = []

        if let intensityRange = note.range(of: #"\[intensity:(\d+)\]"#, options: .regularExpression) {
            let token = String(note[intensityRange])
                .replacingOccurrences(of: "[intensity:", with: "")
                .replacingOccurrences(of: "]", with: "")
            intensity = Int(token)
        }

        if let tagsRange = note.range(of: #"\[tags:([^\]]+)\]"#, options: .regularExpression) {
            let token = String(note[tagsRange])
                .replacingOccurrences(of: "[tags:", with: "")
                .replacingOccurrences(of: "]", with: "")
            triggers = token
                .split(separator: ",")
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }

        return LegacyMoodNoteMetadata(intensity: intensity, triggers: triggers)
    }
}
