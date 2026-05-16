//
//  ChatManager.swift
//  stat-tracker
//

import Foundation

final class ChatManagerImpl {

    // MARK: - REST

    func registerPublicKey(_ publicKey: String) async throws {
        let url = URL(string: Constants.API.URL + Constants.API.Chat.registerPublicKey)!
        let body = try JSONEncoder().encode(["publicKey": publicKey])
        let resource = Resource(url: url, method: .post(body), modelType: UserPublicKeyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
    }

    func getLeaguePublicKeys(leagueId: String) async throws -> [UserPublicKeyResponse] {
        let path = String(format: Constants.API.Chat.getLeaguePublicKeys, leagueId)
        let url = URL(string: Constants.API.URL + path)!
        let resource = Resource(url: url, method: .get([]), modelType: [UserPublicKeyResponse].self)
        return try await HTTPClient.shared.load(resource)
    }

    func getMessages(leagueId: String, before: String? = nil) async throws -> [ChatMessage] {
        let path = String(format: Constants.API.Chat.getMessages, leagueId)
        let url = URL(string: Constants.API.URL + path)!
        var queryItems: [URLQueryItem] = []
        if let before { queryItems.append(URLQueryItem(name: "before", value: before)) }
        let resource = Resource(url: url, method: .get(queryItems), modelType: [ChatMessage].self)
        return try await HTTPClient.shared.load(resource)
    }

    func sendMessage(leagueId: String, payload: SendMessagePayload) async throws -> ChatMessage {
        let path = String(format: Constants.API.Chat.sendMessage, leagueId)
        let url = URL(string: Constants.API.URL + path)!
        let encoder = JSONEncoder()
        let body = try encoder.encode(payload)
        let resource = Resource(url: url, method: .post(body), modelType: ChatMessage.self)
        return try await HTTPClient.shared.load(resource)
    }

    func deleteMessage(leagueId: String, messageId: String) async throws {
        let path = String(format: Constants.API.Chat.deleteMessage, leagueId, messageId)
        let url = URL(string: Constants.API.URL + path)!
        let resource = Resource(url: url, method: .delete, modelType: EmptyResponse.self)
        _ = try await HTTPClient.shared.load(resource)
    }

    // MARK: - WebSocket

    private var webSocketTask: URLSessionWebSocketTask?

    func connectWebSocket(
        leagueId: String,
        token: String,
        onMessage: @escaping @Sendable @MainActor (ChatMessage) -> Void
    ) {
        disconnectWebSocket()

        let baseWS = Constants.API.URL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")

        guard let url = URL(string: "\(baseWS)?token=\(token)&leagueId=\(leagueId)") else { return }

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveLoop(onMessage: onMessage)
    }

    func disconnectWebSocket() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    private func receiveLoop(onMessage: @escaping @Sendable @MainActor (ChatMessage) -> Void) {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            if case .success(let msg) = result,
               case .string(let text) = msg,
               let data = text.data(using: .utf8)
            {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .customISO8601
                if let envelope = try? decoder.decode(WSEnvelope.self, from: data),
                   envelope.type == "new_message"
                {
                    Task { @MainActor in onMessage(envelope.data) }
                }
            }
            if case .failure = result { return }
            self.receiveLoop(onMessage: onMessage)
        }
    }
}

private struct WSEnvelope: Decodable {
    let type: String
    let data: ChatMessage
}
