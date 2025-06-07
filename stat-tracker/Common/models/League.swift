//
//  League.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//
import Foundation

struct League {
    let name: String
    let description: String?
    let gameTypes: [String]
    let users: [User]
    let admins: [User]
    let matches: [Game]
    let duration: Date

    init?(json: [String: Any]) {
        guard let name = json["name"] as? String,
              let gameTypes = json["gameTypes"] as? [String],
              let durationString = json["duration"] as? String,
              let duration = ISO8601DateFormatter().date(from: durationString) else {
            return nil
        }

        self.name = name
        self.description = json["description"] as? String
        self.gameTypes = gameTypes

        if let usersArray = json["users"] as? [[String: Any]] {
            self.users = usersArray.compactMap { User(json: $0) }
        } else {
            self.users = []
        }

        if let adminsArray = json["admins"] as? [[String: Any]] {
            self.admins = adminsArray.compactMap { User(json: $0) }
        } else {
            self.admins = []
        }

        if let matchesArray = json["matches"] as? [[String: Any]] {
            self.matches = matchesArray.compactMap { Game(json: $0) }
        } else {
            self.matches = []
        }

        self.duration = duration
    }
}
