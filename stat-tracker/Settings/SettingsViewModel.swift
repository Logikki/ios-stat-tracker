//
//  SettingsViewModel.swift
//  stat-tracker
//
//  Created by Rkos on 29.1.2025.
//

import SwiftUI
import Foundation

class SettingsViewModel: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false  // Persist dark mode setting
}
