//
//  Game.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

struct Game {
    let league: String?
    let gameType: String
    let homeTeam: String
    let awayTeam: String
    let homeScore: Int
    let awayScore: Int
    let homePlayer: String
    let awayPlayer: String
    let overTime: Bool?
    let penalties: Bool?
    let createdAt: Date
    let updatedAt: Date?

    init?(json: [String: Any]) {
        guard let gameType = json["gameType"] as? String,
              let homeTeam = json["homeTeam"] as? String,
              let awayTeam = json["awayTeam"] as? String,
              let homeScore = json["homeScore"] as? Int,
              let awayScore = json["awayScore"] as? Int,
              let homePlayer = json["homePlayer"] as? String,
              let awayPlayer = json["awayPlayer"] as? String,
              let createdAtString = json["createdAt"] as? String,
              let createdAt = ISO8601DateFormatter().date(from: createdAtString) else {
            return nil
        }

        self.league = json["league"] as? String
        self.gameType = gameType
        self.homeTeam = homeTeam
        self.awayTeam = awayTeam
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.homePlayer = homePlayer
        self.awayPlayer = awayPlayer
        self.overTime = json["overTime"] as? Bool
        self.penalties = json["penalties"] as? Bool
        self.createdAt = createdAt

        if let updatedAtString = json["updatedAt"] as? String {
            self.updatedAt = ISO8601DateFormatter().date(from: updatedAtString)
        } else {
            self.updatedAt = nil
        }
    }
}
