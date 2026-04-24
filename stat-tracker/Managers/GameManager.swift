//
//  GameManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

final class GameManagerImpl: ObservableObject {
    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        AppLogger.info("GameManager initialized.", category: "Games")
    }

    @MainActor
    func fetchGames() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: Constants.API.Game.getGames) else {
            errorMessage = "Failed to build games URL."
            return
        }

        let resource = Resource(url: url, method: .get([]), modelType: [Game].self)
        do {
            let fetched = try await HTTPClient.shared.load(resource)
            self.games = fetched.sorted(by: { $0.createdAt > $1.createdAt })
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("fetchGames failed: \(error.localizedDescription)", category: "Games")
        }
    }

    func createGame(_ payload: CreateGamePayload) async throws -> Game {
        guard let url = URL(string: Constants.API.Game.createGame) else {
            throw NetworkError.invalidURL
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let resource = Resource(url: url, method: .post(data), modelType: Game.self)
        return try await HTTPClient.shared.load(resource)
    }

    func deleteGame(id: String) async throws {
        let path = String(format: Constants.API.Game.deleteGame, id)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        await MainActor.run {
            self.games.removeAll(where: { $0.id == id })
        }
    }
}

#if DEBUG
extension GameManagerImpl {
    @MainActor
    static func preview(games: [Game]) -> GameManagerImpl {
        let manager = GameManagerImpl()
        manager.games = games
        return manager
    }
}
#endif

public struct CreateGamePayload: Encodable {
    public let homeTeam: String
    public let awayTeam: String
    public let homePlayer: String
    public let awayPlayer: String
    public let homeScore: Int
    public let awayScore: Int
    public let createdAt: Date
    public let overTime: Bool?
    public let penalties: Bool?
    public let league: String?
    public let gameType: GameType
}
