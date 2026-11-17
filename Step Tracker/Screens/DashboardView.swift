//
//  DashboardView.swift
//  Step Tracker
//
//  Created by Jeremiah Animaku on 9/22/26.
//

import SwiftUI
import Charts
import HealthKit

enum HealthMetricContext: CaseIterable, Identifiable {
    case steps, weight

    var id: Self { self }

    var title: String {
        switch self {
        case .steps:
            return "Steps"
        case .weight:
            return "Weight"
        }
    }
}

struct DashboardView: View {

    @Environment(HealthKitManager.self) private var hkManager

    @AppStorage("hasSeenPermissionPriming")
    private var hasSeenPermissionPriming = false

    @State private var isShowingPermissionPrimingSheet = false
    @State private var selectedStat: HealthMetricContext = .steps

    var isSteps: Bool {
        selectedStat == .steps
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Selected Stat", selection: $selectedStat) {
                        ForEach(HealthMetricContext.allCases) { metric in
                            Text(metric.title)
                                .tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedStat {
                    case .steps:
                        StepBarChart(
                            selectedStat: selectedStat,
                            chartData: hkManager.stepData
                        )

                        StepPieChart(
                            chartData: ChartMath.averageWeekdayCount(
                                for: hkManager.stepData
                            )
                        )

                    case .weight:
                        WeightLineChart(
                            selectedStat: selectedStat,
                            chartData: hkManager.weightData
                        )

                        WeightDiffBarChart(
                            chartData: ChartMath.averageDailyWeightDiffs(
                                for: hkManager.weightDiffData
                            )
                        )
                    }
                }
                .padding()
            }
            .task {
                await loadDashboard()
            }
            .navigationTitle("Dashboard")
            .navigationDestination(for: HealthMetricContext.self) { metric in
                HealthDataListView(metric: metric)
            }
            .sheet(
                isPresented: $isShowingPermissionPrimingSheet,
                onDismiss: {
                    Task {
                        await hkManager.fetchAllData()
                    }
                }
            ) {
                HealthKitPermissionPrimingView(
                    hasSeen: $hasSeenPermissionPriming
                )
            }
        }
        .tint(isSteps ? .pink : .indigo)
    }

    @MainActor
    private func loadDashboard() async {
        // Canvas previews use in-memory mock data.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return
        }

        #if DEBUG && targetEnvironment(simulator)
        do {
            try await hkManager.store.requestAuthorization(
                toShare: hkManager.types,
                read: hkManager.types
            )

            let seedKey = "didSeedSimulatorHealthDataV1"

            if !UserDefaults.standard.bool(forKey: seedKey) {
                try await hkManager.addSimulatorData()
                UserDefaults.standard.set(true, forKey: seedKey)
            }

            await hkManager.fetchAllData()

            print("Steps: \(hkManager.stepData.count)")
            print("Weights: \(hkManager.weightData.count)")
            print("Weights for differences: \(hkManager.weightDiffData.count)")
        } catch {
            print("❌ Simulator data setup failed: \(error)")
        }
        #else
        if hasSeenPermissionPriming {
            await hkManager.fetchAllData()
        } else {
            isShowingPermissionPrimingSheet = true
        }
        #endif
    }
}

#Preview {
    let manager = HealthKitManager()
    let weights = MockData.weights.sorted { $0.date < $1.date }

    manager.stepData = MockData.steps.sorted { $0.date < $1.date }
    manager.weightData = weights
    manager.weightDiffData = weights

    return DashboardView()
        .environment(manager)
}
