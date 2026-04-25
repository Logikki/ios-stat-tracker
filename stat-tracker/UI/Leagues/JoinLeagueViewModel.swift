//
//  JoinLeagueViewModel.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 25.4.2026.
//

import Foundation

@MainActor
final class JoinLeagueViewModel: ObservableObject {
    @Published var code: String = ""
    @Published private(set) var isSubmitting: Bool = false
    @Published var errorMessage: String?

    private let leagueManager: LeagueManagerImpl
    private let userManager: UserManagerImpl

    init(leagueManager: LeagueManagerImpl, userManager: UserManagerImpl) {
        self.leagueManager = leagueManager
        self.userManager = userManager
    }

    var canSubmit: Bool {
        !isSubmitting && !code.trimmingCharacters(in: .whitespaces).isEmpty
    }

    #if DEBUG
        static func preview() -> JoinLeagueViewModel {
            let user = UserManagerImpl.preview(profile: PreviewSamples.userEmpty)
            return JoinLeagueViewModel(leagueManager: LeagueManagerImpl(), userManager: user)
        }
    #endif

    func submit(onSuccess: @escaping () -> Void) {
        guard canSubmit else { return }
        isSubmitting = true
        errorMessage = nil

        let trimmed = code.trimmingCharacters(in: .whitespaces)

        Task {
            defer { self.isSubmitting = false }
            do {
                _ = try await leagueManager.acceptInvitation(code: trimmed)
                await userManager.fetchOwnUser()
                onSuccess()
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
