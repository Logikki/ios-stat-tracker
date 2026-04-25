//
//  LeaguesViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 19.6.2025.
//

import Combine
import Foundation

@MainActor
final class LeaguesViewModel: ObservableObject {
    @Published private(set) var leagues: [League] = []
    @Published var errorMessage: String?

    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    init(userManager: UserManagerImpl) {
        self.userManager = userManager

        // Observe user profile changes and update leagues
        userManager.$currentUserProfile
            .map { $0?.leagues ?? [] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLeagues in
                self?.leagues = newLeagues
            }
            .store(in: &cancellables)
    }

    func refresh() async {
        refreshTask?.cancel()

        refreshTask = Task {
            await userManager.fetchOwnUser()
        }

        await refreshTask?.value
    }

    #if DEBUG
        static func preview(profile: User?) -> LeaguesViewModel {
            let auth = AuthenticationManagerImpl.shared
            let user = UserManagerImpl.preview(profile: profile)
            let vm = LeaguesViewModel(userManager: user)
            vm.leagues = profile?.leagues ?? []
            return vm
        }
    #endif
}
