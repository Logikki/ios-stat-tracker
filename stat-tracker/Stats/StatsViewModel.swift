//
//  StatsViewModel.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation

class StatsViewModel: ObservableObject {
    @Published var players: [Player]?
    @Published var nhlTeams: [NHLTeam]?

    var gameManager: GameManager?
    var teamsManager: TeamsManager?
    init(teamsManager: TeamsManager, playerManager: PlayerManager) {
        self.teamsManager = teamsManager
        self.players = playerManager.fetchPlayers()
        self.nhlTeams = self.teamsManager?.getNHLTeams()
    }
}
