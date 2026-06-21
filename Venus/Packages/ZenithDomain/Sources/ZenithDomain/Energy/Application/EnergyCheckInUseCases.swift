import Foundation

protocol EnergyCheckInRepositoryProtocol {
    func save(_ checkIn: EnergyCheckIn) async throws
    func fetchLatest() async throws -> EnergyCheckIn?
    func fetchCheckIns(in interval: DateInterval) async throws -> [EnergyCheckIn]
}

struct RecordEnergyCheckInInput: Sendable {
    let energyLevel: EnergyLevel
    let note: String?
    let source: EnergyCheckInSource

    init(
        energyLevel: EnergyLevel,
        note: String? = nil,
        source: EnergyCheckInSource = .manual
    ) {
        self.energyLevel = energyLevel
        self.note = note
        self.source = source
    }
}

protocol RecordEnergyCheckInUseCaseProtocol {
    func execute(_ input: RecordEnergyCheckInInput) async throws -> EnergyCheckIn
}

protocol FetchWeeklyEnergyCheckInsUseCaseProtocol {
    func execute(referenceDate: Date) async throws -> [EnergyCheckIn]
}

