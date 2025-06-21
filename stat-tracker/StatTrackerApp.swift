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
    
    @StateObject var appState: AppState
    
    @StateObject var authenticationManager: AuthenticationManagerImpl
    @StateObject var userManager: UserManagerImpl
    @StateObject var appFactory: ViewModeFactoryImpl
    
    init() {
        let authManager = AuthenticationManagerImpl()
        let userManager = UserManagerImpl(authenticationManager: authManager)
        let factoryInstance = ViewModeFactoryImpl(authManager: authManager, userManager: userManager)
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
                } else if appState.errorMessage != nil {
                    
                }
                else {
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
            
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { appState.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            appState.clearError()
                        }
                    }
                )
            ) {
                Button("OK") {
                    appState.clearError()
                }
            } message: {
                // The message content for the alert
                Text(appState.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
}
