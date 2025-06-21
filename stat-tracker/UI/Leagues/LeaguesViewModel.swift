//
//  LeaguesViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 19.6.2025.
//

import Foundation
import Combine

// MARK: - AuthViewModel

class LeaguesViewModel: ObservableObject {
    var league: [League]
    
    init(league: [League]) {
        self.league = league
    }
}
