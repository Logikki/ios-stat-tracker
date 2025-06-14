//
//  Stat_trackerApp.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

@main
struct Stat_trackerApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject var authenticationManager: AuthenticationManagerImpl
    @StateObject var userManager: UserManagerImpl
    
    @StateObject var appFactory: AppViewModelFactory

    @StateObject var appState: AppState

    init() {
        let authManager = AuthenticationManagerImpl()
        let userManager = UserManagerImpl(authenticationManager: authManager)
        let factoryInstance = AppViewModelFactory(authManager: authManager, userManager: userManager)
        let appStateInstance = AppState(authManager: authManager, userManager: userManager)

        _authenticationManager = StateObject(wrappedValue: authManager)
        _userManager = StateObject(wrappedValue: userManager)
        _appFactory = StateObject(wrappedValue: factoryInstance)
        _appState = StateObject(wrappedValue: appStateInstance)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.isLoadingInitialData {
                    LoadingScreen()
                } else if appState.showAuthView {
                    AuthView(viewModel: appFactory.createAuthViewModel())
                        .environmentObject(authenticationManager)
                } else {
                    AuthenticatedContentView()
                        .environmentObject(authenticationManager)
                        .environmentObject(userManager)
                        .environmentObject(appFactory)
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                }
            }

            .environmentObject(authenticationManager)
            .environmentObject(userManager)
            .environmentObject(appFactory)
            .environmentObject(appState)
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
