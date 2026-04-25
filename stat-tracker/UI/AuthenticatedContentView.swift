//
//  AuthenticatedContentView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 7.6.2025.
//

import SwiftUI

struct AuthenticatedContentView: View {
    @EnvironmentObject var authenticationManager: AuthenticationManagerImpl
    @EnvironmentObject var appFactory: ViewModeFactoryImpl

    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        TabView {
            NavigationStack {
                GamesView(viewModel: appFactory.createGamesViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Games", systemImage: "list.bullet.rectangle") }

            NavigationStack {
                AddGameView(viewModel: appFactory.createAddGameViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Add", systemImage: "plus.circle.fill") }

            NavigationStack {
                LeaguesView(viewModel: appFactory.createLeaguesViewModel())
                    .environmentObject(appFactory)
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Leagues", systemImage: "trophy") }

            NavigationStack {
                ProfileView(viewModel: appFactory.createProfileViewModel())
                    .toolbar { settingsToolbar }
            }
            .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.blue)
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: appFactory.createSettingsViewModel())
                .environmentObject(authenticationManager)
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
        let factory = ViewModeFactoryImpl.preview()
        return AuthenticatedContentView()
            .environmentObject(AuthenticationManagerImpl.shared)
            .environmentObject(factory)
    }
#endif
