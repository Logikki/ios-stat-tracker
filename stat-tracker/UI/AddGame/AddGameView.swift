//
//  AddGameView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

struct AddGameView: View {
    @ObservedObject var viewModel: AddGameViewModel

    var body: some View {
        Form {
            Section("Game type") {
                Picker("Type", selection: $viewModel.gameType) {
                    ForEach(GameType.allCases) { type in
                        Label(type.displayName, systemImage: type.systemImage).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(viewModel.isLeagueLocked)
                
                if viewModel.isLeagueLocked {
                    Text("Game type is limited to this league's supported types")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Players") {
                Toggle("I'm the home player", isOn: $viewModel.homeIsMe)

                if viewModel.canPickFromList && !viewModel.manualOpponent {
                    Picker("Opponent", selection: $viewModel.opponentUsername) {
                        Text("Choose…").tag("")
                        ForEach(viewModel.availableOpponents) { user in
                            Text("@\(user.username)").tag(user.username)
                        }
                    }
                    Button {
                        viewModel.manualOpponent = true
                        viewModel.opponentUsername = ""
                    } label: {
                        Label("Type a username instead", systemImage: "keyboard")
                            .font(.footnote)
                    }
                } else {
                    TextField("Opponent username", text: $viewModel.opponentUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if viewModel.canPickFromList {
                        Button {
                            viewModel.manualOpponent = false
                            viewModel.opponentUsername = ""
                        } label: {
                            Label("Pick from your friends/leagues", systemImage: "person.2")
                                .font(.footnote)
                        }
                    } else {
                        Text("Add friends or join a league to pick opponents from a list.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section(viewModel.gameType == .NHL ? "Teams (NHL)" : "Teams") {
                if viewModel.gameType == .NHL {
                    Picker("Home team", selection: $viewModel.homeTeam) {
                        Text("Choose…").tag("")
                        ForEach(viewModel.nhlTeams) { team in
                            Text(team.rawValue).tag(team.rawValue)
                        }
                    }
                    Picker("Away team", selection: $viewModel.awayTeam) {
                        Text("Choose…").tag("")
                        ForEach(viewModel.nhlTeams) { team in
                            Text(team.rawValue).tag(team.rawValue)
                        }
                    }
                } else {
                    TextField("Home team", text: $viewModel.homeTeam)
                    TextField("Away team", text: $viewModel.awayTeam)
                }
            }

            Section("Score") {
                Stepper("Home: \(viewModel.homeScore)", value: $viewModel.homeScore, in: 0...50)
                Stepper("Away: \(viewModel.awayScore)", value: $viewModel.awayScore, in: 0...50)
            }

            Section("Details") {
                DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                Toggle("Overtime", isOn: $viewModel.overtime)
                Toggle("Penalties / shootout", isOn: $viewModel.penalties)
            }

            if viewModel.shouldShowLeaguePicker {
                Section {
                    if viewModel.isLeagueLocked {
                        // Show locked league (read-only)
                        LabeledContent("League", value: viewModel.leaguesForCurrentType.first?.name ?? "")
                    } else {
                        // Show picker for selecting league
                        Picker("League (optional)", selection: $viewModel.selectedLeagueId) {
                            Text("None").tag(String?.none)
                            ForEach(viewModel.leaguesForCurrentType) { league in
                                Text(league.name).tag(Optional(league.id))
                            }
                        }
                    }
                } header: {
                    Text("League")
                } footer: {
                    if viewModel.isLeagueLocked {
                        Text("This game will be added to the selected league")
                    } else {
                        Text("Optionally assign this game to a league")
                    }
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                }
            }

            Section {
                Button {
                    viewModel.submit()
                } label: {
                    HStack {
                        if viewModel.isSubmitting { ProgressView() }
                        Text("Save game")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!viewModel.canSubmit)
            }
        }
        .navigationTitle("Add game")
        .alert("Game saved", isPresented: $viewModel.didSubmitSuccessfully) {
            Button("OK", role: .cancel) {}
        }
    }
}

#if DEBUG
#Preview("Add game – with friends") {
    NavigationStack {
        AddGameView(viewModel: AddGameViewModel.preview())
    }
}

#Preview("Add game – no friends") {
    NavigationStack {
        AddGameView(viewModel: AddGameViewModel.preview(profile: PreviewSamples.userEmpty))
    }
}
#endif
