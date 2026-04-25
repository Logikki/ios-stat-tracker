//
//  ProfileViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Combine
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User?
    @Published var addFriendUsername: String = ""
    @Published var errorMessage: String?
    @Published private(set) var isWorking: Bool = false

    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManagerImpl) {
        self.userManager = userManager
        userManager.$currentUserProfile
            .receive(on: DispatchQueue.main)
            .assign(to: &$user)
    }

    func refresh() async {
        await userManager.fetchOwnUser()
    }

    var stats: PlayerStats {
        guard let username = user?.username, let matches = user?.matches else { return .empty }
        return PlayerStats(matches: matches, username: username)
    }

    func updateVisibility(_ visibility: ProfileVisibility) {
        Task { await userManager.updateVisibility(visibility) }
    }

    func sendFriendRequest() {
        let username = addFriendUsername.trimmingCharacters(in: .whitespaces)
        guard !username.isEmpty else { return }
        isWorking = true
        Task {
            defer { self.isWorking = false }
            do {
                try await userManager.sendFriendRequest(to: username)
                self.addFriendUsername = ""
                self.errorMessage = "Friend request sent to @\(username)"
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    func accept(_ username: String) {
        Task {
            do { try await userManager.acceptFriendRequest(from: username) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func reject(_ username: String) {
        Task {
            do { try await userManager.rejectFriendRequest(from: username) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    func remove(_ username: String) {
        Task {
            do { try await userManager.removeFriend(username) }
            catch { errorMessage = error.localizedDescription }
        }
    }

    #if DEBUG
        static func preview(profile: User?) -> ProfileViewModel {
            let user = UserManagerImpl.preview(profile: profile)
            return ProfileViewModel(userManager: user)
        }
    #endif
}

struct PlayerStats {
    let played: Int
    let wins: Int
    let draws: Int
    let losses: Int
    let goalsFor: Int
    let goalsAgainst: Int

    static let empty = PlayerStats(played: 0, wins: 0, draws: 0, losses: 0, goalsFor: 0, goalsAgainst: 0)

    init(played: Int, wins: Int, draws: Int, losses: Int, goalsFor: Int, goalsAgainst: Int) {
        self.played = played
        self.wins = wins
        self.draws = draws
        self.losses = losses
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
    }

    init(matches: [Game], username: String) {
        var played = 0, wins = 0, draws = 0, losses = 0, gf = 0, ga = 0
        for game in matches {
            played += 1
            let isHome = game.homePlayer.username == username
            let own = isHome ? game.homeScore : game.awayScore
            let opp = isHome ? game.awayScore : game.homeScore
            gf += own
            ga += opp
            if own > opp { wins += 1 }
            else if own < opp { losses += 1 }
            else { draws += 1 }
        }
        self.init(played: played, wins: wins, draws: draws, losses: losses, goalsFor: gf, goalsAgainst: ga)
    }

    var winRate: Double {
        played == 0 ? 0 : Double(wins) / Double(played)
    }
}
