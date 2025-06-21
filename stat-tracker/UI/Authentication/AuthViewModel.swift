//
//  AuthViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 6.3.2025.
//

import Foundation
import Combine

// MARK: - AuthViewModel

class AuthViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String?
    
    @Published private var loginCallIsLoading: Bool = false
    @Published var overallLoading: Bool = false

    private var authManager: AuthenticationManagerImpl
    private var userManager: UserManagerImpl
    private let urlSession: URLSessionProtocol = URLSession.shared
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManagerImpl,
         userManager: UserManagerImpl) {
        self.authManager = authenticationManager
        self.userManager = userManager

        Publishers.CombineLatest(
            $loginCallIsLoading,
            userManager.$isLoading
        )
        .map { loginLoading, userManagerLoading in
            return loginLoading || userManagerLoading
        }
        .assign(to: &$overallLoading)
    }

    func login(credentials: Credentials) {
        loginCallIsLoading = true
        errorMessage = nil

        guard let url = URL(string: Constants.API.Auth.login) else {
            AppLogger.debug("Error creating login URL", category: "Authentication")
            self.errorMessage = "Invalid login URL."
            self.loginCallIsLoading = false
            return
        }
            
        guard let jsonData = try? JSONEncoder().encode(credentials) else {
            self.errorMessage = "Invalid request data for login."
            self.loginCallIsLoading = false
            return
        }
            
        let loginResource = Resource(url: url, method: .post(jsonData), modelType: AuthResponse.self)
        
        Task { @MainActor in
            defer { self.loginCallIsLoading = false }

            do {
                let decodedResponse = try await HTTPClient.shared.load(loginResource)
                self.authManager.setAuthState(response: decodedResponse)
                self.userManager.fetchOwnUser()
                self.errorMessage = nil
            } catch {
                self.authManager.clearAuthState()
                
                if let networkError = error as? NetworkError {
                    AppLogger.error("Login failed with network error: \(networkError.localizedDescription)", category: "Authentication")
                    self.errorMessage = networkError.localizedDescription
                } else {
                    AppLogger.error("Login failed with unexpected error: \(error.localizedDescription)", category: "Authentication")
                    self.errorMessage = "An unexpected error occurred during login."
                }
            }
        }
    }
}

// MARK: - Auth Related Models

struct AuthResponse: Codable {
    public let token: String
    public let username: String
    public let name: String
}

struct Credentials: Codable {
    public var username: String
    public var password: String
}
