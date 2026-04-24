//
//  LeaguesViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 19.6.2025.
//

import Foundation
import Combine

@MainActor
final class LeaguesViewModel: ObservableObject {
    @Published private(set) var leagues: [League] = []
    @Published var errorMessage: String?

    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(userManager: UserManagerImpl) {
        self.userManager = userManager
        userManager.$currentUserProfile
            .map { $0?.leagues ?? [] }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.leagues = $0 }
            .store(in: &cancellables)
    }

    func refresh() async {
        await userManager.fetchOwnUser()
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
