//
//  Stat_trackerApp.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI
import CoreData

@main
struct Stat_trackerApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject var authenticationManager: AuthenticationManagerImpl
    @StateObject var appFactory: AppViewModelFactory

    init() {
        let authManager = AuthenticationManagerImpl()
        let authViewModel = AuthViewModel(authenticationManager: authManager)
        let factoryInstance = AppViewModelFactory(authManager: authManager)
        
        _authenticationManager = StateObject(wrappedValue: authManager)
        _appFactory = StateObject(wrappedValue: factoryInstance)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authenticationManager)
                .environmentObject(appFactory)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
