//
//  SettingsViewModel.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

import SwiftUI
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false

    @Published var backendURLDraft: String
    @Published private(set) var activeBackendURL: String

    private let authenticationManager: AuthenticationManagerImpl

    public init(authenticationManager: AuthenticationManagerImpl) {
        self.authenticationManager = authenticationManager
        let active = Constants.API.URL
        self.activeBackendURL = active
        self.backendURLDraft = active
    }

    var isUsingProduction: Bool { activeBackendURL == Constants.API.productionURL }
    var isUsingLocal: Bool { activeBackendURL == Constants.API.localSimulatorURL }
    var isCustom: Bool { !isUsingProduction && !isUsingLocal }

    func useProduction() { applyURL(Constants.API.productionURL) }
    func useLocal() { applyURL(Constants.API.localSimulatorURL) }
    func applyDraft() { applyURL(backendURLDraft) }
    func resetToDefault() { applyURL(Constants.API.productionURL) }

    private func applyURL(_ url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        Constants.API.setBaseURL(trimmed == Constants.API.productionURL ? nil : trimmed)
        activeBackendURL = Constants.API.URL
        backendURLDraft = activeBackendURL
        // Tokens issued by one backend won't be valid for another – sign the user out so we
        // don't end up with a half-authenticated state.
        authenticationManager.clearAuthState()
    }

    func logout() {
        authenticationManager.clearAuthState()
    }
}
