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
        Publishers.CombineLatest(
            authManager.$isAuthenticated,
            userManager.$isLoading
        )
        .sink { [unowned self] isAuthenticated, userManagerIsLoading in
            self.showAuthView = !isAuthenticated
            
            if isAuthenticated {
                self.isLoadingInitialData = userManagerIsLoading
            } else {
                self.isLoadingInitialData = false
            }
        }
        .store(in: &cancellables)
        
        userManager.$errorMessage
            .sink { [unowned self] errorMessage in
                if let errorMessage = errorMessage {
                    self.errorMessage = errorMessage
                } else {
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
    }
}

extension AppState {
    public func clearError() {
        self.errorMessage = nil
    }
}
