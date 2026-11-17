//
//  HealthKitManager.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 11/10/26.
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
class HealthKitManager {

    let store = HKHealthStore()

    let types: Set<HKQuantityType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.bodyMass)
    ]

    var stepData: [HealthMetric] = []
    var weightData: [HealthMetric] = []
    var weightDiffData: [HealthMetric] = []

    func fetchStepCount() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let endDate = calendar.date(
            byAdding: .day, value: 1, to: today
        )!
        let startDate = calendar.date(
            byAdding: .day, value: -28, to: endDate
        )!

        let queryPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )

        let samplePredicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.stepCount),
            predicate: queryPredicate
        )

        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum,
            anchorDate: endDate,
            intervalComponents: .init(day: 1)
        )

        do {
            let results = try await query.result(for: store)

            stepData = results.statistics().map {
                HealthMetric(
                    date: $0.startDate,
                    value: $0.sumQuantity()?.doubleValue(for: .count()) ?? 0
                )
            }
            .sorted { $0.date < $1.date }
        } catch {
            print("❌ Failed to fetch steps: \(error)")
        }
    }

    func fetchWeights() async {
        do {
            weightData = try await fetchWeightMeasurements(days: 28)
        } catch {
            print("❌ Failed to fetch weights: \(error)")
        }
    }

    func fetchWeightForDifferentials() async {
        do {
            weightDiffData = try await fetchWeightMeasurements(days: 29)
        } catch {
            print("❌ Failed to fetch differential weights: \(error)")
        }
    }

    func fetchAllData() async {
        await fetchStepCount()
        await fetchWeights()
        await fetchWeightForDifferentials()
    }

    private func fetchWeightMeasurements(
        days: Int
    ) async throws -> [HealthMetric] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let endDate = calendar.date(
            byAdding: .day, value: 1, to: today
        )!
        let startDate = calendar.date(
            byAdding: .day, value: -days, to: endDate
        )!

        let queryPredicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate
        )

        let samplePredicate = HKSamplePredicate.quantitySample(
            type: HKQuantityType(.bodyMass),
            predicate: queryPredicate
        )

        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: samplePredicate,
            options: .mostRecent,
            anchorDate: endDate,
            intervalComponents: .init(day: 1)
        )

        let results = try await query.result(for: store)

        // Missing measurements should not become zero-pound weights.
        return results.statistics().compactMap { statistic -> HealthMetric? in
            guard let quantity = statistic.mostRecentQuantity() else {
                return nil
            }

            return HealthMetric(
                date: statistic.startDate,
                value: quantity.doubleValue(for: .pound())
            )
        }
        .sorted { $0.date < $1.date }
    }

    #if DEBUG && targetEnvironment(simulator)
    func addSimulatorData() async throws {
        var mockSamples: [HKQuantitySample] = []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        for i in 0..<29 {
            let stepQuantity = HKQuantity(
                unit: .count(),
                doubleValue: Double.random(in: 4_000...20_000)
            )

            let weightQuantity = HKQuantity(
                unit: .pound(),
                doubleValue: Double.random(
                    in: (160 + Double(i / 3))...(165 + Double(i / 3))
                )
            )

            let startDate = calendar.date(
                byAdding: .day,
                value: -i,
                to: today
            )!

            let endDate = calendar.date(
                byAdding: .second,
                value: 1,
                to: startDate
            )!

            mockSamples.append(
                HKQuantitySample(
                    type: HKQuantityType(.stepCount),
                    quantity: stepQuantity,
                    start: startDate,
                    end: endDate
                )
            )

            mockSamples.append(
                HKQuantitySample(
                    type: HKQuantityType(.bodyMass),
                    quantity: weightQuantity,
                    start: startDate,
                    end: endDate
                )
            )
        }

        try await store.save(mockSamples)
        print("✅ Simulator step and weight samples saved")
    }
    #endif
}
