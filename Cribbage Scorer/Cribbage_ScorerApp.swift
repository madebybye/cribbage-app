//
//  Cribbage_ScorerApp.swift
//  Cribbage Scorer
//
//  Created by Robert Bye on 02/01/2026.
//

import SwiftUI

@main
struct Cribbage_ScorerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Keep screen awake when app is active
                UIApplication.shared.isIdleTimerDisabled = true
            case .background, .inactive:
                // Allow screen to lock when app goes to background
                UIApplication.shared.isIdleTimerDisabled = false
            @unknown default:
                break
            }
        }
    }
}
