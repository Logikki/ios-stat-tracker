//
//  Factory.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

// MARK: - Factory Protocol
protocol ViewModelFactory {
    func createAddGameViewModel() -> AddGameViewModel
    func createStatsViewModel() -> StatsViewModel
}

// MARK: - Concrete Factory
class AppViewModelFactory: ViewModelFactory {
    private let teamsManager: TeamsManager
    private let playerManager: PlayerManager
    
    public init(
        teamsManager: TeamsManager = TeamsManagerImpl(),
        playerManager: PlayerManager = PlayerManagerImpl()) {
        self.playerManager = playerManager
        self.teamsManager = teamsManager
    }
    
    func createAddGameViewModel() -> AddGameViewModel {
        AddGameViewModel(
            teamsManager: self.teamsManager,
            playerManager: self.playerManager
        )
    }
    
    func createStatsViewModel() -> StatsViewModel {
        StatsViewModel(
            teamsManager: self.teamsManager,
            playerManager: self.playerManager
        )
    }
}
