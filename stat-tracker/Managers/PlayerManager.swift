//
//  PlayerManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

protocol PlayerManager {
    func saveGame(_ game: Game) async throws
    func fetchGamesForPlayer() -> [Game]?
    func fetchPlayers() -> [Player]?
}

final class PlayerManagerImpl: PlayerManager {
    func saveGame(_ game: Game) {
        // todo
    }
    
    func fetchGamesForPlayer() -> [Game]? {
        return nil
    }
}

extension PlayerManager {
    public func fetchPlayers() -> [Player]? {
        return [
            Player(firstName: "Roni", lastName: "Koskinen"),
            Player(firstName: "Jesse", lastName: "Haimi"),
            Player(firstName: "Juuso", lastName: "Vuorela"),
        ]
    }
}

