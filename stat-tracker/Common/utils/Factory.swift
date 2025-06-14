//
//  Factory.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

// MARK: - Factory Protocol
protocol ViewModelFactory: ObservableObject {
    func createAuthViewModel() -> AuthViewModel
    // Add methods for other view models here, e.g.:
    // func createAddGameViewModel() -> AddGameViewModel
    // func createStatsViewModel() -> StatsViewModel
}

// MARK: - Concrete Factory
class AppViewModelFactory: ObservableObject, ViewModelFactory {
    private let teamsManager: TeamsManager
    private let userManager: UserManagerImpl
    private var authManager: AuthenticationManagerImpl

    public init(
        teamsManager: TeamsManager = TeamsManagerImpl(),
        authManager: AuthenticationManagerImpl,
        userManager: UserManagerImpl
    ) {
        self.teamsManager = teamsManager
        self.authManager = authManager
        self.userManager = userManager
    }
    
    public func createAuthViewModel() -> AuthViewModel {
        // This creates a new AuthViewModel using the injected managers.
        // In your current setup, AuthViewModel is also an @EnvironmentObject,
        // so this method might primarily be used for testing or specific non-global flows.
        AuthViewModel(
            authenticationManager: authManager,
            userManager: userManager
        )
    }
}
