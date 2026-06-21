import Foundation

enum PrimaryTriggerKind: String, Codable, Hashable, Sendable {
    case criticalEnergyStreak
    case repeatedStuckPattern
    case unstableHighEnergyCycle
    case focusWithoutRecovery
    case healthyConsistency
}

struct SentinelAdjustment: Codable, Equatable, Sendable {
    let key: String
    let value: String
    let rationale: String

    init(key: String, value: String, rationale: String) {
        self.key = key
        self.value = value
        self.rationale = rationale
    }
}

struct PrimaryTrigger: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: PrimaryTriggerKind
    let summary: String
    let evidence: String
    let detectedAt: Date
    let validUntil: Date
    let adjustment: SentinelAdjustment

    init(
        id: UUID = UUID(),
        kind: PrimaryTriggerKind,
        summary: String,
        evidence: String,
        detectedAt: Date = Date(),
        validUntil: Date,
        adjustment: SentinelAdjustment
    ) {
        self.id = id
        self.kind = kind
        self.summary = summary
        self.evidence = evidence
        self.detectedAt = detectedAt
        self.validUntil = validUntil
        self.adjustment = adjustment
    }
}

struct SentinelInsight: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let title: String
    let message: String
    let severity: PatternSeverity
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        severity: PatternSeverity = .neutral,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.severity = severity
        self.createdAt = createdAt
    }
}

