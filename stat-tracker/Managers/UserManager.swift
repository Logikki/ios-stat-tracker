//
//  UserManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation
import Combine

protocol UserManager: ObservableObject {
    var currentUserProfile: User? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func fetchOwnUser()
    func saveGame(_ game: Game)
    func fetchGamesForPlayer() -> [Game]?
}

final class UserManagerImpl: UserManager {
    @Published var currentUserProfile: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let urlSession: URLSessionProtocol
    private let authenticationManager: AuthenticationManagerImpl
    private var cancellables = Set<AnyCancellable>()

    private func constructRequest(with urlString: String, httpMethod: String = "GET") -> URLRequest? {
        guard let url = URL(string: urlString) else {
            AppLogger.error("Failed to create URL from string: \(urlString)", category: "Network")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authenticationManager.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            AppLogger.error("Attempted to construct authenticated request without an auth token.", category: "Network")
            return nil
        }
        return request
    }

    init(urlSession: URLSessionProtocol = URLSession.shared, authenticationManager: AuthenticationManagerImpl) {
        self.urlSession = urlSession
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

        guard let request = constructRequest(with: Constants.API.URL + Constants.API.User.getOwnUser, httpMethod: "GET") else {
            self.errorMessage = "Failed to create network request for user profile."
            isLoading = false
            AppLogger.error("Error creating request for own user fetch.", category: "UserManagement")
            return
        }
        
        urlSession.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    AppLogger.error("Error fetching user information: \(error.localizedDescription)", category: "Network")
                    self.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse else {
                    AppLogger.error("Invalid server response for user profile fetch.", category: "Network")
                    self.errorMessage = "Invalid server response."
                    return
                }
                
                if let responseBodyString = String(data: data, encoding: .utf8) {
                    AppLogger.debug("HTTP Response Body:\n\(responseBodyString)", category: "Network")
                } else {
                    AppLogger.debug("HTTP Response Body: (Unable to decode as UTF-8 string)", category: "Network")
                }
                
                if httpResponse.statusCode == 200 {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .customISO8601
                    
                    do {
                        let decodedUser = try decoder.decode(User.self, from: data)
                        self.currentUserProfile = decodedUser
                        self.errorMessage = nil
                        AppLogger.info("Successfully fetched and decoded user profile for \(decodedUser.username).", category: "UserManagement")
                    } catch {
                        AppLogger.error("Failed to decode user profile response. Decoding error: \(error)", category: "UserManagement")
                        self.currentUserProfile = nil
                    }
                } else {
                    AppLogger.error("Failed to fetch user profile with status code: \(httpResponse.statusCode)", category: "UserManagement")
                    if let errorBody = String(data: data, encoding: .utf8) {
                        AppLogger.debug("Error response body: \(errorBody)", category: "Network")
                    }
                    if let backendError = try? JSONDecoder().decode(BackendError.self, from: data) {
                        self.errorMessage = backendError.message
                    } else {
                        self.errorMessage = "Failed to fetch user profile. Status: \(httpResponse.statusCode)"
                    }
                    self.currentUserProfile = nil
                }
            }
        }.resume()
    }

    func saveGame(_ game: Game) {
        AppLogger.debug("saveGame called (not implemented)", category: "UserManagement")
    }
    
    func fetchGamesForPlayer() -> [Game]? {
        AppLogger.debug("fetchGamesForPlayer called (not implemented)", category: "UserManagement")
        return nil
    }
}

struct BackendError: Codable, Error {
    let message: String
}
