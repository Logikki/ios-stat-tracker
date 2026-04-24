//
//  LeagueManager.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Foundation

final class LeagueManagerImpl: ObservableObject {
    @Published var errorMessage: String? = nil

    init() {
        AppLogger.info("LeagueManager initialized.", category: "Leagues")
    }

    func createLeague(_ payload: CreateLeaguePayload) async throws -> League {
        guard let url = URL(string: Constants.API.League.createLeague) else {
            throw NetworkError.invalidURL
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let resource = Resource(url: url, method: .post(data), modelType: League.self)
        return try await HTTPClient.shared.load(resource)
    }

    func deleteLeague(id: String) async throws {
        let path = String(format: Constants.API.League.deleteLeague, id)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
    }

    func addUser(username: String, toLeague leagueId: String) async throws -> League {
        let path = String(format: Constants.API.League.putUserToLeague, leagueId)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }

        struct Body: Encodable { let username: String }
        let data = try JSONEncoder().encode(Body(username: username))

        let resource = Resource(url: url, method: .post(data), modelType: League.self)
        return try await HTTPClient.shared.load(resource)
    }

    func createInvitation(leagueId: String) async throws -> String {
        let path = String(format: Constants.API.League.createLeagueInvitation, leagueId)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .post(nil), modelType: InvitationCodeResponse.self)
        let response = try await HTTPClient.shared.load(resource)
        return response.code
    }

    func acceptInvitation(code: String) async throws -> League {
        let path = String(format: Constants.API.League.acceptLeagueInvitation, code)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .post(nil), modelType: League.self)
        return try await HTTPClient.shared.load(resource)
    }
}

public struct CreateLeaguePayload: Encodable {
    public let name: String
    public let description: String?
    public let gameTypes: [GameType]
    public let users: [String]
    public let admins: [String]
    public let duration: Date
}
