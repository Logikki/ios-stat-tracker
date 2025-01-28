//
//  Player.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

struct Player: Identifiable, Codable, Hashable, Equatable {
    var id: UUID
    var firstName: String
    var lastName: String
    var games: [Game]?
    
    // Computed Properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    // Custom initializer
    init(id: UUID = UUID(), firstName: String, lastName: String, games: [Game]? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.games = games
    }
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Conformance to Equatable
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper methods
    func gamesPlayed() -> Int {
        games?.count ?? 0
    }
    
    func gamesAsHomePlayer() -> [Game] {
        games?.filter { $0.homePlayer.id == id } ?? []
    }
    
    func gamesAsAwayPlayer() -> [Game] {
        games?.filter { $0.awayPlayer.id == id } ?? []
    }
}
