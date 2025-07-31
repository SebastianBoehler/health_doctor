//
//  health_doctorApp.swift
//  health_doctor
//
//  Created by Sebastian Böhler on 16.07.25.
//

import SwiftUI

@main
struct health_doctorApp: App {

    var body: some Scene {
        WindowGroup {
             TabView {
                 ContentView()
                     .tabItem {
                         Label("Dashboard", systemImage: "chart.bar")
                     }
                 LLMDemoView()
                     .tabItem {
                         Label("LLM Demo", systemImage: "sparkle")
                     }
             }
         }
        
    }
}
