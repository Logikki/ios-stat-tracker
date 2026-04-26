//
//  DependencyInjection_Examples.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//
//  EXAMPLES: How to use the DependencyContainer in your views
//

import SwiftUI

// MARK: - Example 1: Simple View with Dependencies

struct ExampleGamesView: View {
    @EnvironmentObject var dependencies: DependencyContainer
    @StateObject private var viewModel: GamesViewModel

    init() {
        // Get the cached ViewModel from dependencies
        // This will be called when the view is created
        _viewModel = StateObject(wrappedValue: DependencyContainer.shared.getGamesViewModel())
    }

    var body: some View {
        List {
            ForEach(viewModel.games) { game in
                Text(game.id)
            }
        }
        .navigationTitle("Games")
    }
}

// MARK: - Example 2: View with Direct Dependency Access

struct ExampleSettingsView: View {
    @EnvironmentObject var dependencies: DependencyContainer

    var body: some View {
        List {
            Section {
                // Access managers directly when you don't need a ViewModel
                if let username = dependencies.userManager.currentUserProfile?.username {
                    Text("Logged in as @\(username)")
                }
            }

            Section {
                Button("Logout") {
                    dependencies.authenticationManager.clearAuthState()
                    dependencies.resetViewModels()
                }
            }
        }
        .navigationTitle("Settings")
    }
}

// MARK: - Example 3: View with Transient ViewModel (creates new each time)

struct ExampleAddGameSheet: View {
    @EnvironmentObject var dependencies: DependencyContainer
    @StateObject private var viewModel: AddGameViewModel

    let league: League?

    init(league: League? = nil) {
        self.league = league

        // Create a new ViewModel each time this sheet appears
        if let league = league {
            _viewModel = StateObject(wrappedValue: DependencyContainer.shared.createAddGameViewModel(forLeague: league))
        } else {
            _viewModel = StateObject(wrappedValue: DependencyContainer.shared.createAddGameViewModel())
        }
    }

    var body: some View {
        Form {
            // Your add game form here
        }
        .navigationTitle("Add Game")
    }
}

// MARK: - Example 4: Accessing Dependencies in Previews

#if DEBUG
    struct ExampleGamesView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationStack {
                ExampleGamesView()
                    .environmentObject(DependencyContainer.shared)
            }
        }
    }
#endif

// MARK: - Alternative Pattern: Property Wrapper for Dependencies

/// You can also create a property wrapper to make access even cleaner
@propertyWrapper
struct Injected<T> {
    private let keyPath: KeyPath<DependencyContainer, T>

    var wrappedValue: T {
        DependencyContainer.shared[keyPath: keyPath]
    }

    init(_ keyPath: KeyPath<DependencyContainer, T>) {
        self.keyPath = keyPath
    }
}

/// Usage example:
struct ExampleWithPropertyWrapper: View {
    @Injected(\.userManager) var userManager
    @Injected(\.gameManager) var gameManager

    var body: some View {
        VStack {
            if let user = userManager.currentUserProfile {
                Text("Hello, \(user.name)")
            }
        }
    }
}
