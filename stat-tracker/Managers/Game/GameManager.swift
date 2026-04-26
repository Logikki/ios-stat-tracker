//
//  GameManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

@MainActor
final class GameManagerImpl: ObservableObject {

    @Published private(set) var games: [Game] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var fetchTask: Task<Void, Never>?

    init() {
        AppLogger.info("GameManager initialized.", category: "Games")
    }

    func fetchGames() async {
        // Cancel any existing fetch task
        fetchTask?.cancel()

        guard !isLoading else {
            AppLogger.info("Fetch already in progress, skipping duplicate call", category: "Games")
            return
        }

        fetchTask = Task { @MainActor in
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }

            guard let url = URL(string: Constants.API.Game.getGames) else {
                errorMessage = "Failed to build games URL."
                return
            }

            let resource = Resource(url: url, method: .get([]), modelType: LossyArray<Game>.self)
            do {
                let fetched = try await HTTPClient.shared.load(resource)

                guard !Task.isCancelled else {
                    AppLogger.info("Fetch games task was cancelled", category: "Games")
                    return
                }

                self.games = fetched.elements.sorted(by: { $0.createdAt > $1.createdAt })
            } catch is CancellationError {
                AppLogger.info("Fetch games request cancelled", category: "Games")
            } catch {
                if (error as NSError).code != NSURLErrorCancelled {
                    errorMessage = error.localizedDescription
                    AppLogger.error("fetchGames failed: \(error.localizedDescription)", category: "Games")
                }
            }
        }

        await fetchTask?.value
    }

    /// Create a game with comprehensive error handling
    /// - Parameter payload: The game data to create
    /// - Returns: A result indicating success or the specific type of failure
    func createGameWithErrorHandling(_ payload: CreateGamePayload) async -> CreateGameResult {
        do {
            let game = try await createGame(payload)
            AppLogger.info("Game created successfully: \(game.id)", category: "Games")
            return .success(game)
        } catch let networkError as NetworkError {
            // Handle specific network errors
            if case .httpError(404, _) = networkError, payload.league != nil {
                AppLogger.error("League not found when creating game", category: "Games")
                return .leagueNotFound
            } else {
                let message = networkError.localizedDescription
                AppLogger.error("createGame failed: \(message)", category: "Games")
                return .error(message)
            }
        } catch {
            // Handle other errors
            let message = error.localizedDescription
            AppLogger.error("createGame failed: \(message)", category: "Games")
            return .error(message)
        }
    }

    func deleteGame(id: String) async throws {
        let path = String(format: Constants.API.Game.deleteGame, id)
        guard let url = URL(string: path) else { throw NetworkError.invalidURL }
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
        games.removeAll(where: { $0.id == id })
    }
}

// MARK: GameManager + Private methods

extension GameManagerImpl {
    private func createGame(_ payload: CreateGamePayload) async throws -> Game {
        guard let url = URL(string: Constants.API.Game.createGame) else {
            throw NetworkError.invalidURL
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let resource = Resource(url: url, method: .post(data), modelType: Game.self)
        return try await HTTPClient.shared.load(resource)
    }
}

#if DEBUG
    extension GameManagerImpl {
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
