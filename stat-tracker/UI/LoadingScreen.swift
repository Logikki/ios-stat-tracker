//
//  SplashScreenView.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 14.6.2025.
//

import SwiftUI

struct LoadingScreen: View {
    var body: some View {
        VStack {
            Image(systemName: "hourglass")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
            Text("Loading Your Stats...")
                .font(.title2)
            ProgressView()
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.edgesIgnoringSafeArea(.all))
        .foregroundColor(.white)
    }
}
