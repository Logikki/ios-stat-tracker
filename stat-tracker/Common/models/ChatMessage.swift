//
//  ChatMessage.swift
//  stat-tracker
//

import Foundation

struct EncryptedKey: Codable {
    let recipient: String
    let encryptedMEK: String
    let ephemeralPublicKey: String
}

struct ChatMessage: Identifiable, Codable {
    let id: String
    let league: String
    let sender: LightUser
    let ciphertext: String
    let nonce: String
    let encryptedKeys: [EncryptedKey]
    let imageMimeType: String?
    let imageNonce: String?
    let encryptedImageKeys: [EncryptedKey]?
    let createdAt: Date
}

struct UserPublicKeyResponse: Codable, Identifiable {
    let id: String
    let user: String      // user's ObjectId
    let publicKey: String // base64 raw X25519 public key (32 bytes)
    let algorithm: String
}

struct SendMessagePayload: Encodable {
    let ciphertext: String
    let nonce: String
    let encryptedKeys: [EncryptedKey]
}
