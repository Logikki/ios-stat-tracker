//
//  GamesViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 7.6.2025.
//

import Combine
import Foundation

@MainActor
final class GamesViewModel: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let gameManager: GameManagerImpl
    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(gameManager: GameManagerImpl, userManager: UserManagerImpl) {
        self.gameManager = gameManager
        self.userManager = userManager

        userManager.$currentUserProfile
            .map { $0?.matches ?? [] }
            .map { $0.sorted(by: { $0.createdAt > $1.createdAt }) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] matches in
                guard let self else { return }
                if !matches.isEmpty || self.games.isEmpty {
                    self.games = matches
                }
            }
            .store(in: &cancellables)
    }

    var currentUsername: String? {
        userManager.currentUserProfile?.username
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        await userManager.fetchOwnUser()
    }

    func deleteGame(_ game: Game) {
        Task {
            do {
                try await gameManager.deleteGame(id: game.id)
                await userManager.fetchOwnUser()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#if DEBUG
    extension GamesViewModel {
        static func preview(games: [Game], includeProfile: Bool) -> GamesViewModel {
            let auth = AuthenticationManagerImpl.shared
            let user = UserManagerImpl.preview(profile: includeProfile ? PreviewSamples.userWithEverything : nil)
            let game = GameManagerImpl.preview(games: games)
            let vm = GamesViewModel(gameManager: game, userManager: user)
            vm.games = games
            return vm
        }
    }
#endif
