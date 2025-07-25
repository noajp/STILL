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