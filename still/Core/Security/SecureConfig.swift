//======================================================================
// MARK: - SecureConfig.swift
// Purpose: SecureConfig implementation (SecureConfigの実装)
// Path: still/Core/Security/SecureConfig.swift
//======================================================================
import Foundation
import Security

/// セキュアな設定管理クラス
/// 機密情報をKeychainに保存し、安全にアクセスする
final class SecureConfig: @unchecked Sendable {
    
    // MARK: - Singleton
    static let shared = SecureConfig()
    private init() {
        // 強制的にSecrets.plistから再読み込み
        clearAllCredentials()
        loadFromSecretsPlist()
    }
    
    // MARK: - Keychain Keys
    private enum KeychainKey: String {
        case supabaseURL = "supabase_url"
        case supabaseAnonKey = "supabase_anon_key"
        case googlePlacesAPIKey = "google_places_api_key"
    }
    
    // MARK: - Public Properties
    var supabaseURL: String {
        getKeychainValue(for: .supabaseURL) ?? defaultSupabaseURL
    }
    
    var supabaseAnonKey: String {
        getKeychainValue(for: .supabaseAnonKey) ?? ""
    }
    
    var googlePlacesAPIKey: String {
        getKeychainValue(for: .googlePlacesAPIKey) ?? ""
    }
    
    // MARK: - Default Values (for development only)
    private var defaultSupabaseURL: String {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://yccjlkcxqybxqewzchen.supabase.co"
        #else
        return ""
        #endif
    }
    
    // MARK: - Setup Methods
    func setupCredentials() {
        // 開発環境では環境変数から取得、本番環境ではKeychainから取得
        #if DEBUG
        setupDevelopmentCredentials()
        #else
        // 本番環境では既にKeychainに保存されている値を使用
        validateProductionCredentials()
        #endif
    }
    
    private func loadFromSecretsIfNeeded() {
        // Keychainに値がない場合のみSecrets.plistから読み込む
        if getKeychainValue(for: .supabaseURL) == nil {
            loadFromSecretsPlist()
        }
    }
    
    private func loadFromSecretsPlist() {
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) else {
            #if DEBUG
            print("⚠️ Secrets.plist not found or invalid")
            #endif
            return
        }
        
        if let supabaseURL = plist["SupabaseURL"] as? String, !supabaseURL.isEmpty {
            setKeychainValue(supabaseURL, for: .supabaseURL)
        }
        
        if let supabaseKey = plist["SupabaseAnonKey"] as? String, !supabaseKey.isEmpty {
            setKeychainValue(supabaseKey, for: .supabaseAnonKey)
        }
        
        if let googleKey = plist["GooglePlacesAPIKey"] as? String, !googleKey.isEmpty {
            setKeychainValue(googleKey, for: .googlePlacesAPIKey)
        }
        
        #if DEBUG
        print("🔐 Loaded configuration from Secrets.plist")
        #endif
    }
    
    private func setupDevelopmentCredentials() {
        let env = ProcessInfo.processInfo.environment
        
        if let supabaseURL = env["SUPABASE_URL"] {
            setKeychainValue(supabaseURL, for: .supabaseURL)
        }
        
        if let supabaseKey = env["SUPABASE_ANON_KEY"] {
            setKeychainValue(supabaseKey, for: .supabaseAnonKey)
        }
        
        if let googleKey = env["GOOGLE_PLACES_API_KEY"] {
            setKeychainValue(googleKey, for: .googlePlacesAPIKey)
        }
    }
    
    private func validateProductionCredentials() {
        let requiredKeys: [KeychainKey] = [.supabaseURL, .supabaseAnonKey, .googlePlacesAPIKey]
        
        for key in requiredKeys {
            guard let value = getKeychainValue(for: key), !value.isEmpty else {
                fatalError("Missing required credential: \(key.rawValue)")
            }
        }
    }
    
    // MARK: - Keychain Operations
    private func setKeychainValue(_ value: String, for key: KeychainKey) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 既存の値を削除
        SecItemDelete(query as CFDictionary)
        
        // 新しい値を追加
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status != errSecSuccess {
            print("⚠️ Failed to store \(key.rawValue) in keychain: \(status)")
        }
        #endif
    }
    
    private func getKeychainValue(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Security Methods
    func clearAllCredentials() {
        let keys: [KeychainKey] = [.supabaseURL, .supabaseAnonKey, .googlePlacesAPIKey]
        
        for key in keys {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: key.rawValue
            ]
            SecItemDelete(query as CFDictionary)
        }
    }
    
    // MARK: - Validation
    func validateConfiguration() -> Bool {
        return !supabaseURL.isEmpty && 
               !supabaseAnonKey.isEmpty && 
               !googlePlacesAPIKey.isEmpty
    }
    
    // MARK: - Public Reload Method
    func reloadFromSecrets() {
        clearAllCredentials()
        loadFromSecretsPlist()
    }
}

// MARK: - Logging Security
extension SecureConfig {
    /// セキュアなログ出力（機密情報をマスク）
    func logSecureInfo() {
        #if DEBUG
        print("🔐 Supabase URL: \(maskURL(supabaseURL))")
        print("🔐 Supabase Key: \(maskKey(supabaseAnonKey))")
        print("🔐 Google API Key: \(maskKey(googlePlacesAPIKey))")
        #endif
    }
    
    private func maskURL(_ url: String) -> String {
        guard let urlComponents = URLComponents(string: url) else { return "***" }
        return "\(urlComponents.scheme ?? "https")://***.\(urlComponents.host?.suffix(10) ?? "***")"
    }
    
    private func maskKey(_ key: String) -> String {
        guard key.count > 8 else { return "***" }
        return String(key.prefix(4)) + "..." + String(key.suffix(4))
    }
}