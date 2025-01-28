//
//  StatsScreen.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUICore

struct StatsScreen: View {
    @ObservedObject private var viewModel: StatsViewModel
    
    init(viewModel: StatsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        StatsView(viewModel: viewModel)
    }
}
