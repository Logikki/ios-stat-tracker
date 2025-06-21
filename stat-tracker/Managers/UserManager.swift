//
//  UserManager.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 28.1.2025.
//

import Foundation
import Combine

protocol UserManager: ObservableObject {
    var currentUserProfile: User? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func fetchOwnUser()
    func fetchGamesForPlayer() -> [Game]?
}

final class UserManagerImpl: UserManager {
    @Published var currentUserProfile: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let urlSession = URLSession.shared
    private let authenticationManager: AuthenticationManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManagerImpl) {
        self.authenticationManager = authenticationManager
        AppLogger.info("UserManager initialized.", category: "UserManagement")

        authenticationManager.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.fetchOwnUser()
                } else {
                    self?.currentUserProfile = nil
                    self?.errorMessage = nil
                    AppLogger.info("User logged out, clearing user profile.", category: "UserManagement")
                }
            }
            .store(in: &cancellables)
    }

    public func fetchOwnUser() {
        guard !isLoading else {
            AppLogger.debug("fetchOwnUser is already in progress.", category: "UserManagement")
            return
        }

        isLoading = true
        errorMessage = nil
        AppLogger.debug("Attempting to fetch own user profile.", category: "UserManagement")

        guard let url = URL(string: Constants.API.User.getOwnUser) else {
            self.errorMessage = "Failed to create URL for user profile."
            isLoading = false
            AppLogger.error("Error creating URL for own user fetch.", category: "UserManagement")
            return
        }
        
        let userResource = Resource(url: url, method: .get([]), modelType: User.self)
        
        Task { @MainActor in
            defer { self.isLoading = false }
            
            do {
                let decodedUser = try await HTTPClient.shared.load(userResource)
                self.currentUserProfile = decodedUser
                self.errorMessage = nil
                AppLogger.info("Successfully fetched and decoded user profile for \(decodedUser.username).",
                               category: "UserManagement")
                AppLogger.info("\(decodedUser).", category: "UserManagement")
            } catch {
                if let networkError = error as? NetworkError {
                    AppLogger.error("Error fetching user information: \(networkError.localizedDescription)", category: "Network")
                    self.errorMessage = networkError.localizedDescription
                } else {
                    AppLogger.error("An unexpected error occurred during user fetch: \(error.localizedDescription)", category: "Network")
                    self.errorMessage = "An unexpected error occurred."
                }
                self.currentUserProfile = nil
            }
            
        }
    }
    
    func fetchGamesForPlayer() -> [Game]? {
        AppLogger.debug("fetchGamesForPlayer called (not implemented)", category: "UserManagement")
        return nil
    }
}
