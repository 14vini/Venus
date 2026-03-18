//
//  BehaviorMoodScorer.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

enum BehaviorMoodScorer {
    nonisolated private static let canonicalAliases: [String: String] = [
        "job": "trabalho",
        "work": "trabalho",
        "wrk": "trabalho",
        "trab": "trabalho",
        "trablho": "trabalho",
        "trbalho": "trabalho",
        "sono": "sono",
        "sleep": "sono",
        "slp": "sono",
        "relationship": "relacionamentos",
        "relationships": "relacionamentos",
        "relacionamento": "relacionamentos",
        "relacionamentos": "relacionamentos",
        "familia": "familia",
        "family": "familia",
        "saude": "saude",
        "health": "saude",
        "estudo": "estudos",
        "estudos": "estudos",
        "study": "estudos",
        "studies": "estudos",
        "financa": "financas",
        "financas": "financas",
        "finance": "financas",
        "money": "financas"
    ]

    nonisolated static func score(for mood: Mood) -> Double {
        let base: Double
        switch mood.type {
        case .happy:
            base = 1.0
        case .energetic:
            base = 0.8
        case .calm:
            base = 0.5
        case .tired:
            base = -0.3
        case .sad:
            base = -0.9
        case .stressed:
            base = -1.1
        }

        let intensity = Double(mood.intensity ?? 5)
        let intensityImpact: Double = base >= 0
            ? max(0, intensity - 5) / 14
            : -max(0, intensity - 5) / 8

        let energyImpact: Double
        switch mood.energyLevel {
        case .low:
            energyImpact = -0.25
        case .medium:
            energyImpact = 0
        case .high:
            energyImpact = 0.20
        case nil:
            energyImpact = 0
        }

        let clarityImpact: Double
        if let clarity = mood.mentalClarity {
            clarityImpact = (Double(clarity) - 5) / 20
        } else {
            clarityImpact = 0
        }

        let sleepImpact: Double
        switch mood.sleepQuality {
        case .poor:
            sleepImpact = -0.35
        case .fair:
            sleepImpact = -0.15
        case .good:
            sleepImpact = 0.10
        case .excellent:
            sleepImpact = 0.22
        case nil:
            sleepImpact = 0
        }

        let stressSignals = stressSignalCount(in: mood.bodySignals)
        let bodyImpact = -min(Double(stressSignals) * 0.08, 0.30)

        return min(1.4, max(-1.8, base + intensityImpact + energyImpact + clarityImpact + sleepImpact + bodyImpact))
    }

    nonisolated static func stressSignalCount(in bodySignals: [String]) -> Int {
        guard !bodySignals.isEmpty else { return 0 }
        return bodySignals.filter { signal in
            let normalized = normalize(signal)
            return normalized.contains("tensao")
                || normalized.contains("respiracao curta")
                || normalized.contains("dor de cabeca")
                || normalized.contains("agitacao")
                || normalized.contains("cansaco")
                || normalized.contains("taquicardia")
        }.count
    }

    nonisolated static func normalize(_ value: String) -> String {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(of: "  ", with: " ")

        guard !normalized.isEmpty else { return normalized }
        if let mapped = canonicalAliases[normalized] {
            return mapped
        }
        if normalized.contains("work") || normalized.contains("job") || normalized.contains("trab") {
            return "trabalho"
        }
        if normalized.contains("sleep") || normalized.contains("sono") {
            return "sono"
        }
        if normalized.contains("relacion") || normalized.contains("relationship") {
            return "relacionamentos"
        }
        if normalized.contains("health") || normalized.contains("saude") {
            return "saude"
        }
        if normalized.contains("study") || normalized.contains("estud") {
            return "estudos"
        }
        if normalized.contains("finan") || normalized.contains("money") {
            return "financas"
        }
        return normalized
    }
}
