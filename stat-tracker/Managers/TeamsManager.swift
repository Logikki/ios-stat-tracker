//
//  TeamsManager.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

protocol TeamsManager {
    func getNHLTeams() -> [HockeyTeam]
}

final class TeamsManagerImpl: TeamsManager {
    let availableTeams = HockeyTeam.allCases

    func getNHLTeams() -> [HockeyTeam] {
        return availableTeams
    }
}
