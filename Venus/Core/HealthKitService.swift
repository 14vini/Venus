//
//  HealthKitService.swift
//  Venus
//
//  Created by Kaua on 25/09/26.
//

import Foundation
import HealthKit
import Combine

// MARK: - Biometric Models

public struct BiometricSnapshot: Sendable, Equatable {
    public let currentHRV: Double? // ms
    public let hrvBaseline7Days: Double? // ms (average of past 7 days)
    public let hrvBaselineDays: Int // quantos dias sustentam o baseline (exige >=3 p/ confianca)
    public let recoveryRatio: Double? // currentHRV / hrvBaseline7Days
    public let restingHeartRate: Double? // bpm
    public let sleepScore: Double? // 0.0 - 10.0 based on duration & deep/REM ratio
    public let deepAndREMHours: Double?
    public let totalSleepHours: Double?
    public let ecgSinusRhythm: Bool?
    public let hasLateNightScreenOveruse: Bool? // nil = DeviceActivity nao autorizado (planejado, ver spec)
    public let timestamp: Date

    public var dataFreshnessDate: Date { timestamp }

    public init(
        currentHRV: Double? = nil,
        hrvBaseline7Days: Double? = nil,
        hrvBaselineDays: Int = 0,
        recoveryRatio: Double? = nil,
        restingHeartRate: Double? = nil,
        sleepScore: Double? = nil,
        deepAndREMHours: Double? = nil,
        totalSleepHours: Double? = nil,
        ecgSinusRhythm: Bool? = nil,
        hasLateNightScreenOveruse: Bool? = nil,
        timestamp: Date = Date()
    ) {
        self.currentHRV = currentHRV
        self.hrvBaseline7Days = hrvBaseline7Days
        self.hrvBaselineDays = hrvBaselineDays
        self.recoveryRatio = recoveryRatio
        self.restingHeartRate = restingHeartRate
        self.sleepScore = sleepScore
        self.deepAndREMHours = deepAndREMHours
        self.totalSleepHours = totalSleepHours
        self.ecgSinusRhythm = ecgSinusRhythm
        self.hasLateNightScreenOveruse = hasLateNightScreenOveruse
        self.timestamp = timestamp
    }

    public var hasBiometricData: Bool {
        recoveryRatio != nil || sleepScore != nil || restingHeartRate != nil || currentHRV != nil
    }

    /// Baseline só é confiável com >=3 dias de amostras (evita ratio ruidoso no dia 1).
    public var hasReliableBaseline: Bool { hrvBaselineDays >= 3 && hrvBaseline7Days != nil }

    /// Idade dos dados em horas — se > 36h, a UI deve mostrar "dados desatualizados".
    public var dataAgeHours: Double { Date().timeIntervalSince(timestamp) / 3600.0 }
    public var isStale: Bool { dataAgeHours > 36 }

    public static let unavailable = BiometricSnapshot(timestamp: Date())
}

// MARK: - HealthKit Service Protocol

public protocol HealthKitServiceProtocol: Sendable {
    var isHealthDataAvailable: Bool { get }
    func requestAuthorization() async throws -> Bool
    func fetchBiometricSnapshot() async -> BiometricSnapshot
    func observeBiometricUpdates() -> AsyncStream<BiometricSnapshot>
}

// MARK: - HealthKit Service Implementation

public final class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    public static let shared = HealthKitService()

    private let healthStore: HKHealthStore?
    private var observerQueries: [HKObserverQuery] = []
    private var streamContinuations: [UUID: AsyncStream<BiometricSnapshot>.Continuation] = [:]
    private let lock = NSLock()

    public var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public init(healthStore: HKHealthStore? = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil) {
        self.healthStore = healthStore
    }

    // MARK: - Authorization

    public func requestAuthorization() async throws -> Bool {
        guard let healthStore = healthStore, isHealthDataAvailable else {
            return false
        }

        var typesToRead: Set<HKObjectType> = []

        if let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            typesToRead.insert(hrvType)
        }
        if let restingHRType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) {
            typesToRead.insert(restingHRType)
        }
        if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            typesToRead.insert(sleepType)
        }
        if #available(iOS 14.0, *) {
            let ecgType = HKObjectType.electrocardiogramType()
            typesToRead.insert(ecgType)
        }

        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }

    // MARK: - Fetch Biometric Snapshot

    public func fetchBiometricSnapshot() async -> BiometricSnapshot {
        guard let healthStore = healthStore, isHealthDataAvailable else {
            return .unavailable
        }

        async let latestHRV = fetchTodayAverageHRV()
        async let baseline7d = fetchHRV7DayBaseline()
        async let restingHR = fetchLatestRestingHeartRate()
        async let sleep = fetchLastNightSleepMetrics()
        async let ecg = fetchLatestECGClassification()

        let (todayHRV, baselineResult, rhr, sleepMetrics, ecgSinus) = await (latestHRV, baseline7d, restingHR, sleep, ecg)
        let baseline = baselineResult?.average
        let baselineDays = baselineResult?.days ?? 0

        // Ratio só é válido com baseline confiável (>=3 dias). Evita pico/vale no dia 1.
        let ratio: Double? = {
            guard let today = todayHRV, let base = baseline, base > 0, baselineDays >= 3 else { return nil }
            // Clamp para evitar outliers (relógio trocado, leitura errada)
            return max(0.5, min(1.6, today / base))
        }()

        return BiometricSnapshot(
            currentHRV: todayHRV,
            hrvBaseline7Days: baseline,
            hrvBaselineDays: baselineDays,
            recoveryRatio: ratio,
            restingHeartRate: rhr,
            sleepScore: sleepMetrics?.score,
            deepAndREMHours: sleepMetrics?.deepAndREMHours,
            totalSleepHours: sleepMetrics?.totalHours,
            ecgSinusRhythm: ecgSinus,
            hasLateNightScreenOveruse: nil,
            timestamp: Date()
        )
    }

    // MARK: - Live Real-time Observer

    public func observeBiometricUpdates() -> AsyncStream<BiometricSnapshot> {
        let streamId = UUID()
        return AsyncStream { continuation in
            lock.lock()
            streamContinuations[streamId] = continuation
            lock.unlock()

            continuation.onTermination = { [weak self] _ in
                guard let self = self else { return }
                self.lock.lock()
                self.streamContinuations.removeValue(forKey: streamId)
                self.lock.unlock()
            }

            // Trigger initial fetch
            Task {
                let initial = await self.fetchBiometricSnapshot()
                continuation.yield(initial)
            }

            self.setupBackgroundObserversIfNeeded()
        }
    }

    private func setupBackgroundObserversIfNeeded() {
        guard let healthStore = healthStore, observerQueries.isEmpty else { return }

        let sampleTypes: [HKSampleType?] = [
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        ]

        for sampleType in sampleTypes.compactMap({ $0 }) {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
                guard let self = self, error == nil else {
                    completionHandler()
                    return
                }

                Task {
                    let snapshot = await self.fetchBiometricSnapshot()
                    self.broadcastSnapshot(snapshot)
                    completionHandler()
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { _, _ in }
            observerQueries.append(query)
        }
    }

    private var lastBroadcastAt: Date = .distantPast
    private func broadcastSnapshot(_ snapshot: BiometricSnapshot) {
        // Throttle de 60s: HKObserverQuery pode disparar em rajada
        if Date().timeIntervalSince(lastBroadcastAt) < 60 { return }
        lastBroadcastAt = Date()
        lock.lock()
        let active = Array(streamContinuations.values)
        lock.unlock()

        for continuation in active {
            continuation.yield(snapshot)
        }
    }

    // MARK: - Private HealthKit Queries

    private func fetchTodayAverageHRV() async -> Double? {
        guard let healthStore = healthStore,
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let values = quantitySamples.map { $0.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                let average = values.reduce(0, +) / Double(values.count)
                continuation.resume(returning: average)
            }
            healthStore.execute(query)
        }
    }

    private struct HRVBaseline { let average: Double; let days: Int }
    private func fetchHRV7DayBaseline() async -> HRVBaseline? {
        guard let healthStore = healthStore,
              let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return nil
        }

        let calendar = Calendar.current
        guard let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: sevenDaysAgo,
            end: calendar.startOfDay(for: Date()),
            options: .strictStartDate
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Group by day to compute daily averages, then average across available days (hardware agnostic)
                var dailyBuckets: [Date: [Double]] = [:]
                for sample in quantitySamples {
                    let day = calendar.startOfDay(for: sample.startDate)
                    let val = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    dailyBuckets[day, default: []].append(val)
                }

                let dailyAverages = dailyBuckets.values.map { values in
                    values.reduce(0, +) / Double(values.count)
                }

                guard !dailyAverages.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let baseline = dailyAverages.reduce(0, +) / Double(dailyAverages.count)
                continuation.resume(returning: HRVBaseline(average: baseline, days: dailyAverages.count))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestRestingHeartRate() async -> Double? {
        guard let healthStore = healthStore,
              let rhrType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }

        let startOfYesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: rhrType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                guard let sample = (samples as? [HKQuantitySample])?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                continuation.resume(returning: bpm)
            }
            healthStore.execute(query)
        }
    }

    private struct SleepResult {
        let score: Double
        let deepAndREMHours: Double
        let totalHours: Double
    }

    private func fetchLastNightSleepMetrics() async -> SleepResult? {
        guard let healthStore = healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let startOfYesterdayEvening = calendar.date(byAdding: .hour, value: -18, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterdayEvening, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                guard let categorySamples = samples as? [HKCategorySample], !categorySamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                var totalSleepSeconds: TimeInterval = 0
                var restorativeSleepSeconds: TimeInterval = 0

                for sample in categorySamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)
                    if #available(iOS 16.0, *) {
                        switch sample.value {
                        case HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                             HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                            restorativeSleepSeconds += duration
                            totalSleepSeconds += duration
                        case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                            totalSleepSeconds += duration
                        default:
                            break
                        }
                    } else {
                        if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                            totalSleepSeconds += duration
                        }
                    }
                }

                let totalHours = totalSleepSeconds / 3600.0
                let restorativeHours = restorativeSleepSeconds / 3600.0

                guard totalHours > 0.5 else {
                    continuation.resume(returning: nil)
                    return
                }

                // Sleep score: 7-9 hours optimal, restorative >= 2.0h optimal
                var score = min(10.0, (totalHours / 7.5) * 8.0)
                if restorativeHours >= 1.8 {
                    score = min(10.0, score + 2.0)
                } else if restorativeHours >= 1.0 {
                    score = min(10.0, score + 1.0)
                }

                continuation.resume(returning: SleepResult(
                    score: max(1.0, min(10.0, score)),
                    deepAndREMHours: restorativeHours,
                    totalHours: totalHours
                ))
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestECGClassification() async -> Bool? {
        guard #available(iOS 14.0, *),
              let healthStore = healthStore else {
            return nil
        }

        let ecgType = HKObjectType.electrocardiogramType()
        let calendar = Calendar.current
        let startOf3DaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOf3DaysAgo, end: Date(), options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: ecgType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                guard let ecgSample = (samples as? [HKElectrocardiogram])?.first else {
                    continuation.resume(returning: nil)
                    return
                }
                let isSinus = ecgSample.classification == .sinusRhythm
                continuation.resume(returning: isSinus)
            }
            healthStore.execute(query)
        }
    }
}
