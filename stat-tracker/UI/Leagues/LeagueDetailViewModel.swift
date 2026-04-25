//
//  LeagueDetailViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Combine
import Foundation

@MainActor
final class LeagueDetailViewModel: ObservableObject {
    @Published private(set) var league: League
    @Published var newMemberUsername: String = ""
    @Published var generatedInvitationCode: String?
    @Published var errorMessage: String?
    @Published var currentUserName: String?
    @Published private(set) var isWorking: Bool = false

    private let leagueManager: LeagueManagerImpl
    private let userManager: UserManagerImpl
    private let authManager: AuthenticationManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(league: League,
         leagueManager: LeagueManagerImpl,
         userManager: UserManagerImpl,
         authManager: AuthenticationManagerImpl)
    {
        self.league = league
        self.leagueManager = leagueManager
        self.userManager = userManager
        self.authManager = authManager

        // Stay in sync if the user profile reloads with a fresh copy of this league.
        userManager.$currentUserProfile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] profile in
                guard let self else { return }
                
                self.currentUserName = profile?.username
                
                if let updated = profile?.leagues.first(where: { $0.id == league.id }) {
                    self.league = updated
                }
            }
            .store(in: &cancellables)
    }

    var isAdmin: Bool {
        guard let me = authManager.currentUser?.username else { return false }
        return league.isAdmin(username: me)
    }

    var sortedMatches: [Game] {
        league.matches.sorted(by: { $0.createdAt > $1.createdAt })
    }

    var leaderboard: [LeagueStanding] {
        var standings: [String: LeagueStanding] = [:]
        for user in league.users {
            standings[user.username] = LeagueStanding(username: user.username)
        }
        for game in league.matches {
            let homeName = game.homePlayer.username
            let awayName = game.awayPlayer.username
            standings[homeName] = standings[homeName, default: LeagueStanding(username: homeName)]
                .recording(scoreFor: game.homeScore, scoreAgainst: game.awayScore)
            standings[awayName] = standings[awayName, default: LeagueStanding(username: awayName)]
                .recording(scoreFor: game.awayScore, scoreAgainst: game.homeScore)
        }
        return standings.values.sorted(by: {
            if $0.points != $1.points { return $0.points > $1.points }
            return $0.goalDifference > $1.goalDifference
        })
    }

    func addMember() {
        let username = newMemberUsername.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty else { return }
        isWorking = true
        Task {
            defer { self.isWorking = false }
            do {
                let updated = try await leagueManager.addUser(username: username, toLeague: league.id)
                self.league = updated
                self.newMemberUsername = ""
                await self.userManager.fetchOwnUser()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func generateInvitation() {
        isWorking = true
        Task {
            defer { self.isWorking = false }
            do {
                let code = try await leagueManager.createInvitation(leagueId: league.id)
                self.generatedInvitationCode = code
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func deleteLeague(onSuccess: @escaping () -> Void) {
        isWorking = true
        Task {
            defer { self.isWorking = false }
            do {
                try await leagueManager.deleteLeague(id: league.id)
                await userManager.fetchOwnUser()
                onSuccess()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
    extension LeagueDetailViewModel {
        static func preview(league: League, asAdmin: Bool = true) -> LeagueDetailViewModel {
            let auth = AuthenticationManagerImpl.shared
            if asAdmin, let admin = league.admins.first {
                auth.currentUser = AuthResponse(token: "preview", username: admin.username, name: admin.username)
            }
            let user = UserManagerImpl.preview(profile: PreviewSamples.userWithEverything)
            let leagueManager = LeagueManagerImpl()
            return LeagueDetailViewModel(
                league: league,
                leagueManager: leagueManager,
                userManager: user,
                authManager: auth
            )
        }
    }
#endif

struct LeagueStanding: Identifiable, Hashable {
    let username: String
    var played: Int = 0
    var wins: Int = 0
    var draws: Int = 0
    var losses: Int = 0
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0

    var id: String {
        username
    }

    var points: Int {
        wins * 3 + draws
    }

    var goalDifference: Int {
        goalsFor - goalsAgainst
    }

    func recording(scoreFor: Int, scoreAgainst: Int) -> LeagueStanding {
        var copy = self
        copy.played += 1
        copy.goalsFor += scoreFor
        copy.goalsAgainst += scoreAgainst
        if scoreFor > scoreAgainst { copy.wins += 1 }
        else if scoreFor < scoreAgainst { copy.losses += 1 }
        else { copy.draws += 1 }
        return copy
    }
}
