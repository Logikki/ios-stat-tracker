//
//  addGameViewModel.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import Foundation
import SwiftUICore

class AddGameViewModel: ObservableObject {
    @Published var homeTeam: String = ""
    @Published var awayTeam: String = ""
    @Published var homeScore: Int = 0
    @Published var awayScore: Int = 0
    @Published var gameTime: Date = Date()
    @Published var isOvertime: Bool = false
    @Published var showError: Bool = false
    @Published var showSuccess: Bool = false
    @Published var errorMessage: String = ""
    @Published var isSaving: Bool = false
    
    @Published var selectedHomePlayer: String?
    @Published var selectedAwayPlayer: String?
    @Published var selectedHomeTeam: NHLTeam?
    @Published var selectedAwayTeam: NHLTeam?
    
    @Published var players: [Player]?
    @Published var nhlTeams: [NHLTeam]?

    let isEditing: Bool = false
    private let existingGameId: UUID?
    
    var gameManager: GameManager?
    var teamsManager: TeamsManager?

    init(teamsManager: TeamsManager, playerManager: PlayerManager) {
        self.teamsManager = teamsManager
        self.players = playerManager.fetchPlayers()
        self.nhlTeams = self.teamsManager?.getNHLTeams()
        self.existingGameId = UUID()
    }
    
    // In a real app, this would likely come from a service or database
    var isValid: Bool {
        !homeTeam.isEmpty &&
        !awayTeam.isEmpty &&
        homeTeam != awayTeam &&
        selectedHomePlayer != nil &&
        selectedAwayPlayer != nil
    }
}

extension AddGameViewModel {
    func playerFromName(id: String) -> Player? {
        return self.players?.first(where: { $0.fullName == id })
    }
}

extension AddGameViewModel {
    func saveGame() async -> Game? {
        guard isValid else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return nil
        }
        
        guard let homePlayer = self.players?.first(where: { $0.fullName == selectedHomePlayer }) else {
            errorMessage = "Could not resolve name"
            showError = true
            return nil
        }
        
        guard let awayPlayer = self.players?.first(where: { $0.fullName == selectedAwayPlayer }) else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return nil
        }
        
        guard let homeTeam = NHLTeam(rawValue: homeTeam) else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return nil
        }
        
        guard let awayTeam = NHLTeam(rawValue: awayTeam) else {
            errorMessage = "Please fill in all required fields"
            showError = true
            return nil
        }
        
        let game = Game(
            id: existingGameId ?? UUID(),
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homePlayer: homePlayer,
            awayPlayer: awayPlayer,
            time: gameTime,
            overTime: isOvertime
        )
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            // Here you would typically save to your data store
            // For example:
            // try await gameService.saveGame(game)
            showSuccess = true
            print("Saved game: \(game)")
            return game
        } catch {
            errorMessage = "Failed to save game: \(error.localizedDescription)"
            showError = true
            return nil
        }
    }
}
