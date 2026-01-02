//
//  Cribbage_ScorerApp.swift
//  Cribbage Scorer
//
//  Created by Robert Bye on 02/01/2026.
//

import SwiftUI
import CoreData

@main
struct Cribbage_ScorerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
