import Combine
import Foundation

@MainActor
final class ZenithHomeViewModel: ObservableObject {
    @Published private(set) var latestCheckIn: EnergyCheckIn?
    @Published private(set) var currentInsight: SentinelInsight
    @Published private(set) var activeTrigger: PrimaryTrigger?
    @Published private(set) var debugEvents: [PatternLogEvent]

    private let calendar: Calendar
    private let nowProvider: () -> Date

    init(
        calendar: Calendar = .current,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.nowProvider = nowProvider
        self.currentInsight = SentinelInsight(
            title: "Sentinela em espera",
            message: "Assim que voce registrar energia ou sinalizar um travamento, o motor comeca a montar seus padroes invisiveis.",
            severity: .neutral
        )
        self.activeTrigger = nil
        self.debugEvents = []
    }

    var greetingTitle: String {
        if let latestCheckIn {
            return "Energia \(latestCheckIn.energyLevel.displayName.lowercased()) registrada"
        }

        return "Como esta sua bateria hoje?"
    }

    var greetingSubtitle: String {
        latestCheckIn?.energyLevel.supportCopy
        ?? "O Zenith comeca pelo estado real de hoje, sem empilhar culpa nem expectativas antigas."
    }

    func selectEnergyLevel(_ level: EnergyLevel) {
        let checkIn = EnergyCheckIn(energyLevel: level)
        latestCheckIn = checkIn

        appendEvent(
            PatternLogEvent(
                kind: .energyCheckInRecorded,
                severity: severity(for: level),
                summary: "Check-in registrado como \(level.displayName).",
                metadata: ["energyLevel": level.rawValue],
                createdAt: checkIn.createdAt
            )
        )

        currentInsight = makeImmediateInsight(for: level, referenceDate: checkIn.createdAt)
    }

    func registerStuckMoment() {
        let event = PatternLogEvent(
            kind: .stuckSignalRegistered,
            severity: .warning,
            summary: "Botao 'Travei' acionado para marcar friccao cognitiva.",
            metadata: ["source": "manual_debug"],
            createdAt: nowProvider()
        )
        appendEvent(event)
        currentInsight = SentinelInsight(
            title: "Friccao detectada",
            message: "O Sentinela marcou este momento para ajudar a reconhecer padroes de travamento, sem transformar isso em falha.",
            severity: .warning,
            createdAt: event.createdAt
        )
    }

    func registerRecoveryMoment() {
        let event = PatternLogEvent(
            kind: .recoveryActionLogged,
            severity: .positive,
            summary: "Momento de recuperacao registrado.",
            metadata: ["source": "manual_debug"],
            createdAt: nowProvider()
        )
        appendEvent(event)
        currentInsight = SentinelInsight(
            title: "Recuperacao reconhecida",
            message: "Esse tipo de evento vira evidencia util para o Sweep de 7 dias entender o que realmente te ajuda a voltar.",
            severity: .positive,
            createdAt: event.createdAt
        )
    }

    func runWeeklySweepPreview() {
        let now = nowProvider()
        let trigger = PrimaryTrigger(
            kind: .repeatedStuckPattern,
            summary: "Travamentos se concentraram apos dias de energia regular sem pausa de recuperacao.",
            evidence: "Nos ultimos 7 dias, os eventos de travamento apareceram com mais frequencia no fim da tarde.",
            detectedAt: now,
            validUntil: calendar.date(byAdding: .day, value: 7, to: now) ?? now,
            adjustment: SentinelAdjustment(
                key: "recovery_bias",
                value: "high",
                rationale: "Aumentar o peso de intervencoes de recuperacao durante a proxima semana."
            )
        )
        activeTrigger = trigger

        appendEvent(
            PatternLogEvent(
                kind: .weeklySweepCompleted,
                severity: .neutral,
                summary: "Sweep semanal concluido com gatilho primario ativo.",
                metadata: ["trigger": trigger.kind.rawValue],
                createdAt: now
            )
        )

        currentInsight = SentinelInsight(
            title: "Gatilho primario atualizado",
            message: "O app agora pode se proteger melhor nos proximos 7 dias com base nesse padrao.",
            severity: .neutral,
            createdAt: now
        )
    }

    private func appendEvent(_ event: PatternLogEvent) {
        debugEvents.insert(event, at: 0)
        if debugEvents.count > 12 {
            debugEvents = Array(debugEvents.prefix(12))
        }
    }

    private func makeImmediateInsight(for level: EnergyLevel, referenceDate: Date) -> SentinelInsight {
        switch level {
        case .critical:
            return SentinelInsight(
                title: "Modo protecao",
                message: "O Zenith deve favorecer recuperacao, menos carga e menos ruido visual a partir deste check-in.",
                severity: .critical,
                createdAt: referenceDate
            )
        case .regular:
            return SentinelInsight(
                title: "Ritmo sustentavel",
                message: "Hoje vale operar com foco estreito e pausas intencionais para evitar desgaste escondido.",
                severity: .neutral,
                createdAt: referenceDate
            )
        case .full:
            return SentinelInsight(
                title: "Energia cheia com freio de seguranca",
                message: "O Sentinela acompanha sequencias de energia alta para evitar que empolgacao vire sobrecarga depois.",
                severity: .positive,
                createdAt: referenceDate
            )
        }
    }

    private func severity(for level: EnergyLevel) -> PatternSeverity {
        switch level {
        case .critical:
            return .critical
        case .regular:
            return .neutral
        case .full:
            return .positive
        }
    }
}
