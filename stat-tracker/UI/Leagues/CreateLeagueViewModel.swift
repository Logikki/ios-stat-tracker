//
//  CreateLeagueViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Foundation

@MainActor
final class CreateLeagueViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = ""
    @Published var gameTypes: Set<GameType> = [.NHL]
    @Published var duration: Date = Calendar.current.date(byAdding: .month, value: 3, to: .now) ?? .now
    @Published var extraUsernames: String = ""

    @Published private(set) var isSubmitting: Bool = false
    @Published var errorMessage: String?

    private let leagueManager: LeagueManagerImpl
    private let userManager: UserManagerImpl

    init(leagueManager: LeagueManagerImpl, userManager: UserManagerImpl) {
        self.leagueManager = leagueManager
        self.userManager = userManager
    }

    var canSubmit: Bool {
        !isSubmitting &&
            !name.trimmingCharacters(in: .whitespaces).isEmpty &&
            !gameTypes.isEmpty &&
            userManager.currentUserProfile != nil
    }

    func toggle(_ type: GameType) {
        if gameTypes.contains(type) { gameTypes.remove(type) } else { gameTypes.insert(type) }
    }

    #if DEBUG
        static func preview() -> CreateLeagueViewModel {
            let user = UserManagerImpl.preview(profile: PreviewSamples.userWithEverything)
            return CreateLeagueViewModel(leagueManager: LeagueManagerImpl(), userManager: user)
        }
    #endif

    func submit(onSuccess: @escaping () -> Void) {
        guard canSubmit, let me = userManager.currentUserProfile?.username else { return }
        isSubmitting = true
        errorMessage = nil

        let extras = extraUsernames
            .split(whereSeparator: { ", \n".contains($0) })
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var users = Array(Set(extras + [me]))
        if !users.contains(me) { users.append(me) }

        let payload = CreateLeaguePayload(
            name: name,
            description: description.isEmpty ? nil : description,
            gameTypes: Array(gameTypes),
            users: users,
            admins: [me],
            duration: duration
        )

        Task {
            defer { self.isSubmitting = false }
            do {
                _ = try await leagueManager.createLeague(payload)
                await userManager.fetchOwnUser()
                onSuccess()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
