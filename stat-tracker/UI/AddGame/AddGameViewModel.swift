//
//  AddGameViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Combine
import Foundation

// MARK: - Navigation Source

/// Represents the screen from which the user navigated to add a game
enum NavigationSource {
    /// User navigated from the main games screen
    case mainScreen
    
    /// User navigated from a specific league's detail view
    case leagueDetails(League)
    
    /// The associated league, if navigated from league details
    var league: League? {
        switch self {
        case .mainScreen:
            return nil
        case .leagueDetails(let league):
            return league
        }
    }
}

// MARK: - Add Game View Model

@MainActor
final class AddGameViewModel: ObservableObject {
    @Published var gameType: GameType = .NHL
    @Published var homeIsMe: Bool = true

    /// When false, `opponentUsername` is driven by the friends picker.
    /// When true, `opponentUsername` is typed manually.
    @Published var manualOpponent: Bool = false
    @Published var opponentUsername: String = ""

    @Published var homeTeam: String = ""
    @Published var awayTeam: String = ""
    @Published var homeScore: Int = 0
    @Published var awayScore: Int = 0

    @Published var date: Date = .now
    @Published var overtime: Bool = false
    @Published var penalties: Bool = false

    @Published var selectedLeagueId: String? = nil

    @Published private(set) var isSubmitting: Bool = false
    @Published var errorMessage: String?
    @Published var didSubmitSuccessfully: Bool = false
    @Published var leagueNotFoundAlert: Bool = false

    private let gameManager: GameManagerImpl
    private let userManager: UserManagerImpl
    private let teamsManager: TeamsManager

    /// Where the user navigated from
    private let navigationSource: NavigationSource
    
    /// League context - when set, locks the league selection
    private let preselectedLeague: League?
    
    var isLeagueLocked: Bool {
        preselectedLeague != nil
    }

    init(
        gameManager: GameManagerImpl,
        userManager: UserManagerImpl,
        teamsManager: TeamsManager,
        preselectedLeague: League? = nil
    ) {
        self.gameManager = gameManager
        self.userManager = userManager
        self.teamsManager = teamsManager
        self.preselectedLeague = preselectedLeague
        
        // Determine navigation source based on preselected league
        if let league = preselectedLeague {
            self.navigationSource = .leagueDetails(league)
        } else {
            self.navigationSource = .mainScreen
        }

        // If coming from a league, pre-select it
        if let league = preselectedLeague {
            selectedLeagueId = league.id
            // Set game type to first available type in the league
            if let firstType = league.gameTypes.first,
               let gameType = GameType(rawValue: firstType)
            {
                self.gameType = gameType
            }
        }
    }

    var leaguesForCurrentType: [League] {
        if let locked = preselectedLeague {
            return [locked]
        }

        let userLeagues = userManager.currentUserProfile?.leagues ?? []
        return userLeagues.filter { $0.gameTypes.contains(gameType.rawValue) }
    }

    var shouldShowLeaguePicker: Bool {
        if preselectedLeague != nil { return true }
        return !leaguesForCurrentType.isEmpty
    }

    var nhlTeams: [HockeyTeam] {
        teamsManager.getNHLTeams()
    }

    // MARK: - Opponent Selection Logic
    
    /// Returns the currently selected league, if any
    private var activeLeague: League? {
        guard let leagueId = selectedLeagueId else { return nil }
        
        // First check if it's the preselected league
        if let preselected = preselectedLeague, preselected.id == leagueId {
            return preselected
        }
        
        // Otherwise find it in the user's leagues
        return userManager.currentUserProfile?.leagues.first(where: { $0.id == leagueId })
    }
    
    var availableOpponents: [LightUser] {
        guard let me = userManager.currentUserProfile else { return [] }
        
        if let league = activeLeague {
            return filterLeagueMembers(from: league, excludingUsername: me.username)
        }
        
        switch navigationSource {
        case .leagueDetails(let league):
            return filterLeagueMembers(from: league, excludingUsername: me.username)
            
        case .mainScreen:
            return filterFriendsAndLeagueMembers(excludingUsername: me.username)
        }
    }
    
    private func filterLeagueMembers(from league: League, excludingUsername: String) -> [LightUser] {
        var seen = Set<String>([excludingUsername])
        var members: [LightUser] = []
        
        for user in league.users where seen.insert(user.username).inserted {
            members.append(user)
        }
        
        return members.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }
    
    private func filterFriendsAndLeagueMembers(excludingUsername: String) -> [LightUser] {
        guard let me = userManager.currentUserProfile else { return [] }
        
        var seen = Set<String>([excludingUsername])
        var pool: [LightUser] = []
        
        // Add friends
        for friend in me.friends where seen.insert(friend.username).inserted {
            pool.append(friend)
        }
        
        for league in me.leagues {
            for member in league.users where seen.insert(member.username).inserted {
                pool.append(member)
            }
        }
        
        return pool.sorted { $0.username.lowercased() < $1.username.lowercased() }
    }

    var canPickFromList: Bool {
        !availableOpponents.isEmpty
    }

    var canSubmit: Bool {
        guard !opponentUsername.trimmingCharacters(in: .whitespaces).isEmpty,
              !homeTeam.trimmingCharacters(in: .whitespaces).isEmpty,
              !awayTeam.trimmingCharacters(in: .whitespaces).isEmpty,
              userManager.currentUserProfile != nil
        else {
            return false
        }
        return !isSubmitting
    }

    func reset() {
        homeTeam = ""
        awayTeam = ""
        homeScore = 0
        awayScore = 0
        opponentUsername = ""
        overtime = false
        penalties = false
        selectedLeagueId = nil
        date = .now
    }

    #if DEBUG
        static func preview(profile: User? = PreviewSamples.userWithEverything) -> AddGameViewModel {
            let auth = AuthenticationManagerImpl.shared
            let user = UserManagerImpl.preview(profile: profile)
            let game = GameManagerImpl()
            return AddGameViewModel(gameManager: game, userManager: user, teamsManager: TeamsManagerImpl())
        }
    #endif

    func submit() {
        guard let currentUsername = userManager.currentUserProfile?.username else {
            errorMessage = "You must be logged in to record a game."
            return
        }
        guard canSubmit else { return }

        isSubmitting = true
        errorMessage = nil
        leagueNotFoundAlert = false

        let payload = CreateGamePayload(
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homePlayer: homeIsMe ? currentUsername : opponentUsername,
            awayPlayer: homeIsMe ? opponentUsername : currentUsername,
            homeScore: homeScore,
            awayScore: awayScore,
            createdAt: date,
            overTime: overtime ? true : nil,
            penalties: penalties ? true : nil,
            league: selectedLeagueId,
            gameType: gameType
        )

        Task {
            defer { self.isSubmitting = false }
            
            let result = await gameManager.createGameWithErrorHandling(payload)
            
            switch result {
            case .success:
                // Refresh data in the background
                await userManager.fetchOwnUser(showLoadingIndicator: false)
                await gameManager.fetchGames()
                
                // Notify success
                self.didSubmitSuccessfully = true
                self.reset()
                
            case .leagueNotFound:
                self.leagueNotFoundAlert = true
                
            case .error(let message):
                self.errorMessage = message
            }
        }
    }
}
