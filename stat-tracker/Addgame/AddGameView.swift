//
//  AddGameView.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUICore
import SwiftUI

// MARK: - View
struct AddGameView: View {
    @ObservedObject private var viewModel: AddGameViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(viewModel: AddGameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                Form {
                    teamsSection()
                    playersSection()
                    gameDetailsSection()
                    saveButtonSection()
                }
                .navigationTitle(viewModel.isEditing ? "Edit Game" : "New Game")
                .alert("Error", isPresented: $viewModel.showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(viewModel.errorMessage)
                }
                .alert("Success", isPresented: $viewModel.showSuccess) {
                    Button("OK", role: .cancel) {
                        self.dismiss()
                    }
                } message: {
                    Text("Game has been saved successfully!")
                }
            }
        }
    }
}

// MARK: Views

extension AddGameView {
    func teamsSection() -> some View {
        Section(header: Text("Teams")) {
            Picker("Home team", selection: $viewModel.selectedHomeTeam) {
                ForEach(viewModel.nhlTeams ?? []) { team in
                    Text(team.rawValue).tag(team)
                }
            }
            
            Picker("Away team", selection: $viewModel.selectedAwayTeam) {
                ForEach(viewModel.nhlTeams ?? []) { team in
                    Text(team.rawValue).tag(team)
                }
            }
        }
    }
    
    private func playersSection() -> some View {
        Section(header: Text("Players")) {
            Picker("Home player", selection: $viewModel.selectedHomePlayer) {
                ForEach(viewModel.players ?? []) { player in
                    Text(player.fullName).tag(player.fullName)
                }
            }
            
            Picker("Away player", selection: $viewModel.selectedAwayPlayer) {
                ForEach(viewModel.players ?? []) { player in
                    Text(player.fullName).tag(player.fullName)
                }
            }
        }
    }
    
    private func saveButtonSection() -> some View {
        Section {
            Button(action: saveGame) {
                HStack {
                    Spacer()
                    if viewModel.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text(viewModel.isEditing ? "Update Game" : "Add Game")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.isValid || viewModel.isSaving)
        }
    }
    
    private func gameDetailsSection() -> some View {
        Section(header: Text("Game Details")) {
            DatePicker("Time", selection: $viewModel.gameTime)
            Toggle("Overtime", isOn: $viewModel.isOvertime)
        }
    }
}

extension AddGameView {
    private func saveGame() {
        Task {
            if let savedGame = await viewModel.saveGame() {
                dismiss()
            }
        }
    }
}
