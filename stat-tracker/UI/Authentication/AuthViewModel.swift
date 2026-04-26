//
//  AuthViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 6.3.2025.
//

import Combine
import Foundation

enum AuthMode: Hashable {
    case login
    case signUp
}

@MainActor
final class AuthViewModel: ObservableObject, Loggable {
    @Published var mode: AuthMode = .login

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var visibility: ProfileVisibility = .Friends

    @Published var errorMessage: String?
    @Published private(set) var overallLoading: Bool = false

    private let authManager: AuthenticationManagerImpl
    private let userManager: UserManagerImpl
    private var cancellables = Set<AnyCancellable>()

    init(authenticationManager: AuthenticationManagerImpl, userManager: UserManagerImpl) {
        authManager = authenticationManager
        self.userManager = userManager

        userManager.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                guard let self else { return }
                if !loading { self.overallLoading = false }
            }
            .store(in: &cancellables)
    }

    func toggleMode() {
        mode = (mode == .login) ? .signUp : .login
        errorMessage = nil
    }

    func submit() {
        switch mode {
        case .login: login()
        case .signUp: signUp()
        }
    }

    var isSubmitDisabled: Bool {
        if overallLoading { return true }
        switch mode {
        case .login:
            return username.isEmpty || password.isEmpty
        case .signUp:
            return username.isEmpty || password.isEmpty || name.isEmpty || email.isEmpty
        }
    }

    // MARK: - Actions

    private func login() {
        overallLoading = true
        errorMessage = nil

        let credentials = Credentials(username: username, password: password)
        guard
            let url = URL(string: Constants.API.Auth.login),
            let body = try? JSONEncoder().encode(credentials)
        else {
            errorMessage = "Could not build login request."
            overallLoading = false
            return
        }

        let resource = Resource(url: url, method: .post(body), modelType: AuthResponse.self)

        Task { @MainActor in
            defer {
                self.overallLoading = false
            }
            do {
                let response = try await HTTPClient.shared.load(resource)
                self.authManager.setAuthState(response: response)
                self.errorMessage = nil
            } catch {
                let message = friendlyMessage(for: error, fallback: "Login failed.")
                self.errorMessage = message
                AppLogger.error("\(self.tag)::Login failed: \(error.localizedDescription), message='\(message)'", category: "Authentication")
            }
        }
    }

    private func signUp() {
        overallLoading = true
        errorMessage = nil

        let username = self.username
        let password = self.password
        let name = self.name
        let email = self.email
        let visibility = self.visibility

        Task {
            defer { self.overallLoading = false }
            do {
                try await self.userManager.createUser(
                    username: username,
                    name: name,
                    email: email,
                    password: password,
                    visibility: visibility
                )

                // Auto-login after signup.
                let credentials = Credentials(username: username, password: password)
                guard
                    let url = URL(string: Constants.API.Auth.login),
                    let body = try? JSONEncoder().encode(credentials)
                else {
                    self.errorMessage = "Account created. Please log in."
                    self.mode = .login
                    return
                }
                let loginResource = Resource(url: url, method: .post(body), modelType: AuthResponse.self)
                let response = try await HTTPClient.shared.load(loginResource)
                self.authManager.setAuthState(response: response)
                await self.userManager.fetchOwnUser()
                self.errorMessage = nil
            } catch {
                self.errorMessage = friendlyMessage(for: error, fallback: "Sign up failed.")
                AppLogger.error("Sign up failed: \(error.localizedDescription)", category: "Authentication")
            }
        }
    }

    private func friendlyMessage(for error: Error, fallback: String) -> String {
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? fallback
        }
        return error.localizedDescription.isEmpty ? fallback : error.localizedDescription
    }
}

// MARK: - Auth-related models

struct AuthResponse: Codable {
    let token: String
    let username: String
    let name: String
}

struct Credentials: Codable {
    var username: String
    var password: String
}
