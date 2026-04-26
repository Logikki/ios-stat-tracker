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
                        // Show loading indicator only on initial login
                        await self.fetchOwnUser(showLoadingIndicator: true)
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

    /// Fetch the current user's profile
    /// - Parameter showLoadingIndicator: If true, sets isLoading which triggers the full-screen loading state
    func fetchOwnUser(showLoadingIndicator: Bool = false) async {
        fetchTask?.cancel()

        // Skip if already loading
        if isLoading, showLoadingIndicator {
            AppLogger.info("Fetch already in progress, skipping duplicate call", category: "UserManagement")
            return
        }

        fetchTask = Task { @MainActor in
            if showLoadingIndicator {
                isLoading = true
            }
            errorMessage = nil
            defer {
                if showLoadingIndicator {
                    isLoading = false
                }
            }

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
            // Refresh silently in the background
            await fetchOwnUser(showLoadingIndicator: false)
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
        // Refresh silently in the background
        await fetchOwnUser(showLoadingIndicator: false)
    }

    func rejectFriendRequest(from username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.rejectFriendRequest, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await fetchOwnUser(showLoadingIndicator: false)
    }

    func removeFriend(_ username: String) async throws {
        let path = String(format: Constants.API.FriendRequest.removeFriend, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await fetchOwnUser(showLoadingIndicator: false)
    }

    func uploadAvatar(_ jpeg: Data) async throws {
        guard let url = URL(string: Constants.API.URL + Constants.API.User.uploadAvatar) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token = AuthenticationManagerImpl.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        let (_, response) = try await URLSession.shared.upload(for: request, from: body)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    func deleteAvatar() async throws {
        guard let url = URL(string: Constants.API.URL + Constants.API.User.deleteAvatar) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if let token = AuthenticationManagerImpl.shared.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }

    func fetchUser(username: String) async throws -> OtherUserProfile {
        let path = String(format: Constants.API.User.getUser, username)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .get([]), modelType: OtherUserProfile.self)
        return try await HTTPClient.shared.load(resource)
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
