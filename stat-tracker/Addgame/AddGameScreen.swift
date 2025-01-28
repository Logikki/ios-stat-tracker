//
//  addGameScreen.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUI

// MARK: - Screen (Container View)
struct AddGameScreen: View {
    @ObservedObject private var viewModel: AddGameViewModel
    
    init(viewModel: AddGameViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        AddGameView(viewModel: viewModel)
    }
}
