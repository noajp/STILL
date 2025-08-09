//======================================================================
// MARK: - KeychainManager.swift
// Purpose: Secure storage of encryption keys in iOS Keychain
// Path: still/Core/Security/KeychainManager.swift
//======================================================================

import Foundation
import Security

class KeychainManager: @unchecked Sendable {
    static let shared = KeychainManager()
    
    private let serviceName = "com.takanorinakano.still"
    private let userKeyAccount = "userEncryptionKey"
    private let accessGroup: String? = nil // 必要に応じてApp Group IDを設定
    
    private init() {}
    
    // 暗号化キーを保存
    func saveUserKey(_ keyData: Data) throws {
        // 既存のキーがあれば削除
        try? deleteUserKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userKeyAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    // 暗号化キーを取得
    func getUserKey() throws -> Data {
        print("🔑 KeychainManager - Attempting to retrieve user key")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        print("🔑 KeychainManager - Keychain query status: \(status)")
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            print("❌ KeychainManager - Key not found in keychain, status: \(status)")
            throw KeychainError.keyNotFound
        }
        
        print("🔑 KeychainManager - Successfully retrieved key, length: \(keyData.count)")
        return keyData
    }
    
    // 暗号化キーを削除
    func deleteUserKey() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: userKeyAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
    
    // キーが存在するかチェック
    func hasUserKey() -> Bool {
        do {
            _ = try getUserKey()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - P256 Private Key Storage for E2EE
    
    private let privateKeyAccount = "userP256PrivateKey"
    
    /**
     * Save P256 private key to keychain
     * - Parameter keyData: Serialized private key data
     */
    func savePrivateKey(_ keyData: Data) throws {
        print("🔐 Saving P256 private key to keychain")
        
        // Delete existing key if present
        try? deletePrivateKey()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.takanorinakano.still.p256.private".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            kSecAttrSynchronizable as String: false // Don't sync to iCloud Keychain
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            print("❌ Failed to save private key. Status: \(status)")
            throw KeychainError.unableToSave
        }
        
        print("✅ P256 private key saved successfully")
    }
    
    /**
     * Retrieve P256 private key from keychain
     * - Returns: Serialized private key data
     */
    func getPrivateKey() throws -> Data {
        print("🔑 Retrieving P256 private key from keychain")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.takanorinakano.still.p256.private".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            print("❌ Failed to retrieve private key. Status: \(status)")
            throw KeychainError.keyNotFound
        }
        
        print("✅ P256 private key retrieved successfully")
        return keyData
    }
    
    /**
     * Delete P256 private key from keychain
     */
    func deletePrivateKey() throws {
        print("🗑️ Deleting P256 private key from keychain")
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.takanorinakano.still.p256.private".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            print("❌ Failed to delete private key. Status: \(status)")
            throw KeychainError.unableToDelete
        }
        
        print("✅ P256 private key deleted")
    }
    
    /**
     * Check if P256 private key exists in keychain
     */
    func hasPrivateKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "com.takanorinakano.still.p256.private".data(using: .utf8)!,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

enum KeychainError: LocalizedError {
    case unableToSave
    case keyNotFound
    case unableToDelete
    
    var errorDescription: String? {
        switch self {
        case .unableToSave:
            return "Unable to save key to Keychain"
        case .keyNotFound:
            return "Key not found in Keychain"
        case .unableToDelete:
            return "Unable to delete key from Keychain"
        }
    }
}