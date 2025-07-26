//======================================================================
// MARK: - SecureConfig.swift
// Purpose: Secure configuration management using Keychain and environment variables (Keychainと環境変数を使用したセキュアな設定管理)
// Path: still/Core/Config/SecureConfig.swift
//======================================================================

import Foundation
import Security

struct SecureConfig {
    static let shared = SecureConfig()
    
    private init() {}
    
    // MARK: - Keychain Keys
    private enum KeychainKey: String {
        case supabaseURL = "supabase_url"
        case supabaseAnonKey = "supabase_anon_key"
    }
    
    // MARK: - Configuration Properties
    var supabaseURL: String {
        // First try environment variable, then Keychain, then fallback
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
            return envURL
        }
        
        if let keychainURL = getFromKeychain(key: .supabaseURL) {
            return keychainURL
        }
        
        // Development fallback
        #if DEBUG
        return "https://yccjlkcxqybxqewzchen.supabase.co"
        #else
        fatalError("SUPABASE_URL not configured. Please set environment variable or Keychain value.")
        #endif
    }
    
    var supabaseAnonKey: String {
        // First try environment variable, then Keychain, then fallback
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        if let keychainKey = getFromKeychain(key: .supabaseAnonKey) {
            return keychainKey
        }
        
        // Development fallback - このキーは開発用のプレースホルダーです
        #if DEBUG
        print("⚠️ Using placeholder Supabase key. Please set SUPABASE_ANON_KEY environment variable.")
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljY2psa2N4cXlieHFld3pjaGVuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg4NzUzMjUsImV4cCI6MjA2NDQ1MTMyNX0.sKAfALsKR6wzYfhu3HybrWVl3Pi5qttL6ychxg7L05Q"
        #else
        fatalError("SUPABASE_ANON_KEY not configured. Please set environment variable or Keychain value.")
        #endif
    }
    
    // MARK: - Configuration Methods
    func setSupabaseConfig(url: String, anonKey: String) {
        saveToKeychain(key: .supabaseURL, value: url)
        saveToKeychain(key: .supabaseAnonKey, value: anonKey)
    }
    
    // MARK: - Keychain Operations
    private func saveToKeychain(key: KeychainKey, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.still.app",
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("❌ Failed to save \(key.rawValue) to Keychain: \(status)")
        }
    }
    
    private func getFromKeychain(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.still.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    // MARK: - Development Helper
    #if DEBUG
    func initializeForDevelopment() {
        // These values should be set from a secure source or environment
        // DO NOT commit actual values to Git
        let defaultURL = "https://yccjlkcxqybxqewzchen.supabase.co"
        // Note: SUPABASE_ANON_KEY should be set via environment variable or setSupabaseConfig()
        
        if getFromKeychain(key: .supabaseURL) == nil {
            saveToKeychain(key: .supabaseURL, value: defaultURL)
        }
        
        if getFromKeychain(key: .supabaseAnonKey) == nil {
            print("⚠️ Please set SUPABASE_ANON_KEY in environment or call setSupabaseConfig()")
        }
    }
    #endif
}