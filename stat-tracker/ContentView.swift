//
//  ContentView.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authenticationManager: AuthenticationManagerImpl
    @EnvironmentObject var factory: AppViewModelFactory

    @State private var showAddGame = false
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        VStack {
            if authenticationManager.isAuthenticated {
                authenticatedContentView()
            } else {
                AuthView(viewModel: factory.createAuthViewModel())
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
    
    func authenticatedContentView() -> some View {
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
                }
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthManager = AuthenticationManagerImpl() 
        let mockFactory = AppViewModelFactory(authManager: mockAuthManager)

        ContentView()
            .environmentObject(mockAuthManager)
            .environmentObject(mockFactory)
    }
}
