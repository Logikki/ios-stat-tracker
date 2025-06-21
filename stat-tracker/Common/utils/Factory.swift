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
class ViewModeFactoryImpl: ObservableObject, ViewModelFactory {
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
        AuthViewModel(
            authenticationManager: authManager,
            userManager: userManager
        )
    }
    public func createSettingsViewModel() -> SettingsViewModel{
        return SettingsViewModel(authenticationManager: self.authManager)
    }
}
