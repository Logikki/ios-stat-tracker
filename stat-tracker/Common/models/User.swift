//
//  User.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

// Response usually contains this
public struct LightUser: Codable, Identifiable {
    public let id: String
    public let username: String
}

public struct User: Codable, Identifiable {
    public let id: String
    public let username: String
    public let name: String
    public let email: String
    public let profileVisibility: String
    public let matches: [Game]
    public let leagues: [League]
    public let friends: [LightUser]
    public let friendRequests: [LightUser]
}
