//
//  League.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//
import Foundation

public struct League: Codable, Identifiable {
    public let id: String
    public let name: String
    public let description: String?
    public let gameTypes: [String]
    public let users: [LightUser]
    public let admins: [LightUser] // fix
    public let matches: [Game]
    public let duration: Date
}
