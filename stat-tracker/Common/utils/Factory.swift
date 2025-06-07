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
}

// MARK: - Concrete Factory
class AppViewModelFactory: ObservableObject, ViewModelFactory {
    private let teamsManager: TeamsManager
    private let playerManager: UserManager
    private var authManager: AuthenticationManagerImpl

    public init(
        teamsManager: TeamsManager = TeamsManagerImpl(),
        playerManager: UserManager = UserManagerImpl(),
        authManager: AuthenticationManagerImpl = AuthenticationManagerImpl()
    ) {
        self.playerManager = playerManager
        self.teamsManager = teamsManager
        self.authManager = authManager
    }
    
    public func createAuthViewModel() -> AuthViewModel {
        AuthViewModel(
            authenticationManager: authManager
        )
    }
}
