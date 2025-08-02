//======================================================================
// MARK: - MessageEncryptionService.swift
// Purpose: Dedicated service for message encryption and decryption operations
// Path: still/Core/Services/MessageEncryptionService.swift
//======================================================================

import Foundation
import Security

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