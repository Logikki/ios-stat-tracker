//
//  User.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

import Foundation

public enum ProfileVisibility: String, Codable, CaseIterable, Identifiable, Hashable {
    case Public
    case Private
    case Friends

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .Public:  return "Public"
        case .Private: return "Private"
        case .Friends: return "Friends only"
        }
    }
}

public struct LightUser: Codable, Identifiable, Hashable {
    public let id: String
    public let username: String
    public let profileVisibility: ProfileVisibility?
}

public struct User: Codable, Identifiable, Hashable {
    public let id: String
    public let username: String
    public let name: String
    public let email: String
    public let profileVisibility: ProfileVisibility
    public let matches: [Game]
    public let leagues: [League]
    public let friends: [LightUser]
    public let friendRequests: [LightUser]
}
