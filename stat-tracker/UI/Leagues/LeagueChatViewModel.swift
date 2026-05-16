//
//  LeagueChatViewModel.swift
//  stat-tracker
//

import Foundation

struct DecryptedChatMessage: Identifiable {
    let message: ChatMessage
    let plaintext: String?
    var id: String { message.id }
}

@MainActor
final class LeagueChatViewModel: ObservableObject {
    @Published private(set) var decryptedMessages: [DecryptedChatMessage] = []
    @Published var inputText: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var isSending = false
    @Published var errorMessage: String?

    private let leagueId: String
    private let chatManager: ChatManagerImpl
    private let authManager: AuthenticationManagerImpl
    private let userManager: UserManagerImpl
    private let e2ee: E2EEManager

    private var keyRegistered = false

    init(
        leagueId: String,
        chatManager: ChatManagerImpl,
        authManager: AuthenticationManagerImpl,
        userManager: UserManagerImpl,
        e2ee: E2EEManager = .shared
    ) {
        self.leagueId = leagueId
        self.chatManager = chatManager
        self.authManager = authManager
        self.userManager = userManager
        self.e2ee = e2ee
    }

    deinit {
        chatManager.disconnectWebSocket()
    }

    func load() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await ensureKeyRegistered()
                let msgs = try await chatManager.getMessages(leagueId: leagueId)
                let myId = userManager.currentUserProfile?.id ?? ""
                decryptedMessages = msgs
                    .map { DecryptedChatMessage(message: $0, plaintext: e2ee.decrypt(message: $0, myUserId: myId)) }
                    .sorted { $0.message.createdAt < $1.message.createdAt }
                connectWebSocket()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func send() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        Task {
            defer { isSending = false }
            do {
                try await ensureKeyRegistered()
                let recipients = try await chatManager.getLeaguePublicKeys(leagueId: leagueId)
                let encrypted = try e2ee.encrypt(plaintext: text, recipients: recipients)
                let payload = SendMessagePayload(
                    ciphertext: encrypted.ciphertext,
                    nonce: encrypted.nonce,
                    encryptedKeys: encrypted.encryptedKeys
                )
                let sent = try await chatManager.sendMessage(leagueId: leagueId, payload: payload)
                let myId = userManager.currentUserProfile?.id ?? ""
                let decrypted = DecryptedChatMessage(
                    message: sent,
                    plaintext: e2ee.decrypt(message: sent, myUserId: myId)
                )
                // TODO: Optimize
//                decryptedMessages.append(decrypted)
                inputText = ""
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func delete(_ msg: DecryptedChatMessage) {
        Task {
            do {
                try await chatManager.deleteMessage(leagueId: leagueId, messageId: msg.id)
                decryptedMessages.removeAll { $0.id == msg.id }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Private

    private func ensureKeyRegistered() async throws {
        guard !keyRegistered else { return }
        try await chatManager.registerPublicKey(e2ee.publicKeyBase64)
        keyRegistered = true
    }

    private func connectWebSocket() {
        guard let token = authManager.authToken else { return }
        chatManager.connectWebSocket(leagueId: leagueId, token: token) { [weak self] msg in
            guard let self else { return }
            guard !self.decryptedMessages.contains(where: { $0.id == msg.id }) else { return }
            let myId = self.userManager.currentUserProfile?.id ?? ""
            let decrypted = DecryptedChatMessage(
                message: msg,
                plaintext: self.e2ee.decrypt(message: msg, myUserId: myId)
            )
            self.decryptedMessages.append(decrypted)
        }
    }
}
