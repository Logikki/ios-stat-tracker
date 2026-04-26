//
//  StatTrackerApp.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

@main
struct Stat_trackerApp: App {
    private let dependencies = DependencyContainer.shared
    @StateObject private var appState: AppState

    init() {
        _appState = StateObject(wrappedValue: DependencyContainer.shared.appState)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.isLoadingInitialData {
                    LoadingScreen()
                } else if appState.showAuthView {
                    AuthView(viewModel: dependencies.getAuthViewModel())
                } else {
                    AuthenticatedContentView()
                }
            }
            .environmentObject(dependencies)
            .environmentObject(appState)
            .alert(
                "Error",
                isPresented: Binding<Bool>(
                    get: { appState.errorMessage != nil },
                    set: { newValue in
                        if !newValue {
                            appState.clearError()
                        }
                    }
                )
            ) {
                Button("OK") { appState.clearError() }
            } message: {
                Text(appState.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
}
