//
//  AuthenticatedContentView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 7.6.2025.
//

import Foundation
import SwiftUI

struct AuthenticatedContentView: View {
    @EnvironmentObject var authenticationManager: AuthenticationManagerImpl
    @EnvironmentObject var appFactory: AppViewModelFactory

    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    var body: some View {
        NavigationView {
            getTabBarView()
                .navigationTitle("NHL Tracker")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showSettings.toggle()
                        }) {
                            Image(systemName: "gearshape.fill")
                                .imageScale(.large)
                        }
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView()
                        .environmentObject(authenticationManager)
                }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }

    func getTabBarView() -> some View {
        return TabView {
            Text("Add Game Tab Content")
                .tabItem {
                    Label("Add Game", systemImage: "plus.circle.fill")
                }
            Text("Games Tab Content")
                .tabItem {
                    Label("Games", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.blue)
    }
}
