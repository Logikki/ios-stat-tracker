//
//  AuthenticationManager.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 17.5.2025.
//

import Foundation
import SwiftUI
import os.log

protocol AuthenticationManager {
    func setAuthState(response: AuthResponse)
    func clearAuthState()
    func loadAuthState()
    var isAuthenticated: Bool { get }
}

class AuthenticationManagerImpl: AuthenticationManager, ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var authToken: String? = nil
    @Published var currentUser: AuthResponse? = nil

    init() {
        loadAuthState()
        AppLogger.info("AuthenticationManager initialized.", category: "Authentication")
    }

    func setAuthState(response: AuthResponse) {
        self.authToken = response.token
        self.currentUser = response
        UserDefaults.standard.set(response.token, forKey: Constants.UserDefaultsKeys.authToken)
        UserDefaults.standard.set(response.username, forKey: Constants.UserDefaultsKeys.currentUsername)
        UserDefaults.standard.set(response.name, forKey: Constants.UserDefaultsKeys.currentName)
        self.isAuthenticated = true
        AppLogger.info("Auth state set: User '\(response.username)' logged in.", category: "Authentication")
    }

    func clearAuthState() {
        self.authToken = nil
        self.currentUser = nil
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.authToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentUsername)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.currentName)
        self.isAuthenticated = false
        AppLogger.info("Auth state cleared: User logged out.", category: "Authentication")
    }

    func loadAuthState() {
        if let token = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.authToken),
           let username = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentUsername),
           let name = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentName) {
            
            self.authToken = token
            self.currentUser = AuthResponse(token: token, username: username, name: name)
            self.isAuthenticated = true
            AppLogger.info("Loaded existing auth state from UserDefaults.", category: "Authentication")
        } else {
            self.isAuthenticated = false
            self.authToken = nil
            self.currentUser = nil
            AppLogger.info("No existing auth state found in UserDefaults.", category: "Authentication")
        }
    }
}
