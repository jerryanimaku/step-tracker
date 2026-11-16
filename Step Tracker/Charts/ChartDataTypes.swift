//
//  ChartDataTypes.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 11/16/26.
//

import Foundation

struct WeekdayChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

