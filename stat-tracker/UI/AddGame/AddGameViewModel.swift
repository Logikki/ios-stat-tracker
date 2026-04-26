//
//  AddGameViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Combine
import Foundation

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

    private let gameManager: GameManagerImpl
    private let userManager: UserManagerImpl
    private let teamsManager: TeamsManager

    // League context - when set, locks the league selection
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

    /// Friends + everyone in any of my leagues — unique by username, alphabetical.
    var availableOpponents: [LightUser] {
        guard let me = userManager.currentUserProfile else { return [] }
        var seen: Set<String> = [me.username]
        var pool: [LightUser] = []
        for friend in me.friends where seen.insert(friend.username).inserted {
            pool.append(friend)
        }
        for league in me.leagues {
            for member in league.users where seen.insert(member.username).inserted {
                pool.append(member)
            }
        }
        return pool.sorted(by: { $0.username.lowercased() < $1.username.lowercased() })
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
            do {
                _ = try await gameManager.createGame(payload)
                await userManager.fetchOwnUser()
                await gameManager.fetchGames()
                self.didSubmitSuccessfully = true
                self.reset()
            } catch {
                self.errorMessage = error.localizedDescription
                AppLogger.error("createGame failed: \(error.localizedDescription)", category: "Games")
            }
        }
    }
}
