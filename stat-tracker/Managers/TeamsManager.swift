//
//  TeamsManager.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

protocol TeamsManager {
    func getNHLTeams() -> [NHLTeam]
}

final class TeamsManagerImpl: TeamsManager {
    let availableTeams = NHLTeam.allCases
    
    public func getNHLTeams() -> [NHLTeam] {
        return availableTeams
    }
}
