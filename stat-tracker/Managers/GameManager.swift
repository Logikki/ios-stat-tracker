//
//  GameSaverManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//
import Foundation

protocol GameManager {
    func fetchGames() -> [Game]?
}

public struct GameManagerImpl: GameManager {
    
}

// MARK: Actions
extension GameManagerImpl {
    func fetchGames() -> [Game]? {
        return nil
    }
}
