//
//  StatsView.swift
//  stat-tracker
//
//  Created by Rkos on 28.1.2025.
//

import SwiftUICore
import SwiftUI
import Charts

struct StatsView: View {
    @ObservedObject private var viewModel: StatsViewModel
    
//    let roniStats = [
//        PlayerStats(category: "Wins", value: 4, color: .green),
//        PlayerStats(category: "Losses", value: 2, color: .red)
//    ]
//    
//    let tatuStats = [
//        PlayerStats(category: "Wins", value: 2, color: .blue),
//        PlayerStats(category: "Losses", value: 4, color: .orange)
//    ]

    let stats = [
        PlayerStats(player: "Roni", category: "Wins", value: 8, color: .blue),
        PlayerStats(player: "Tatu", category: "Wins", value: 6, color: .blue),
        PlayerStats(player: "Roni", category: "Losses", value: 6, color: .orange),
        PlayerStats(player: "Tatu", category: "Losses", value: 8, color: .orange)
    ]

    var body: some View {
        VStack {
            Text("Wins & Losses Bar Chart")
                .font(.title)
                .bold()
            
            Chart(stats) { stat in
                BarMark(
                    x: .value("Player", stat.player),
                    y: .value("Games", stat.value)
                )
                .foregroundStyle(stat.color)
            }
            .frame(height: 300)
            .padding()
        }
        .padding()
    }
    
    init(viewModel: StatsViewModel) {
        self.viewModel = viewModel
    }
}

struct PlayerStats: Identifiable {
    let id = UUID()
    let player: String
    let category: String
    let value: Int
    let color: Color
}
