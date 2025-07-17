//
//  ContentView.swift
//  health_doctor
//
//  Created by Sebastian Böhler on 16.07.25.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var stepsToday: Int = 0
    @State private var caloriesToday: Int = 0
    @State private var sleepHours: Double = 0
    @State private var last7DaysSteps: [Health.DailyStepCount] = []
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
            Text("Steps today: \(stepsToday)")
            Text("Active kcal today: \(caloriesToday)")
            Text(String(format: "Sleep hours last night: %.1f", sleepHours))
            if let errorMessage {
                Text(errorMessage).foregroundColor(.red)
            }
                if !last7DaysSteps.isEmpty {
                    Chart(last7DaysSteps) { item in
                        BarMark(
                            x: .value("Day", item.date, unit: .day),
                            y: .value("Steps", item.count)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .frame(height: 160)
                    .padding(.vertical)
                }
            }
        }
        .padding()
        .task {
            await loadHealth()
        }
    }

    private func loadHealth() async {
        do {
            try await Health.shared.requestAuthorisation()
            async let steps = Health.shared.stepCountToday()
            async let kcal = Health.shared.activeEnergyBurnedToday()
            async let sleep = Health.shared.sleepHoursLastNight()
            async let last7 = Health.shared.stepCountsLast7Days()

            self.stepsToday = Int(try await steps)
            self.caloriesToday = Int(try await kcal)
            self.sleepHours = try await sleep
            self.last7DaysSteps = try await last7
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}

