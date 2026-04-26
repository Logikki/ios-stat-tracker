//
//  OtherProfileViewModel.swift
//  stat-tracker
//

import Foundation

@MainActor
final class OtherProfileViewModel: ObservableObject {
    let username: String
    @Published private(set) var profile: OtherUserProfile?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let userManager: UserManagerImpl

    init(username: String, userManager: UserManagerImpl) {
        self.username = username
        self.userManager = userManager
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await userManager.fetchUser(username: username)
        } catch {
            errorMessage = error.localizedDescription
            AppLogger.error("fetchUser \(username) failed: \(error.localizedDescription)", category: "UserManagement")
        }
    }

    var stats: PlayerStats {
        guard let matches = profile?.matches else { return .empty }
        return PlayerStats(matches: matches, username: username)
    }

    func sendFriendRequest() {
        Task {
            do {
                try await userManager.sendFriendRequest(to: username)
                await load()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    #if DEBUG
        init(username: String, userManager: UserManagerImpl, previewProfile: OtherUserProfile?) {
            self.username = username
            self.userManager = userManager
            self.profile = previewProfile
        }

        static func previewFull() -> OtherProfileViewModel {
            OtherProfileViewModel(
                username: "alice",
                userManager: UserManagerImpl.preview(profile: nil),
                previewProfile: OtherUserProfile(
                    visible: true,
                    username: "alice",
                    id: "u-alice",
                    name: "Alice Smith",
                    profileVisibility: .Public,
                    matches: PreviewSamples.games,
                    leagues: [PreviewSamples.leagueWithMatches],
                    friends: [PreviewSamples.bob, PreviewSamples.carol],
                    avatarBase64: "",
                    reason: nil
                )
            )
        }

        static func previewPrivate() -> OtherProfileViewModel {
            OtherProfileViewModel(
                username: "dave",
                userManager: UserManagerImpl.preview(profile: nil),
                previewProfile: OtherUserProfile(
                    visible: false, username: "dave",
                    id: nil, name: nil, profileVisibility: nil,
                    matches: nil, leagues: nil, friends: nil,
                    avatarBase64: "",
                    reason: .private
                )
            )
        }

        static func previewNotFriends() -> OtherProfileViewModel {
            OtherProfileViewModel(
                username: "bob",
                userManager: UserManagerImpl.preview(profile: nil),
                previewProfile: OtherUserProfile(
                    visible: false, username: "bob",
                    id: nil, name: nil, profileVisibility: nil,
                    matches: nil, leagues: nil, friends: nil,
                    avatarBase64: "",
                    reason: .notFriends
                )
            )
        }
    #endif
}
