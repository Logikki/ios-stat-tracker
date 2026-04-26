//
//  AuthenticatedContentView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 7.6.2025.
//

import SwiftUI

struct AuthenticatedContentView: View {
    @EnvironmentObject var dependencies: DependencyContainer

    @State private var selectedTab: Tab = .games
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    enum Tab {
        case games, add, leagues, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                GamesView(viewModel: dependencies.getGamesViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Games", systemImage: "list.bullet.rectangle") }
            .tag(Tab.games)

            NavigationStack {
                AddGameView(viewModel: dependencies.createAddGameViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Add", systemImage: "plus.circle.fill") }
            .tag(Tab.add)

            NavigationStack {
                LeaguesView(viewModel: dependencies.getLeaguesViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Leagues", systemImage: "trophy") }
            .tag(Tab.leagues)

            NavigationStack {
                ProfileView(viewModel: dependencies.getProfileViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            .tag(Tab.profile)
        }
        .tint(.blue)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: dependencies.getSettingsViewModel())
                .environmentObject(dependencies.authenticationManager)
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
            }
        }
    }
}

#if DEBUG
    #Preview("Authenticated tabs") {
        return AuthenticatedContentView()
            .environmentObject(AuthenticationManagerImpl.shared)
    }
#endif
