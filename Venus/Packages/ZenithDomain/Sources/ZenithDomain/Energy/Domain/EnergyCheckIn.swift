import Foundation

enum EnergyLevel: String, Codable, CaseIterable, Hashable, Sendable {
    case critical
    case regular
    case full

    var displayName: String {
        switch self {
        case .critical:
            return "Critica"
        case .regular:
            return "Regular"
        case .full:
            return "Cheia"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .critical:
            return "battery.25"
        case .regular:
            return "battery.50"
        case .full:
            return "battery.100"
        }
    }

    var supportCopy: String {
        switch self {
        case .critical:
            return "Hoje o app deve proteger sua energia."
        case .regular:
            return "Hoje vale manter ritmo leve e intencional."
        case .full:
            return "Hoje ha espaco para avancar sem exagerar."
        }
    }
}

enum EnergyCheckInSource: String, Codable, Hashable, Sendable {
    case manual
    case imported
    case recoveryPrompt
}

struct EnergyCheckIn: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let energyLevel: EnergyLevel
    let note: String?
    let source: EnergyCheckInSource
    let createdAt: Date

    init(
        id: UUID = UUID(),
        energyLevel: EnergyLevel,
        note: String? = nil,
        source: EnergyCheckInSource = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.energyLevel = energyLevel
        self.note = note
        self.source = source
        self.createdAt = createdAt
    }
}

