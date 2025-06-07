//
//  Constants.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 4.6.2025.
//

import Foundation

public struct Constants {    
    public struct API {
        public static let URL = "https://game-stats-tracker.fly.dev"

        public struct Auth {
            public static let login = "/api/login"
        }

        public struct User {
            public static let createUser = "/api/user"
            public static let updateUserVisibility = "/api/user/visibility"
            public static let getOwnUser = "/api/user/own"
            public static let getUser = "/api/user/%@"
            public static let getUsers = "/api/users"
        }

        public struct FriendRequest {
            public static let sendFriendRequest = "/api/user/friend-request/%@"
            public static let acceptFriendRequest = "/api/user/friend-request/accept/%@"
            public static let rejectFriendRequest = "/api/user/friend-request/reject/%@"
            public static let removeFriend = "/api/user/friend/%@"
        }

        public struct League {
            public static let createLeague = "/api/league"
            public static let putUserToLeague = "/api/league/user/%@"
            public static let deleteLeague = "/api/league/delete/%@"
            public static let createLeagueInvitation = "/api/league/invite/%@"
            public static let acceptLeagueInvitation = "/api/league/join/%@"
        }

        public struct Game {
            public static let createGame = "/api/game"
            public static let deleteGame = "/api/game/remove/%@"
            public static let getGames = "/api/game"
        }
    }
    
    public struct UserDefaultsKeys {
        public static let authToken = "authToken"
        public static let currentUsername = "username"
        public static let currentName = "name"
    }
}
