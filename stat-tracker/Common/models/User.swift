//
//  User.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 3.4.2025.
//

struct User {
    let username: String
    let name: String
    let email: String
    let profileVisibility: String
    let matches: [Game]
    let friends: [String]
    let friendRequests: [String]

    init?(json: [String: Any]) {
        guard let username = json["username"] as? String,
              let name = json["name"] as? String,
              let email = json["email"] as? String,
              let profileVisibility = json["profileVisibility"] as? String else {
            return nil
        }

        self.username = username
        self.name = name
        self.email = email
        self.profileVisibility = profileVisibility

        // Convert matches JSON array to Game objects
        if let matchesArray = json["matches"] as? [[String: Any]] {
            self.matches = matchesArray.compactMap { Game(json: $0) }
        } else {
            self.matches = []
        }

        self.friends = json["friends"] as? [String] ?? []
        self.friendRequests = json["friendRequests"] as? [String] ?? []
    }
}
