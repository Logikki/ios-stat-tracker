//
//  UserManager.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 28.1.2025.
//

import Combine
import Foundation

@MainActor
final class UserManagerImpl: ObservableObject {
    @Published var currentUserProfile: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let authenticationManager: AuthenticationManagerImpl
    private var cancellables = Set<AnyCancellable>()
    private var fetchTask: Task<Void, Never>?

    init(authenticationManager: AuthenticationManagerImpl) {
        self.authenticationManager = authenticationManager
        AppLogger.info("UserManager initialized.", category: "UserManagement")

        authenticationManager.$isAuthenticated
            .removeDuplicates()
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    
                    if isAuthenticated {
                        await self.fetchOwnUser()
                    } else {
                        self.currentUserProfile = nil
                        self.errorMessage = nil
                        AppLogger.info("User logged out, clearing user profile.", category: "UserManagement")
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Networking

    func fetchOwnUser() async {
        fetchTask?.cancel()

        guard !isLoading else {
            AppLogger.info("Fetch already in progress, skipping duplicate call", category: "UserManagement")
            return
        }

        fetchTask = Task { @MainActor in
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            guard let url = URL(string: Constants.API.User.getOwnUser) else {
                errorMessage = "Failed to build user URL."
                return
            }

            let resource = Resource(url: url, method: .get([]), modelType: User.self)
            do {
                let user = try await HTTPClient.shared.load(resource)

                guard !Task.isCancelled else {
                    AppLogger.info("Fetch task was cancelled", category: "UserManagement")
                    return
                }

                self.currentUserProfile = user
                AppLogger.info("Loaded own user \(user.username)", category: "UserManagement")
            } catch is CancellationError {
                AppLogger.info("Fetch request cancelled", category: "UserManagement")
            } catch NetworkError.unauthorized(_) {
                authenticationManager.clearAuthState()
                errorMessage = "Session expired. Please log in again."
            } catch {
                // Don't report cancellation errors
                if (error as NSError).code != NSURLErrorCancelled {
                    errorMessage = error.localizedDescription
                    AppLogger.error("fetchOwnUser failed: \(error.localizedDescription)", category: "UserManagement")
                }
            }
        }

        await fetchTask?.value
    }

    func createUser(username: String, name: String, email: String, password: String, visibility: ProfileVisibility) async throws {
        guard let url = URL(string: Constants.API.User.createUser) else {
            throw NetworkError.invalidURL
        }

        struct Body: Encodable {
            let username: String
            let name: String
            let email: String
            let password: String
            let visibility: ProfileVisibility
        }
        let body = Body(username: username, name: name, email: email, password: password, visibility: visibility)
        let data = try JSONEncoder().encode(body)

        let resource = Resource(url: url, method: .post(data), modelType: User.self)
        _ = try await HTTPClient.shared.load(resource)
    }

    func updateVisibility(_ visibility: ProfileVisibility) async {
        guard let url = URL(string: Constants.API.User.updateUserVisibility) else { return }
        struct Body: Encodable { let visibility: ProfileVisibility }
        guard let data = try? JSONEncoder().encode(Body(visibility: visibility)) else { return }

        let resource = Resource(url: url, method: .post(data), modelType: EmptyResponse.self)
        do {
            _ = try await HTTPClient.shared.load(resource)
            await fetchOwnUser()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            AppLogger.error("updateVisibility failed: \(error.localizedDescription)", category: "UserManagement")
        }
    }

    func sendFriendRequest(to username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.sendFriendRequest, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .post(nil), modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
    }

    func acceptFriendRequest(from username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.acceptFriendRequest, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .post(nil), modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await fetchOwnUser()
    }

    func rejectFriendRequest(from username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.rejectFriendRequest, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await fetchOwnUser()
    }

    func removeFriend(_ username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.removeFriend, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await fetchOwnUser()
    }

    func clearError() {
        errorMessage = nil
    }
}

#if DEBUG
    extension UserManagerImpl {
        @MainActor
        static func preview(profile: User?) -> UserManagerImpl {
            let manager = UserManagerImpl(authenticationManager: AuthenticationManagerImpl.shared)
            manager.currentUserProfile = profile
            return manager
        }
    }
#endif
