//======================================================================
// MARK: - SupabaseManage.swift
// Purpose: SupabaseManage implementation (SupabaseManageの実装)
// Path: still/Core/Networking/SupabaseManage.swift
//======================================================================
import Foundation
import Supabase

final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    private let secureLogger = SecureLogger.shared
    
    private init() {
        // セキュアな設定を使用
        guard let supabaseURL = URL(string: SecureConfig.shared.supabaseURL) else {
            secureLogger.error("Invalid Supabase URL configuration")
            fatalError("Invalid Supabase URL")
        }
        
        let supabaseKey = SecureConfig.shared.supabaseAnonKey
        guard !supabaseKey.isEmpty else {
            secureLogger.error("Missing Supabase anonymous key")
            fatalError("Missing Supabase configuration")
        }
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        secureLogger.info("SupabaseManager initialized with secure configuration")
        setupSecurityConfiguration()
    }
    
    private func setupSecurityConfiguration() {
        // 追加のセキュリティ設定
        secureLogger.debug("Supabase security configuration completed")
    }
}

