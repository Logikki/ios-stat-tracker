//
//  CreateGameResult.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 26.4.2026.
//

public enum CreateGameResult {
    case success(Game)
    case leagueNotFound
    case error(String)
}
