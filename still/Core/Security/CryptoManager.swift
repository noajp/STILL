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
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        guard let text = String(data: decryptedData, encoding: .utf8) else {
            throw CryptoError.decryptionFailed
        }
        
        return text
    }
    
    // Base64エンコード（データベース保存用）
    func encryptToBase64(text: String, using key: SymmetricKey) throws -> String {
        let encryptedData = try encrypt(text: text, using: key)
        return encryptedData.base64EncodedString()
    }
    
    // Base64デコードして復号化
    func decryptFromBase64(base64String: String, using key: SymmetricKey) throws -> String {
        guard let data = Data(base64Encoded: base64String) else {
            throw CryptoError.invalidBase64
        }
        
        return try decrypt(data: data, using: key)
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