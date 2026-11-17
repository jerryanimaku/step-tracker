//
//  ChartMath.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 11/16/26.
//

import Foundation
import Algorithms

struct ChartMath {

    static func averageWeekdayCount(
        for metric: [HealthMetric]
    ) -> [WeekdayChartData] {
        let sortedByWeekday = metric.sorted {
            $0.date.weekdayInt < $1.date.weekdayInt
        }

        let weekdayArray = sortedByWeekday.chunked {
            $0.date.weekdayInt == $1.date.weekdayInt
        }

        var weekdayChartData: [WeekdayChartData] = []

        for array in weekdayArray {
            guard let firstValue = array.first else { continue }

            let total = array.reduce(0.0) { $0 + $1.value }
            let avgSteps = total / Double(array.count)

            weekdayChartData.append(
                .init(date: firstValue.date, value: avgSteps)
            )
        }

        return weekdayChartData
    }

    static func averageDailyWeightDiffs(
        for weights: [HealthMetric]
    ) -> [WeekdayChartData] {
        guard weights.count >= 2 else { return [] }

        let sortedWeights = weights.sorted {
            $0.date < $1.date
        }

        var diffValues: [(date: Date, value: Double)] = []

        for i in 1..<sortedWeights.count {
            let date = sortedWeights[i].date
            let diff = sortedWeights[i].value - sortedWeights[i - 1].value

            diffValues.append((date: date, value: diff))
        }

        let sortedByWeekday = diffValues.sorted {
            $0.date.weekdayInt < $1.date.weekdayInt
        }

        let weekdayArray = sortedByWeekday.chunked {
            $0.date.weekdayInt == $1.date.weekdayInt
        }

        var weekdayChartData: [WeekdayChartData] = []

        for array in weekdayArray {
            guard let firstValue = array.first else { continue }

            let total = array.reduce(0.0) { $0 + $1.value }
            let avgWeightDiff = total / Double(array.count)

            weekdayChartData.append(
                .init(date: firstValue.date, value: avgWeightDiff)
            )
        }

        return weekdayChartData
    }
}
