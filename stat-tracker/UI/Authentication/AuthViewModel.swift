//
//  LoginManager.swift
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

        guard let url = URL(string: Constants.API.URL + Constants.API.Auth.login) else {
            AppLogger.debug("Error creating URL", category: "Authentication")
            self.errorMessage = "Invalid login URL."
            self.loginCallIsLoading = false
            return
        }
        
        let body: [String: Any] = [
            "username": credentials.username,
            "password": credentials.password
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            self.errorMessage = "Invalid request data"
            self.loginCallIsLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.loginCallIsLoading = false

                if let error = error {
                    AppLogger.debug("login error: " + error.localizedDescription, category: "Network")
                    self.errorMessage = "Request error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid server response"
                    return
                }

                if httpResponse.statusCode == 200 {
                    do {
                        let decodedResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
                        self.authManager.setAuthState(response: decodedResponse)
                        self.userManager.fetchOwnUser()
                        
                        self.errorMessage = nil
                    } catch {
                        self.authManager.clearAuthState()
                        self.errorMessage = "Failed to decode response"
                    }
                } else {
                    if let errorDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String], let message = errorDict["message"] {
                        self.errorMessage = message
                    } else {
                        self.errorMessage = "Login failed with status code: \(httpResponse.statusCode)"
                    }
                    self.authManager.clearAuthState()
                }
            }
        }.resume()
    }
}

// MARK: - Auth Related Models

struct AuthResponse: Codable {
    public let token: String
    public let username: String
    public let name: String
}

struct Credentials {
    public var username: String
    public var password: String
}
