//
//  LeagueDetailView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import SwiftUI

struct LeagueDetailView: View {
    @ObservedObject var viewModel: LeagueDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appFactory: ViewModeFactoryImpl

    @State private var showInvitationSheet = false
    @State private var showAddGame = false
    @State private var confirmDelete = false

    var body: some View {
        Form {
            headerSection
            standingsSection
            matchesSection
            membersSection

            if viewModel.isAdmin {
                adminSection
            }
        }
        .navigationTitle(viewModel.league.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddGame = true
                } label: {
                    Label("Add Game", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddGame) {
            NavigationStack {
                AddGameView(viewModel: appFactory.createAddGameViewModel(forLeague: viewModel.league))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAddGame = false
                            }
                        }
                    }
            }
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
        .sheet(isPresented: $showInvitationSheet) {
            InvitationCodeSheet(code: viewModel.generatedInvitationCode ?? "")
        }
        .onChange(of: viewModel.generatedInvitationCode) { _, newValue in
            showInvitationSheet = (newValue != nil)
        }
        .confirmationDialog(
            "Delete this league? This cannot be undone.",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteLeague { dismiss() }
            }
        }
    }

    private var headerSection: some View {
        Section {
            if let description = viewModel.league.description, !description.isEmpty {
                Text(description)
            }
            LabeledContent("Ends", value: viewModel.league.duration.formatted(date: .abbreviated, time: .omitted))
            HStack {
                Text("Game types").foregroundStyle(.secondary)
                Spacer()
                ForEach(viewModel.league.gameTypes, id: \.self) { type in
                    Text(type)
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    private var standingsSection: some View {
        Section("Standings") {
            if viewModel.leaderboard.isEmpty {
                InlineEmptyState(
                    icon: "list.number",
                    text: "Standings will appear once games are played."
                )
            } else {
                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, row in
                    HStack {
                        Text("\(index + 1).")
                            .frame(width: 24, alignment: .leading)
                            .foregroundColor(.secondary)
                        Text("@\(row.username)")
                        Spacer()
                        Text("\(row.wins)-\(row.draws)-\(row.losses)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                        Text("\(row.points) pts")
                            .font(.callout.bold().monospacedDigit())
                    }
                }
            }
        }
    }

    private var matchesSection: some View {
        Section("Matches") {
            if viewModel.sortedMatches.isEmpty {
                InlineEmptyState(
                    icon: "calendar.badge.exclamationmark",
                    text: "No games have been recorded in this league yet."
                )
            } else {
                ForEach(viewModel.sortedMatches) { game in
                    NavigationLink(value: game) {
                        GameRowView(game: game, currentUsername: nil)
                    }
                }
            }
        }
        .navigationDestination(for: Game.self) { game in
            GameDetailView(game: game, currentUsername: nil)
        }
    }

    private var membersSection: some View {
        Section("Members (\(viewModel.league.users.count))") {
            ForEach(viewModel.league.users) { user in
                HStack {
                    Text("@\(user.username)")
                    if viewModel.league.isAdmin(username: user.username) {
                        Text("Admin")
                            .font(.caption2.bold())
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var adminSection: some View {
        Section("Admin") {
            HStack {
                TextField("Username to add", text: $viewModel.newMemberUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Add") { viewModel.addMember() }
                    .disabled(viewModel.newMemberUsername.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Button {
                viewModel.generateInvitation()
            } label: {
                Label("Generate invitation code", systemImage: "envelope.badge")
            }

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Label("Delete league", systemImage: "trash")
            }
        }
    }
}

#if DEBUG
#Preview("League detail – with matches") {
    NavigationStack {
        LeagueDetailView(viewModel: LeagueDetailViewModel.preview(league: PreviewSamples.leagueWithMatches))
    }
}

#Preview("League detail – empty matches") {
    NavigationStack {
        LeagueDetailView(viewModel: LeagueDetailViewModel.preview(league: PreviewSamples.leagueEmpty, asAdmin: false))
    }
}

#Preview("Invitation sheet") {
    InvitationCodeSheet(code: "f47ac10b-58cc-4372-a567-0e02b2c3d479")
}
#endif

struct InvitationCodeSheet: View {
    let code: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tint)
                Text("Invitation code")
                    .font(.title2.bold())
                Text(code)
                    .font(.system(.title3, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .textSelection(.enabled)

                Button {
                    UIPasteboard.general.string = code
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Text("Share this code with someone you want to invite. It expires in 7 days.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
            .padding(.top, 32)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
