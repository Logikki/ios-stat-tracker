//
//  GamesView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 7.6.2025.
//

import SwiftUI

struct GamesView: View {
    @ObservedObject var viewModel: GamesViewModel

    var body: some View {
        contentView
            .navigationTitle("Games")
            .navigationDestination(for: Game.self) { game in
                GameDetailView(game: game, currentUsername: viewModel.currentUsername)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if viewModel.games.isEmpty {
            emptyState
        } else {
            List {
                ForEach(viewModel.games) { game in
                    NavigationLink(value: game) {
                        GameRowView(game: game, currentUsername: viewModel.currentUsername)
                    }
                }
                .onDelete { indices in
                    for idx in indices {
                        viewModel.deleteGame(viewModel.games[idx])
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "sportscourt",
            title: "No games yet",
            message: "Tap the Add tab to record your first match."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GameRowView: View {
    let game: Game
    let currentUsername: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: game.gameTypeEnum?.systemImage ?? "questionmark.circle")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(game.homeTeam).font(.headline)
                    Text("vs").foregroundColor(.secondary)
                    Text(game.awayTeam).font(.headline)
                }
                HStack(spacing: 8) {
                    Text("@\(game.homePlayer.username)")
                    Text("vs")
                    Text("@\(game.awayPlayer.username)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(game.scoreLine)
                    .font(.headline.monospacedDigit())
                if let username = currentUsername {
                    Text(game.resultLabel(forCurrentUser: username))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(resultColor(for: game.resultLabel(forCurrentUser: username)))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func resultColor(for label: String) -> Color {
        switch label {
        case "W": return .green
        case "L": return .red
        default:  return .gray
        }
    }
}

struct GameDetailView: View {
    let game: Game
    let currentUsername: String?

    var body: some View {
        Form {
            Section("Match") {
                LabeledContent("Type", value: game.gameTypeEnum?.displayName ?? game.gameType)
                LabeledContent("Date", value: game.createdAt.formatted(date: .abbreviated, time: .shortened))
                if let ot = game.overTime, ot { LabeledContent("Overtime", value: "Yes") }
                if let pen = game.penalties, pen { LabeledContent("Penalties", value: "Yes") }
            }

            Section("Home") {
                LabeledContent("Team", value: game.homeTeam)
                LabeledContent("Player", value: "@\(game.homePlayer.username)")
                LabeledContent("Score", value: "\(game.homeScore)")
            }

            Section("Away") {
                LabeledContent("Team", value: game.awayTeam)
                LabeledContent("Player", value: "@\(game.awayPlayer.username)")
                LabeledContent("Score", value: "\(game.awayScore)")
            }

            if let username = currentUsername {
                Section("Result") {
                    Text(resultText(for: username))
                        .font(.title3.bold())
                }
            }
        }
        .navigationTitle("Game details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resultText(for username: String) -> String {
        switch game.resultLabel(forCurrentUser: username) {
        case "W": return "Win"
        case "L": return "Loss"
        default:  return "Draw"
        }
    }
}

#if DEBUG
#Preview("Games – list") {
    NavigationStack {
        GamesView(viewModel: GamesViewModel.preview(games: PreviewSamples.games, includeProfile: true))
    }
}

#Preview("Games – empty") {
    NavigationStack {
        GamesView(viewModel: GamesViewModel.preview(games: [], includeProfile: true))
    }
}

#Preview("Game row") {
    List {
        GameRowView(game: PreviewSamples.nhlGameRecent, currentUsername: "alice")
        GameRowView(game: PreviewSamples.nhlGameLoss, currentUsername: "alice")
        GameRowView(game: PreviewSamples.fifaGame, currentUsername: "alice")
    }
}

#Preview("Game detail") {
    NavigationStack {
        GameDetailView(game: PreviewSamples.nhlGameRecent, currentUsername: "alice")
    }
}
#endif
