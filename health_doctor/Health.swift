//
//  Health.swift
//  health_doctor
//
//  Created by Sebastian Böhler on 16.07.25.
//
//  A tiny helper that handles HealthKit authorisation and simple data queries (steps & sleep).
//  This file purposefully keeps the public surface very small so you can see how complex — or
//  rather *un*complex — it is to fetch common HealthKit metrics.
//
//  All calls use Swift Concurrency and therefore compile on iOS 15+. If you target an older
//  deployment you can easily wrap the async code in completion-handler shims.
//

import Foundation
import HealthKit

@MainActor
final class Health {
    static let shared = Health()
    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Authorisation

    /// Requests read authorisation for the types we care about (steps & sleep).
    /// Call this once early in your app lifecycle (e.g. `.task` on the first screen).
    func requestAuthorisation() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.healthDataUnavailable
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!  // calories
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
    }

    // MARK: - Active Energy

    /// Returns active calories burned (kcal) for today.
    func activeEnergyBurnedToday() async throws -> Double {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Step Count

    /// Returns the *cumulative* step count for today.
    func stepCountToday() async throws -> Double {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType,
                                          quantitySamplePredicate: predicate,
                                          options: .cumulativeSum) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: sum)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Last 7 Days Steps

    /// Lightweight model used for charting daily step counts.
    struct DailyStepCount: Identifiable {
        let date: Date
        let count: Double
        var id: Date { date }
    }

    /// Returns an array of `DailyStepCount` for the last seven *completed* days including today.
    /// The items are sorted ascending by date (oldest first) so that they can be used directly in `ForEach` / `Chart`.
    func stepCountsLast7Days() async throws -> [DailyStepCount] {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else {
            return []
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            // Use per-day statistics so we can directly display the values.
            var interval = DateComponents()
            interval.day = 1

            let query = HKStatisticsCollectionQuery(quantityType: stepType,
                                                    quantitySamplePredicate: predicate,
                                                    options: .cumulativeSum,
                                                    anchorDate: calendar.startOfDay(for: startDate),
                                                    intervalComponents: interval)

            query.initialResultsHandler = { _, collection, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                var results: [DailyStepCount] = []
                collection.enumerateStatistics(from: startDate, to: endDate) { statistic, _ in
                    let count = statistic.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    results.append(DailyStepCount(date: statistic.startDate, count: count))
                }
                continuation.resume(returning: results)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep

    /// Convenience helper that returns the total **hours asleep** (\"asleep\" category) for last night.
    func sleepHoursLastNight() async throws -> Double {
        let samples = try await lastNightSleepSamples()
        let asleepValue = HKCategoryValueSleepAnalysis.asleep.rawValue
        let seconds = samples
            .filter { $0.value == asleepValue }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return seconds / 3600.0
    }

    /// Returns an array of `HKCategorySample` representing last night’s sleep sessions.
    /// The sample array is **not** processed; this keeps the helper generic. On the UI side you
    /// can interpret `value == HKCategoryValueSleepAnalysis.inBed.rawValue` etc.
    func lastNightSleepSamples() async throws -> [HKCategorySample] {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) else {
            return []
        }
        let startOfYesterday = Calendar.current.startOfDay(for: yesterday)
        let predicate = HKQuery.predicateForSamples(withStart: startOfYesterday, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType,
                                      predicate: predicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: nil) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Errors

    enum HealthError: Error {
        case healthDataUnavailable
    }
}
