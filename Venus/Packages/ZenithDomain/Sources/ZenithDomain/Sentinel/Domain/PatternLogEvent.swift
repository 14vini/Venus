import Foundation

enum PatternLogEventKind: String, Codable, Hashable, Sendable {
    case energyCheckInRecorded
    case stuckSignalRegistered
    case recoveryActionLogged
    case manualOverloadSignalRegistered
    case highEnergyStreakDetected
    case criticalEnergyStreakDetected
    case weeklySweepCompleted
}

enum PatternSeverity: String, Codable, Hashable, Sendable {
    case neutral
    case positive
    case warning
    case critical
}

struct PatternLogEvent: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: PatternLogEventKind
    let severity: PatternSeverity
    let summary: String
    let metadata: [String: String]
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: PatternLogEventKind,
        severity: PatternSeverity = .neutral,
        summary: String,
        metadata: [String: String] = [:],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.severity = severity
        self.summary = summary
        self.metadata = metadata
        self.createdAt = createdAt
    }
}

