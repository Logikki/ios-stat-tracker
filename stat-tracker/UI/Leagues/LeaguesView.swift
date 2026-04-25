//
//  LeaguesView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 19.6.2025.
//

import SwiftUI

struct LeaguesView: View {
    @ObservedObject var viewModel: LeaguesViewModel
    @EnvironmentObject var appFactory: ViewModeFactoryImpl

    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        Group {
            if viewModel.leagues.isEmpty {
                emptyState
            } else {
                List(viewModel.leagues) { league in
                    NavigationLink(value: league) {
                        LeagueRowView(league: league)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Leagues")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showCreate = true
                    } label: {
                        Label("Create league", systemImage: "plus.circle")
                    }
                    Button {
                        showJoin = true
                    } label: {
                        Label("Join with code", systemImage: "envelope.open")
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable { 
            await viewModel.refresh() 
        }
        .navigationDestination(for: League.self) { league in
            LeagueDetailView(viewModel: appFactory.createLeagueDetailViewModel(league: league))
        }
        .sheet(isPresented: $showCreate) {
            NavigationStack {
                CreateLeagueView(viewModel: appFactory.createCreateLeagueViewModel(),
                                 onDone: { showCreate = false })
            }
        }
        .sheet(isPresented: $showJoin) {
            NavigationStack {
                JoinLeagueView(viewModel: appFactory.createJoinLeagueViewModel(),
                               onDone: { showJoin = false })
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "person.3.sequence",
            title: "You're not in any leagues yet",
            message: "Create your own league or join one with an invitation code from a friend.",
            actionTitle: "Create league",
            action: { showCreate = true }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview("Leagues – list") {
    NavigationStack {
        LeaguesView(viewModel: LeaguesViewModel.preview(profile: PreviewSamples.userWithEverything))
            .environmentObject(ViewModeFactoryImpl.preview())
    }
}

#Preview("Leagues – empty") {
    NavigationStack {
        LeaguesView(viewModel: LeaguesViewModel.preview(profile: PreviewSamples.userEmpty))
            .environmentObject(ViewModeFactoryImpl.preview(profile: PreviewSamples.userEmpty))
    }
}

#Preview("League row") {
    List {
        LeagueRowView(league: PreviewSamples.leagueWithMatches)
        LeagueRowView(league: PreviewSamples.leagueEmpty)
    }
}
#endif

struct LeagueRowView: View {
    let league: League

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(league.name).font(.headline)
            HStack(spacing: 6) {
                ForEach(league.gameTypes, id: \.self) { type in
                    Text(type)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.15))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                Spacer()
                Text("\(league.users.count) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
