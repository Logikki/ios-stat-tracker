//
//  SettingsViewModel.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

import SwiftUI
import Foundation

class SettingsViewModel: ObservableObject {
    private let authenticationManager: AuthenticationManager
    @AppStorage("isDarkMode") var isDarkMode = false
    
    public init(authenticationManager: AuthenticationManagerImpl, isDarkMode: Bool = false) {
        self.authenticationManager = authenticationManager
    }
    
    func logout() {
        self.authenticationManager.clearAuthState()
    }
}
