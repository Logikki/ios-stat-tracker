//
//  E2EEManager.swift
//  stat-tracker
//
//  X25519 ECDH + AES-256-GCM end-to-end encryption.
//  Private key is persisted in UserDefaults (move to Keychain for production hardening).
//

import CryptoKit
import Foundation

final class E2EEManager {
    static let shared = E2EEManager()
    private init() {}
    
    private let storageKey = "e2ee_x25519_private_key"
    private var cachedPrivateKey: Curve25519.KeyAgreement.PrivateKey?
    
    func getOrCreatePrivateKey() -> Curve25519.KeyAgreement.PrivateKey {
        if let key = cachedPrivateKey { return key }
        
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let key = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data) {
            cachedPrivateKey = key
            return key
        }
        let key = Curve25519.KeyAgreement.PrivateKey()
        
        UserDefaults.standard.set(Data(key.rawRepresentation), forKey: storageKey)
        cachedPrivateKey = key
        return key
    }
    
    var publicKeyBase64: String {
        Data(getOrCreatePrivateKey().publicKey.rawRepresentation).base64EncodedString()
    }
    
    // MARK: - Encrypt
}

extension E2EEManager {
    struct EncryptResult {
        let ciphertext: String  // base64(ciphertextBytes + 16-byte GCM tag)
        let nonce: String       // base64(12-byte GCM nonce)
        let encryptedKeys: [EncryptedKey]
    }

    func encrypt(plaintext: String, recipients: [UserPublicKeyResponse]) throws -> EncryptResult {
        guard let plaintextData = plaintext.data(using: .utf8) else {
            throw E2EEError.encodingFailed
        }

        let mek = SymmetricKey(size: .bits256)
        let sealed = try AES.GCM.seal(plaintextData, using: mek)

        let mekData = mek.withUnsafeBytes { Data($0) }
        var encryptedKeys: [EncryptedKey] = []

        for recipient in recipients {
            guard
                let pubKeyData = Data(base64Encoded: recipient.publicKey),
                let recipientPubKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: pubKeyData)
            else { continue }

            let ephemeralPrivate = Curve25519.KeyAgreement.PrivateKey()
            guard let sharedSecret = try? ephemeralPrivate.sharedSecretFromKeyAgreement(with: recipientPubKey) else { continue }

            let wrappingKey = sharedSecret.hkdfDerivedSymmetricKey(
                using: SHA256.self,
                salt: Data(),
                sharedInfo: Data("chat-mek".utf8),
                outputByteCount: 32
            )

            guard
                let wrappedBox = try? AES.GCM.seal(mekData, using: wrappingKey),
                let combined = wrappedBox.combined
            else { continue }

            encryptedKeys.append(EncryptedKey(
                recipient: recipient.user,
                encryptedMEK: combined.base64EncodedString(),
                ephemeralPublicKey: Data(ephemeralPrivate.publicKey.rawRepresentation).base64EncodedString()
            ))
        }

        let ciphertextWithTag = sealed.ciphertext + sealed.tag
        return EncryptResult(
            ciphertext: ciphertextWithTag.base64EncodedString(),
            nonce: Data(sealed.nonce).base64EncodedString(),
            encryptedKeys: encryptedKeys
        )
    }

    // MARK: - Decrypt

    func decrypt(message: ChatMessage, myUserId: String) -> String? {
        guard
            let myEntry = message.encryptedKeys.first(where: { $0.recipient == myUserId }),
            let encryptedMEKData = Data(base64Encoded: myEntry.encryptedMEK),
            let ephemeralPubKeyData = Data(base64Encoded: myEntry.ephemeralPublicKey),
            let ephemeralPubKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: ephemeralPubKeyData)
        else { return nil }

        guard let sharedSecret = try? getOrCreatePrivateKey().sharedSecretFromKeyAgreement(with: ephemeralPubKey) else { return nil }

        let wrappingKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("chat-mek".utf8),
            outputByteCount: 32
        )

        guard
            let wrappedBox = try? AES.GCM.SealedBox(combined: encryptedMEKData),
            let mekData = try? AES.GCM.open(wrappedBox, using: wrappingKey)
        else { return nil }

        let mek = SymmetricKey(data: mekData)

        guard
            let nonceData = Data(base64Encoded: message.nonce),
            let ciphertextWithTag = Data(base64Encoded: message.ciphertext),
            ciphertextWithTag.count >= 17,
            let nonce = try? AES.GCM.Nonce(data: nonceData)
        else { return nil }

        let ciphertext = ciphertextWithTag.dropLast(16)
        let tag = ciphertextWithTag.suffix(16)

        guard
            let sealedBox = try? AES.GCM.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag),
            let plaintextData = try? AES.GCM.open(sealedBox, using: mek)
        else { return nil }

        return String(data: plaintextData, encoding: .utf8)
    }
}

enum E2EEError: Error {
    case encodingFailed
    case encryptionFailed
}
