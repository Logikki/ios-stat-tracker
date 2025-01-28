//
//  stat_trackerApp.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

@main
struct stat_trackerApp: App {
    let persistenceController = PersistenceController.shared
    let factory = AppViewModelFactory()

    var body: some Scene {
        WindowGroup {
            ContentView(factory: factory)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
