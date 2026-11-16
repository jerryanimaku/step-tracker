//
//  HealthKitManager.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 11/10/26.
//

import Foundation
import HealthKit
import Observation

@Observable class HealthKitManager {

    let store = HKHealthStore()

    let types: Set = [HKQuantityType(.stepCount), HKQuantityType(.bodyMass)]
}
