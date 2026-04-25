//
//  PreviewSamples.swift
//  stat-tracker
//
//  Sample data used by SwiftUI #Preview blocks. DEBUG-only.
//

#if DEBUG
    import Foundation

    enum PreviewSamples {
        // MARK: - Users

        static let alice = LightUser(id: "u-alice", username: "alice", profileVisibility: .Public)
        static let bob = LightUser(id: "u-bob", username: "bob", profileVisibility: .Friends)
        static let carol = LightUser(id: "u-carol", username: "carol", profileVisibility: .Public)
        static let dave = LightUser(id: "u-dave", username: "dave", profileVisibility: .Private)

        // MARK: - Games

        static let nhlGameRecent = Game(
            id: "game-1",
            league: "league-1",
            gameType: GameType.NHL.rawValue,
            homeTeam: "Boston Bruins",
            awayTeam: "Toronto Maple Leafs",
            homeScore: 4,
            awayScore: 3,
            homePlayer: alice,
            awayPlayer: bob,
            overTime: true,
            penalties: false,
            createdAt: Date().addingTimeInterval(-3600 * 4),
            updatedAt: nil
        )

        static let nhlGameLoss = Game(
            id: "game-2",
            league: "league-1",
            gameType: GameType.NHL.rawValue,
            homeTeam: "Florida Panthers",
            awayTeam: "Boston Bruins",
            homeScore: 5,
            awayScore: 2,
            homePlayer: carol,
            awayPlayer: alice,
            overTime: false,
            penalties: false,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            updatedAt: nil
        )

        static let fifaGame = Game(
            id: "game-3",
            league: nil,
            gameType: GameType.FIFA.rawValue,
            homeTeam: "FC Barcelona",
            awayTeam: "Real Madrid",
            homeScore: 2,
            awayScore: 2,
            homePlayer: alice,
            awayPlayer: dave,
            overTime: false,
            penalties: true,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: nil
        )

        static let games: [Game] = [nhlGameRecent, nhlGameLoss, fifaGame]

        // MARK: - Leagues

        static let leagueWithMatches = League(
            id: "league-1",
            name: "Friday Night NHL",
            description: "Casual weekly NHL games with the squad.",
            gameTypes: [GameType.NHL.rawValue],
            users: [alice, bob, carol, dave],
            admins: [alice],
            matches: [nhlGameRecent, nhlGameLoss],
            duration: Date().addingTimeInterval(86400 * 60)
        )

        static let leagueEmpty = League(
            id: "league-2",
            name: "FIFA Office League",
            description: nil,
            gameTypes: [GameType.FIFA.rawValue],
            users: [alice, dave],
            admins: [alice],
            matches: [],
            duration: Date().addingTimeInterval(86400 * 30)
        )

        // MARK: - Profiles

        static let userWithEverything = User(
            id: "u-alice",
            username: "alice",
            name: "Alice Smith",
            email: "alice@example.com",
            profileVisibility: .Friends,
            matches: games,
            leagues: [leagueWithMatches, leagueEmpty],
            friends: [bob, carol],
            friendRequests: [dave]
        )

        static let userEmpty = User(
            id: "u-newbie",
            username: "newbie",
            name: "New Player",
            email: "new@example.com",
            profileVisibility: .Private,
            matches: [],
            leagues: [],
            friends: [],
            friendRequests: []
        )
    }
#endif
