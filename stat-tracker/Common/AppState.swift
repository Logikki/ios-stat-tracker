//
//  AppState.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 14.6.2025.
//

import Foundation
import Combine

class AppState: ObservableObject {
    @Published var isLoadingInitialData: Bool = true
    @Published var showAuthView: Bool = true

    private let authManager: AuthenticationManagerImpl
    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthenticationManagerImpl, userManager: UserManagerImpl) {
        self.authManager = authManager
        self.userManager = userManager
        
        setupSubscriptions()
    }

    private func setupSubscriptions() {
        authManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                self.showAuthView = !isAuthenticated

                if isAuthenticated {
                    
                } else {
                    self.isLoadingInitialData = false
                }
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest(
            authManager.$isAuthenticated,
            userManager.$isLoading
        )
        .sink { [weak self] isAuthenticated, userManagerIsLoading in
            guard let self = self else { return }

            if isAuthenticated {
                self.isLoadingInitialData = userManagerIsLoading
            } else {
                self.isLoadingInitialData = false
            }
        }
        .store(in: &cancellables)
    }
}
