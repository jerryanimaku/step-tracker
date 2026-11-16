//
//  Step_TrackerApp.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 9/22/26.
//

import SwiftUI

@main
struct Step_TrackerApp: App {

    let hkManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(hkManager)
        }
    }
}
