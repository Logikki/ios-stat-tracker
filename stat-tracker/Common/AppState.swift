//
//  AppState.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 14.6.2025.
//

import Combine
import Foundation

@MainActor
class AppState: ObservableObject {
    @Published var isLoadingInitialData: Bool = true
    @Published var showAuthView: Bool = true
    @Published var errorMessage: String? = nil

    private let authManager: AuthenticationManagerImpl
    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthenticationManagerImpl, userManager: UserManagerImpl) {
        self.authManager = authManager
        self.userManager = userManager

        setup()
    }

    private func setup() {
        // Set initial state immediately based on current values
        showAuthView = !authManager.isAuthenticated
        if authManager.isAuthenticated {
            isLoadingInitialData = userManager.isLoading
        } else {
            isLoadingInitialData = false
        }

        // Combine auth and loading states with debouncing to prevent rapid updates
        Publishers.CombineLatest(
            authManager.$isAuthenticated,
            userManager.$isLoading
        )
        .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
        .sink { [weak self] isAuthenticated, userManagerIsLoading in
            guard let self else { return }

            self.showAuthView = !isAuthenticated

            if isAuthenticated {
                self.isLoadingInitialData = userManagerIsLoading
            } else {
                self.isLoadingInitialData = false
            }
        }
        .store(in: &cancellables)

        // Handle error messages
        userManager.$errorMessage
            .debounce(for: .milliseconds(50), scheduler: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                guard let self else { return }
                self.errorMessage = errorMessage
            }
            .store(in: &cancellables)
    }

    func clearError() {
        errorMessage = nil
    }
}
