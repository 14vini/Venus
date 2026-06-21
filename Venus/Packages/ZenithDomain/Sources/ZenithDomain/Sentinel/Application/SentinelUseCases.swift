import Foundation

protocol PatternLogEventRepositoryProtocol {
    func append(_ event: PatternLogEvent) async throws
    func fetchLatest(limit: Int) async throws -> [PatternLogEvent]
    func fetchEvents(in interval: DateInterval) async throws -> [PatternLogEvent]
}

protocol PrimaryTriggerRepositoryProtocol {
    func saveCurrent(_ trigger: PrimaryTrigger) async throws
    func loadCurrent(referenceDate: Date) async throws -> PrimaryTrigger?
}

struct RegisterPatternLogEventInput: Sendable {
    let kind: PatternLogEventKind
    let severity: PatternSeverity
    let summary: String
    let metadata: [String: String]

    init(
        kind: PatternLogEventKind,
        severity: PatternSeverity = .neutral,
        summary: String,
        metadata: [String: String] = [:]
    ) {
        self.kind = kind
        self.severity = severity
        self.summary = summary
        self.metadata = metadata
    }
}

protocol RegisterPatternLogEventUseCaseProtocol {
    func execute(_ input: RegisterPatternLogEventInput) async throws -> PatternLogEvent
}

protocol EvaluateRealtimeSentinelAlertsUseCaseProtocol {
    func execute(referenceDate: Date) async throws -> SentinelInsight?
}

protocol RunWeeklySentinelSweepUseCaseProtocol {
    func execute(referenceDate: Date) async throws -> PrimaryTrigger?
}

