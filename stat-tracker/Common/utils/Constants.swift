//
//  Constants.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 4.6.2025.
//

import Foundation

public enum Constants {
    public enum API {
        public static let productionURL = "https://game-stats-tracker-api.fly.dev"
        public static let localSimulatorURL = "http://localhost:3000"

        private static let baseURLKey = "apiBaseURLOverride"

        /// Base URL the HTTP client talks to. Reads an optional override from UserDefaults.
        public static var URL: String {
            #if DEBUG
                return localSimulatorURL
            #else
                if let override = UserDefaults.standard.string(forKey: baseURLKey),
                   !override.isEmpty
                {
                    return override.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                }
            #endif
            // default
            return productionURL
        }

        /// Pass `nil` or empty string to clear and return to the default.
        public static func setBaseURL(_ url: String?) {
            if let url, !url.trimmingCharacters(in: .whitespaces).isEmpty {
                UserDefaults.standard.set(url, forKey: baseURLKey)
            } else {
                UserDefaults.standard.removeObject(forKey: baseURLKey)
            }
        }

        public enum Auth {
            public static let login = "/api/login"
        }

        public enum User {
            public static let createUser = "/api/user"
            public static let updateUserVisibility = "/api/user/visibility"
            public static let getOwnUser = "/api/user/own"
            public static let getUser = "/api/user/%@"
            public static let getUsers = "/api/users"
            public static let getAvatar = "/api/user/%@/avatar"
            public static let uploadAvatar = "/api/user/avatar"
            public static let deleteAvatar = "/api/user/avatar"
        }

        public enum FriendRequest {
            public static let sendFriendRequest = "/api/user/friend-request/%@"
            public static let acceptFriendRequest = "/api/user/friend-request/accept/%@"
            public static let rejectFriendRequest = "/api/user/friend-request/reject/%@"
            public static let removeFriend = "/api/user/friend/%@"
        }

        public enum League {
            public static let createLeague = "/api/league"
            public static let putUserToLeague = "/api/league/user/%@"
            public static let deleteLeague = "/api/league/delete/%@"
            public static let createLeagueInvitation = "/api/league/invite/%@"
            public static let acceptLeagueInvitation = "/api/league/join/%@"
        }

        public enum Game {
            public static let createGame = "/api/game"
            public static let deleteGame = "/api/game/remove/%@"
            public static let getGames = "/api/game"
        }
    }

    public enum UserDefaultsKeys {
        public static let authToken = "authToken"
        public static let currentUsername = "username"
        public static let currentName = "name"
    }
}
