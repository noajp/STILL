//======================================================================
// MARK: - MessageEncryptionService.swift
// Purpose: Dedicated service for message encryption and decryption operations
// Path: still/Core/Services/MessageEncryptionService.swift
//======================================================================

import Foundation
import Security
import CryptoKit

/// Handles all message encryption and decryption operations
/// Manages user encryption keys and provides secure message processing
class MessageEncryptionService {
    
    // MARK: - Public Methods
    
    /// Encrypt message content for storage
    func encryptMessage(_ content: String) throws -> String {
        let keyData = try getUserOrGenerateKey()
        let key = CryptoManager.shared.dataToKey(keyData)
        return try CryptoManager.shared.encryptToBase64(text: content, using: key)
    }
    
    /// Decrypt message content for display
    func decryptMessage(_ encryptedContent: String) throws -> String {
        let keyData = try KeychainManager.shared.getUserKey()
        let key = CryptoManager.shared.dataToKey(keyData)
        return try CryptoManager.shared.decryptFromBase64(base64String: encryptedContent, using: key)
    }
    
    /// Decrypt message content and create preview text
    func decryptMessagePreview(_ encryptedContent: String) throws -> String {
        let decryptedContent = try decryptMessage(encryptedContent)
        return decryptedContent.count > 50 ? String(decryptedContent.prefix(50)) + "..." : decryptedContent
    }
    
    /// Check if user has encryption key available
    func hasUserKey() -> Bool {
        do {
            _ = try KeychainManager.shared.getUserKey()
            return true
        } catch {
            return false
        }
    }
    
    /// Generate new encryption key for user
    func generateNewUserKey() throws -> Data {
        let newKey = CryptoManager.shared.generateUserKey()
        let keyData = CryptoManager.shared.keyToData(newKey)
        try KeychainManager.shared.saveUserKey(keyData)
        return keyData
    }
    
    /// Safely decrypt message with fallback handling
    func safeDecryptMessage(_ encryptedContent: String) -> String {
        do {
            return try decryptMessage(encryptedContent)
        } catch {
            print("❌ Failed to decrypt message: \(error)")
            return "Unable to decrypt message"
        }
    }
    
    /// Safely decrypt message preview with fallback handling
    func safeDecryptMessagePreview(_ encryptedContent: String) -> String {
        do {
            return try decryptMessagePreview(encryptedContent)
        } catch {
            print("❌ Failed to decrypt message preview: \(error)")
            return "Message"
        }
    }
    
    // MARK: - Private Methods
    
    /// Get existing user key or generate new one if not found
    private func getUserOrGenerateKey() throws -> Data {
        do {
            return try KeychainManager.shared.getUserKey()
        } catch KeychainError.keyNotFound {
            // Generate new key for first-time users
            return try generateNewUserKey()
        } catch {
            throw error
        }
    }
}

// MARK: - E2EE Message Encryption Service

/**
 * End-to-End Encrypted Message Service using P256 ECDH + AES-GCM hybrid encryption
 * This provides true E2EE where only conversation participants can decrypt messages
 */
@MainActor
class E2EEMessageEncryptionService {
    
    private let cryptoManager = CryptoManager.shared
    private let keychainManager = KeychainManager.shared
    
    // MARK: - Key Management
    
    /**
     * Initialize E2EE for user (generate key pair if needed)
     */
    func initializeE2EE() async throws -> String {
        print("🔐 Initializing E2EE for user")
        
        // Check if user already has a key pair
        if keychainManager.hasPrivateKey() {
            print("✅ User already has E2EE key pair")
            // Get existing public key (would need to be retrieved from server)
            throw E2EEError.implementationIncomplete("Need to retrieve existing public key from server")
        }
        
        // Generate new key pair
        let (privateKey, publicKeyBase64) = try cryptoManager.generateP256KeyPair()
        
        // Save private key to keychain
        let privateKeyData = try cryptoManager.serializePrivateKey(privateKey)
        try keychainManager.savePrivateKey(privateKeyData)
        
        print("✅ E2EE key pair generated and saved")
        return publicKeyBase64
    }
    
    /**
     * Get user's private key from keychain
     */
    private func getPrivateKey() throws -> P256.KeyAgreement.PrivateKey {
        let privateKeyData = try keychainManager.getPrivateKey()
        return try cryptoManager.deserializePrivateKey(from: privateKeyData)
    }
    
    // MARK: - Message Encryption/Decryption
    
    /**
     * Encrypt message for specific recipient using E2EE
     * - Parameters:
     *   - message: Plain text message to encrypt
     *   - recipientPublicKey: Recipient's public key (Base64 encoded)
     * - Returns: Encrypted message as Base64 string
     */
    func encryptMessage(_ message: String, recipientPublicKey: String) throws -> String {
        print("🔒 Encrypting message with E2EE for recipient")
        
        // Get sender's private key
        let senderPrivateKey = try getPrivateKey()
        
        // Encrypt using hybrid encryption
        return try cryptoManager.encryptMessage(
            message,
            senderPrivateKey: senderPrivateKey,
            recipientPublicKeyBase64: recipientPublicKey
        )
    }
    
    /**
     * Decrypt message from specific sender using E2EE
     * - Parameters:
     *   - encryptedMessage: Encrypted message as Base64 string
     *   - senderPublicKey: Sender's public key (Base64 encoded)
     * - Returns: Decrypted plain text message
     */
    func decryptMessage(_ encryptedMessage: String, senderPublicKey: String) throws -> String {
        print("🔓 Decrypting message with E2EE from sender")
        
        // Get recipient's private key
        let recipientPrivateKey = try getPrivateKey()
        
        // Decrypt using hybrid encryption
        return try cryptoManager.decryptMessage(
            encryptedMessage,
            recipientPrivateKey: recipientPrivateKey,
            senderPublicKeyBase64: senderPublicKey
        )
    }
    
    /**
     * Encrypt message for group conversation (multi-recipient)
     * Note: In a proper implementation, this would use a group key or encrypt for each participant
     * For now, we'll throw an error to indicate this needs implementation
     */
    func encryptMessageForGroup(_ message: String, participantPublicKeys: [String]) throws -> String {
        throw E2EEError.implementationIncomplete("Group message encryption not yet implemented")
    }
    
    /**
     * Safely decrypt message with error handling
     * - Parameters:
     *   - encryptedMessage: Encrypted message as Base64 string
     *   - senderPublicKey: Sender's public key (Base64 encoded)
     * - Returns: Decrypted message or error message
     */
    func safeDecryptMessage(_ encryptedMessage: String, senderPublicKey: String) -> String {
        do {
            return try decryptMessage(encryptedMessage, senderPublicKey: senderPublicKey)
        } catch {
            print("❌ Failed to decrypt E2EE message: \(error)")
            return "Unable to decrypt message"
        }
    }
    
    /**
     * Create decrypted message preview for conversation list
     * - Parameters:
     *   - encryptedMessage: Encrypted message as Base64 string
     *   - senderPublicKey: Sender's public key (Base64 encoded)
     * - Returns: Preview text (truncated to 50 characters)
     */
    func createMessagePreview(_ encryptedMessage: String, senderPublicKey: String) -> String {
        do {
            let decryptedMessage = try decryptMessage(encryptedMessage, senderPublicKey: senderPublicKey)
            return decryptedMessage.count > 50 ? String(decryptedMessage.prefix(50)) + "..." : decryptedMessage
        } catch {
            print("❌ Failed to decrypt message preview: \(error)")
            return "Message"
        }
    }
    
    // MARK: - Utility Methods
    
    /**
     * Check if E2EE is properly initialized for this user
     */
    func isE2EEInitialized() -> Bool {
        return keychainManager.hasPrivateKey()
    }
    
    /**
     * Reset E2EE (delete private key) - USE WITH CAUTION
     * This will make all encrypted messages unreadable
     */
    func resetE2EE() throws {
        print("⚠️ Resetting E2EE - this will make encrypted messages unreadable!")
        try keychainManager.deletePrivateKey()
    }
}

// MARK: - E2EE Errors

enum E2EEError: LocalizedError {
    case keyPairNotFound
    case implementationIncomplete(String)
    case recipientPublicKeyMissing
    case encryptionFailed(String)
    case decryptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .keyPairNotFound:
            return "E2EE key pair not found. Please initialize E2EE first."
        case .implementationIncomplete(let message):
            return "E2EE implementation incomplete: \(message)"
        case .recipientPublicKeyMissing:
            return "Recipient's public key not available for E2EE"
        case .encryptionFailed(let message):
            return "E2EE encryption failed: \(message)"
        case .decryptionFailed(let message):
            return "E2EE decryption failed: \(message)"
        }
    }
}

// MARK: - Error Types

/// Encryption-specific errors
enum EncryptionError: Error, LocalizedError {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidKeyFormat
    case keyNotFound
    
    var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        case .encryptionFailed:
            return "Failed to encrypt message"
        case .decryptionFailed:
            return "Failed to decrypt message"
        case .invalidKeyFormat:
            return "Invalid encryption key format"
        case .keyNotFound:
            return "Encryption key not found"
        }
    }
}