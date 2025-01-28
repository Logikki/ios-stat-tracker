//
//  GameSaverManager.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//
import Foundation

protocol GameManager {
    func fetchGames() -> [Game]
}

public struct GameManagerImpl: GameManager {
    
}

// MARK: Actions
extension GameManagerImpl {
    func fetchGames() -> [Game] {
        let player1 = Player(firstName: "Roni", lastName: "Koskinen")
        let player2 = Player(firstName: "Jesse", lastName: "Haimi")
        let player3 = Player(firstName: "Juuso", lastName: "Vuorela")
        
        let game1 = Game(
            id: UUID(),
            homeTeam: .edmontonOilers,
            awayTeam: .torontoMapleLeafs,
            homePlayer: player1,
            awayPlayer: player2,
            time: Date(),
            overTime: false
        )
        
        let game2 = Game(
            id: UUID(),
            homeTeam: .coloradoAvalanche,
            awayTeam: .pittsburghPenguins,
            homePlayer: player2,
            awayPlayer: player3,
            time: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            overTime: true
        )
        
        let game3 = Game(
            id: UUID(),
            homeTeam: .calgaryFlames,
            awayTeam: .montrealCanadiens,
            homePlayer: player3,
            awayPlayer: player1,
            time: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
            overTime: false
        )
        
        return [game1, game2, game3]
    }
}

