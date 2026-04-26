//
//  DependencyContainer.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

/// Central dependency container for the entire app
/// Use this as a single source of truth for all dependencies
@MainActor
final class DependencyContainer: ObservableObject {
    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Core Services (Created once, reused everywhere)

    let authenticationManager: AuthenticationManagerImpl
    let userManager: UserManagerImpl
    let gameManager: GameManagerImpl
    let leagueManager: LeagueManagerImpl
    let teamsManager: TeamsManager

    // MARK: - App State

    let appState: AppState

    // MARK: - ViewModels (Cached to preserve state)

    private(set) lazy var authViewModel: AuthViewModel = .init(
        authenticationManager: authenticationManager,
        userManager: userManager
    )

    private var settingsViewModel: SettingsViewModel?
    private var gamesViewModel: GamesViewModel?
    private var leaguesViewModel: LeaguesViewModel?
    private var profileViewModel: ProfileViewModel?

    // MARK: - Initialization

    private init() {
        // Initialize core services in dependency order
        authenticationManager = AuthenticationManagerImpl.shared
        userManager = UserManagerImpl(authenticationManager: authenticationManager)
        gameManager = GameManagerImpl()
        leagueManager = LeagueManagerImpl()
        teamsManager = TeamsManagerImpl()

        appState = AppState(
            authManager: authenticationManager,
            userManager: userManager
        )
    }

    // MARK: - ViewModel Factory Methods

    /// Get the shared AuthViewModel (preserves login state)
    func getAuthViewModel() -> AuthViewModel {
        authViewModel
    }

    /// Get the shared SettingsViewModel (preserves settings state)
    func getSettingsViewModel() -> SettingsViewModel {
        if settingsViewModel == nil {
            settingsViewModel = SettingsViewModel(authenticationManager: authenticationManager)
        }
        return settingsViewModel!
    }

    /// Get the shared GamesViewModel (preserves filters/state)
    func getGamesViewModel() -> GamesViewModel {
        if gamesViewModel == nil {
            gamesViewModel = GamesViewModel(
                gameManager: gameManager,
                userManager: userManager
            )
        }
        return gamesViewModel!
    }

    /// Get the shared LeaguesViewModel
    func getLeaguesViewModel() -> LeaguesViewModel {
        if leaguesViewModel == nil {
            leaguesViewModel = LeaguesViewModel(userManager: userManager)
        }
        return leaguesViewModel!
    }

    func getProfileViewModel() -> ProfileViewModel {
        if profileViewModel == nil {
            profileViewModel = ProfileViewModel(userManager: userManager)
        }
        return profileViewModel!
    }

    // MARK: - Transient ViewModels (Create new each time)

    // These ViewModels are context-specific and should be created fresh

    func createAddGameViewModel() -> AddGameViewModel {
        AddGameViewModel(
            gameManager: gameManager,
            userManager: userManager,
            teamsManager: teamsManager
        )
    }

    func createAddGameViewModel(forLeague league: League) -> AddGameViewModel {
        AddGameViewModel(
            gameManager: gameManager,
            userManager: userManager,
            teamsManager: teamsManager,
            preselectedLeague: league
        )
    }

    func createCreateLeagueViewModel() -> CreateLeagueViewModel {
        CreateLeagueViewModel(
            leagueManager: leagueManager,
            userManager: userManager
        )
    }

    func createJoinLeagueViewModel() -> JoinLeagueViewModel {
        JoinLeagueViewModel(
            leagueManager: leagueManager,
            userManager: userManager
        )
    }

    func createLeagueDetailViewModel(league: League) -> LeagueDetailViewModel {
        LeagueDetailViewModel(
            league: league,
            leagueManager: leagueManager,
            userManager: userManager,
            authManager: authenticationManager
        )
    }

    // MARK: - Lifecycle Methods

    func resetViewModels() {
        settingsViewModel = nil
        gamesViewModel = nil
        leaguesViewModel = nil
        profileViewModel = nil
    }
}

// MARK: - SwiftUI Environment Key

private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue = DependencyContainer.shared
}

extension EnvironmentValues {
    var dependencies: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension for Easy Access

extension View {
    func withDependencies(_ container: DependencyContainer = .shared) -> some View {
        environmentObject(container)
    }
}
