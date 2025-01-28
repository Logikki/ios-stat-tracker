//
//  ContentView.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI
import CoreData

import SwiftUI
import CoreData

struct ContentView: View {
    private let factory: ViewModelFactory
    @State private var showAddGame = false
    @State private var showSettings = false
    @AppStorage("isDarkMode") private var isDarkMode = true

    init(factory: ViewModelFactory) {
        self.factory = factory
    }
    
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
                    SettingsView() // Open SettingsView in a sheet
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

extension ContentView {
    func getTabBarView() -> some View {
        return TabView {
            AddGameScreen(viewModel: factory.createAddGameViewModel())
                .tabItem {
                    Label("Add Game", systemImage: "plus.circle.fill")
                }
            StatsScreen(viewModel: factory.createStatsViewModel())
                .tabItem {
                    Label("Games", systemImage: "chart.bar.fill")
                }
        }
        .accentColor(.blue)
    }
}

//#Preview {
//    let mockFactory = MockViewModelFactory()
//    ContentView(factory: mockFactory)
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
