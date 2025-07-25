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