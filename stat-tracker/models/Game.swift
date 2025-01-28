//
//  Game.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

struct Game: Identifiable, Codable, Hashable, Equatable {
    var id: UUID
    var homeTeam: NHLTeam
    var awayTeam: NHLTeam
    var homePlayer: Player
    var awayPlayer: Player
    var time: Date
    var overTime: Bool?
    
    // Computed Properties
    var isOvertime: Bool {
        overTime ?? false
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    // Custom initializer
    init(
        id: UUID = UUID(),
        homeTeam: NHLTeam,
        awayTeam: NHLTeam,
        homePlayer: Player,
        awayPlayer: Player,
        time: Date = Date(),
        overTime: Bool? = nil
    ) {
        self.id = id
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homePlayer = homePlayer
        self.awayPlayer = awayPlayer
        self.time = time
        self.overTime = overTime
    }
    
    // Conformance to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Conformance to Equatable
    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }
    
    // Helper methods
    func involves(player: Player) -> Bool {
        homePlayer.id == player.id || awayPlayer.id == player.id
    }
    
    func isHomePlayer(_ player: Player) -> Bool {
        homePlayer.id == player.id
    }
    
    func isAwayPlayer(_ player: Player) -> Bool {
        awayPlayer.id == player.id
    }
}
