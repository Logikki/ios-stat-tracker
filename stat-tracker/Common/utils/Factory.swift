//
//  Factory.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

protocol ViewModelFactory: ObservableObject {
    func createAuthViewModel() -> AuthViewModel
    func createSettingsViewModel() -> SettingsViewModel
    func createGamesViewModel() -> GamesViewModel
    func createAddGameViewModel() -> AddGameViewModel
    func createAddGameViewModel(forLeague league: League) -> AddGameViewModel
    func createLeaguesViewModel() -> LeaguesViewModel
    func createCreateLeagueViewModel() -> CreateLeagueViewModel
    func createJoinLeagueViewModel() -> JoinLeagueViewModel
    func createLeagueDetailViewModel(league: League) -> LeagueDetailViewModel
    func createProfileViewModel() -> ProfileViewModel
}

@MainActor
final class ViewModeFactoryImpl: ObservableObject, ViewModelFactory {
    private let teamsManager: TeamsManager
    private let userManager: UserManagerImpl
    private let authManager: AuthenticationManagerImpl
    private let gameManager: GameManagerImpl
    private let leagueManager: LeagueManagerImpl
    
    // Cache the AuthViewModel to preserve its state
    private lazy var authViewModel: AuthViewModel = {
        AuthViewModel(authenticationManager: authManager, userManager: userManager)
    }()

    init(
        teamsManager: TeamsManager = TeamsManagerImpl(),
        authManager: AuthenticationManagerImpl,
        userManager: UserManagerImpl,
        gameManager: GameManagerImpl,
        leagueManager: LeagueManagerImpl
    ) {
        self.teamsManager = teamsManager
        self.authManager = authManager
        self.userManager = userManager
        self.gameManager = gameManager
        self.leagueManager = leagueManager
    }

    func createAuthViewModel() -> AuthViewModel {
        authViewModel
    }

    func createSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(authenticationManager: authManager)
    }

    func createGamesViewModel() -> GamesViewModel {
        GamesViewModel(gameManager: gameManager, userManager: userManager)
    }

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

    func createLeaguesViewModel() -> LeaguesViewModel {
        LeaguesViewModel(userManager: userManager)
    }

    func createCreateLeagueViewModel() -> CreateLeagueViewModel {
        CreateLeagueViewModel(leagueManager: leagueManager, userManager: userManager)
    }

    func createJoinLeagueViewModel() -> JoinLeagueViewModel {
        JoinLeagueViewModel(leagueManager: leagueManager, userManager: userManager)
    }

    func createLeagueDetailViewModel(league: League) -> LeagueDetailViewModel {
        LeagueDetailViewModel(
            league: league,
            leagueManager: leagueManager,
            userManager: userManager,
            authManager: authManager
        )
    }

    func createProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(userManager: userManager)
    }
}

#if DEBUG
    extension ViewModeFactoryImpl {
        static func preview(profile: User? = PreviewSamples.userWithEverything) -> ViewModeFactoryImpl {
            let auth = AuthenticationManagerImpl.shared
            let user = UserManagerImpl.preview(profile: profile)
            let game = GameManagerImpl()
            let league = LeagueManagerImpl()
            return ViewModeFactoryImpl(
                authManager: auth,
                userManager: user,
                gameManager: game,
                leagueManager: league
            )
        }
    }
#endif
