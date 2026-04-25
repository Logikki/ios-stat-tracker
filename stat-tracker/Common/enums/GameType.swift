//
//  GameType.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

public enum GameType: String, Codable, CaseIterable, Identifiable, Hashable {
    case NHL
    case FIFA

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .NHL: return "NHL"
        case .FIFA: return "FIFA"
        }
    }

    public var systemImage: String {
        switch self {
        case .NHL: return "hockey.puck.fill"
        case .FIFA: return "soccerball"
        }
    }
}
