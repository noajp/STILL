//======================================================================
// MARK: - CryptoManager.swift
// Purpose: Encryption/Decryption manager for sensitive data
// Path: still/Core/Security/CryptoManager.swift
//======================================================================

import Foundation
import CryptoKit

class CryptoManager: @unchecked Sendable {
    static let shared = CryptoManager()
    
    private init() {}
    
    // ユーザーごとの暗号化キーを生成
    func generateUserKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    // キーをKeychain用のDataに変換
    func keyToData(_ key: SymmetricKey) -> Data {
        return key.withUnsafeBytes { Data($0) }
    }
    
    // DataからSymmetricKeyを復元
    func dataToKey(_ data: Data) -> SymmetricKey {
        return SymmetricKey(data: data)
    }
    
    // テキストを暗号化
    func encrypt(text: String, using key: SymmetricKey) throws -> Data {
        guard let data = text.data(using: .utf8) else {
            throw CryptoError.invalidInput
        }
        
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        // combined形式で返す（nonce + ciphertext + tag）
        guard let combined = sealedBox.combined else {
            throw CryptoError.encryptionFailed
        }
        
        return combined
    }
    
    // データを復号化
    func decrypt(data: Data, using key: SymmetricKey) throws -> String {
        print("🔐 CryptoManager.decrypt - Input data length: \(data.count)")
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            print("🔐 CryptoManager.decrypt - Successfully created SealedBox")
            
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            print("🔐 CryptoManager.decrypt - Successfully opened SealedBox, decrypted data length: \(decryptedData.count)")
            
            guard let text = String(data: decryptedData, encoding: .utf8) else {
                print("❌ CryptoManager.decrypt - Failed to convert decrypted data to UTF-8 string")
                throw CryptoError.decryptionFailed
            }
            
            print("🔐 CryptoManager.decrypt - Successfully converted to string: \(text)")
            return text
        } catch {
            print("❌ CryptoManager.decrypt - AES.GCM operation failed: \(error)")
            throw CryptoError.decryptionFailed
        }
    }
    
    // Base64エンコード（データベース保存用）
    func encryptToBase64(text: String, using key: SymmetricKey) throws -> String {
        let encryptedData = try encrypt(text: text, using: key)
        return encryptedData.base64EncodedString()
    }
    
    // Base64デコードして復号化
    func decryptFromBase64(base64String: String, using key: SymmetricKey) throws -> String {
        print("🔐 CryptoManager - Starting Base64 decryption")
        print("🔐 CryptoManager - Base64 string length: \(base64String.count)")
        print("🔐 CryptoManager - Base64 preview: \(String(base64String.prefix(50)))")
        
        guard let data = Data(base64Encoded: base64String) else {
            print("❌ CryptoManager - Invalid Base64 string")
            throw CryptoError.invalidBase64
        }
        
        print("🔐 CryptoManager - Successfully decoded Base64 to data, length: \(data.count)")
        
        do {
            let result = try decrypt(data: data, using: key)
            print("🔐 CryptoManager - Successfully decrypted data")
            return result
        } catch {
            print("❌ CryptoManager - Decryption failed: \(error)")
            throw error
        }
    }
}

// MARK: - P256 Key Management for E2EE

extension CryptoManager {
    
    /**
     * Generate a new P256 key pair for end-to-end encryption
     * Returns: A tuple containing the private key and public key (Base64 encoded)
     */
    func generateP256KeyPair() throws -> (privateKey: P256.KeyAgreement.PrivateKey, publicKeyBase64: String) {
        print("🔑 Generating new P256 key pair for E2EE")
        
        // Generate new private key
        let privateKey = P256.KeyAgreement.PrivateKey()
        
        // Get public key and encode as Base64
        let publicKeyData = privateKey.publicKey.x963Representation
        let publicKeyBase64 = publicKeyData.base64EncodedString()
        
        print("✅ Generated P256 key pair. Public key length: \(publicKeyBase64.count)")
        return (privateKey, publicKeyBase64)
    }
    
    /**
     * Serialize private key for secure storage
     */
    func serializePrivateKey(_ privateKey: P256.KeyAgreement.PrivateKey) throws -> Data {
        return privateKey.x963Representation
    }
    
    /**
     * Deserialize private key from stored data
     */
    func deserializePrivateKey(from data: Data) throws -> P256.KeyAgreement.PrivateKey {
        return try P256.KeyAgreement.PrivateKey(x963Representation: data)
    }
    
    /**
     * Deserialize public key from Base64 string
     */
    func deserializePublicKey(from base64String: String) throws -> P256.KeyAgreement.PublicKey {
        guard let data = Data(base64Encoded: base64String) else {
            throw CryptoError.invalidInput
        }
        return try P256.KeyAgreement.PublicKey(x963Representation: data)
    }
    
    /**
     * Derive shared symmetric key using ECDH
     * - Parameters:
     *   - privateKey: Your private key
     *   - publicKeyBase64: Other party's public key as Base64 string
     * - Returns: Shared symmetric key for AES encryption
     */
    func deriveSharedKey(privateKey: P256.KeyAgreement.PrivateKey, publicKeyBase64: String) throws -> SymmetricKey {
        print("🔐 Deriving shared key using ECDH")
        
        // Deserialize the public key
        let publicKey = try deserializePublicKey(from: publicKeyBase64)
        
        // Perform key agreement
        let sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
        
        // Derive symmetric key from shared secret using HKDF
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: "STILL-E2EE-v1".data(using: .utf8)!,
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        print("✅ Successfully derived shared symmetric key")
        return symmetricKey
    }
    
    /**
     * Encrypt message using hybrid encryption (ECDH + AES-GCM)
     * - Parameters:
     *   - message: Plain text message to encrypt
     *   - senderPrivateKey: Sender's private key
     *   - recipientPublicKeyBase64: Recipient's public key as Base64 string
     * - Returns: Encrypted message as Base64 string
     */
    func encryptMessage(_ message: String, senderPrivateKey: P256.KeyAgreement.PrivateKey, recipientPublicKeyBase64: String) throws -> String {
        print("🔒 Encrypting message with hybrid encryption")
        
        // Derive shared key
        let sharedKey = try deriveSharedKey(privateKey: senderPrivateKey, publicKeyBase64: recipientPublicKeyBase64)
        
        // Encrypt message with derived key
        let encryptedData = try encrypt(text: message, using: sharedKey)
        
        // Return as Base64
        let encryptedBase64 = encryptedData.base64EncodedString()
        print("✅ Message encrypted. Length: \(encryptedBase64.count)")
        return encryptedBase64
    }
    
    /**
     * Decrypt message using hybrid encryption (ECDH + AES-GCM)
     * - Parameters:
     *   - encryptedBase64: Encrypted message as Base64 string
     *   - recipientPrivateKey: Recipient's private key
     *   - senderPublicKeyBase64: Sender's public key as Base64 string
     * - Returns: Decrypted plain text message
     */
    func decryptMessage(_ encryptedBase64: String, recipientPrivateKey: P256.KeyAgreement.PrivateKey, senderPublicKeyBase64: String) throws -> String {
        print("🔓 Decrypting message with hybrid encryption")
        
        // Decode from Base64
        guard let encryptedData = Data(base64Encoded: encryptedBase64) else {
            throw CryptoError.invalidInput
        }
        
        // Derive shared key
        let sharedKey = try deriveSharedKey(privateKey: recipientPrivateKey, publicKeyBase64: senderPublicKeyBase64)
        
        // Decrypt message with derived key
        let decryptedMessage = try decrypt(data: encryptedData, using: sharedKey)
        
        print("✅ Message decrypted successfully")
        return decryptedMessage
    }
}
enum CryptoError: LocalizedError {
    case invalidInput
    case encryptionFailed
    case decryptionFailed
    case invalidBase64
    case keyNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Invalid input data"
        case .encryptionFailed:
            return "Encryption failed"
        case .decryptionFailed:
            return "Decryption failed"
        case .invalidBase64:
            return "Invalid Base64 string"
        case .keyNotFound:
            return "Encryption key not found"
        }
    }
}