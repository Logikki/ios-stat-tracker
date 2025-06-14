//
//  Game.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

public struct Game: Codable, Identifiable {
    public let id: String
    public let league: String?
    public let gameType: String
    public let homeTeam: String
    public let awayTeam: String
    public let homeScore: Int
    public let awayScore: Int
    public let homePlayer: LightUser
    public let awayPlayer: LightUser
    public let overTime: Bool?
    public let penalties: Bool?
    public let createdAt: Date
    public let updatedAt: Date?
}
